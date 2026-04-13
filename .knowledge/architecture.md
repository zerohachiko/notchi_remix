# Notchi Remix 项目架构

## 项目概述

Notchi Remix 是一个 macOS 原生应用，将 MacBook 的刘海 (Notch) 区域变成一个 AI 编程助手的实时状态面板。通过 Claude Code 和 OpenAI Codex CLI 的 Hook 机制接收事件，在刘海区域显示动画角色、会话状态、工具使用情况等信息。支持同时监控多个 Claude Code 和 Codex 会话。

## 技术栈

| 项目 | 值 |
|------|------|
| 语言 | Swift 5.0 |
| UI 框架 | SwiftUI + AppKit (NSPanel) |
| 最低部署版本 | macOS 15.0 |
| 依赖 | Sparkle (自动更新) |
| IPC | Unix Domain Socket (`/tmp/notchi.sock`) |
| 包管理 | Swift Package Manager |
| Bundle ID | `com.zerohachiko.notchi-remix` |

## 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                      Claude Code (终端)                          │
│                                                                  │
│  运行时触发 Hook → ~/.claude/hooks/notchi-hook.sh                │
│                         │ ▲                                      │
│                         ▼ │ (PermissionRequest 响应 JSON)        │
│              Unix Socket 双向通信                                 │
│              /tmp/notchi.sock                                     │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────┤──────────────────────────────────────┐
│                      Codex CLI (终端)                             │
│                                                                  │
│  运行时触发 Hook → ~/.codex/notchi-codex-hook.sh                 │
│                         │                                        │
│                         ▼ (单向事件推送)                          │
│              Unix Socket 单向通信                                 │
│              /tmp/notchi.sock                                     │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    Notchi Remix App                               │
│                                                                  │
│  ┌──────────────┐    ┌───────────────────┐    ┌──────────────┐  │
│  │ SocketServer │───▶│ NotchiStateMachine│───▶│ SessionStore │  │
│  │(双向Socket通信)│    │   (状态机核心)     │    │  (会话管理)   │  │
│  └──────┬───────┘    └────────┬──────────┘    └──────┬───────┘  │
│         ▲                     │                      │           │
│         │              ┌──────▼──────────┐    ┌──────▼───────┐  │
│  PermissionResponse    │ Conversation-   │    │ SessionData  │  │
│    Service             │   Parser        │    │ (会话数据)    │  │
│  (权限决策→Socket回写)  │ (JSONL增量解析)  │    └──────┬───────┘  │
│                        └────────────────┘    ┌──────▼───────┐  │
│                    ┌─────────────────────┐    │ EmotionState │  │
│                    │  EmotionAnalyzer    │    │ (情绪累积)    │  │
│                    │  (工具→情绪映射)     │    └──────────────┘  │
│                    └─────────────────────┘                       │
│                                                                  │
│  ┌────────────────────────── UI 层 ─────────────────────────┐   │
│  │                                                           │   │
│  │  NotchPanel (NSPanel)                                     │   │
│  │    └── NotchContentView (SwiftUI)                         │   │
│  │          ├── GrassIslandView + SpriteSheetView (收起态)    │   │
│  │          ├── CollapsedActivityView / PermissionView /      │   │
│  │          │   SummaryView (收起态第二行活动信息)             │   │
│  │          ├── ExpandedPanelView (展开态)                    │   │
│  │          │     ├── 会话活动列表                             │   │
│  │          │     ├── QuestionPromptView (权限操作按钮)        │   │
│  │          │     ├── PanelSettingsView (设置)                │   │
│  │          │     └── ClaudeSettingsView (Claude 配置编辑)    │   │
│  │          └── NotchShape (刘海形状动画)                     │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────── 辅助服务 ─────────────┐                           │
│  │ HookInstaller  (Hook 安装/卸载, 支持 Claude + Codex) │                           │
│  │ SoundService   (通知音, 系统+自定义) │                           │
│  │ UpdateManager  (Sparkle 更新)     │                           │
│  │ ClaudeUsageService (用量查询)     │                           │
│  │ EventMonitor   (全局事件监听)     │                           │
│  │ ClaudeSettingsStore (配置读写)    │                           │
│  │ PermissionResponseService         │                           │
│  │   (权限决策管理, Allow/Deny/      │                           │
│  │    Always Allow → Socket回写)     │                           │
│  └───────────────────────────────────┘                           │
└──────────────────────────────────────────────────────────────────┘
```

## 数据流

```
Claude Code 事件 (运行时)     Codex CLI 事件 (运行时)     启动时已有会话发现
      │                            │                        │
      ▼                            ▼                        ▼
notchi-hook.sh             notchi-codex-hook.sh      ActiveSessionScanner
(Bash + Python)            (Bash + Python)           │  扫描 ~/.claude/sessions/*.json
│  解析 stdin JSON,         │  解析 stdin JSON,       │  验证 PID 存活, 构造合成 SessionStart
│  构建精简 payload          │  source_app="codex"     │
│  source_app="claude"      │                         │
▼                           ▼                         │
Unix Socket → SocketServer ◀─────────────────────────┘
      │  解码为 HookEvent (含 sourceApp 字段)
      ▼
NotchiStateMachine.handleEvent(_:)
      │
      ├──▶ SessionStore: 创建/查找/更新会话 (含 agentSource: claude/codex)
      ├──▶ SessionData: 更新任务状态、记录工具使用
      ├──▶ [仅 Claude] ConversationParser: 增量解析 JSONL 对话文件
      ├──▶ EmotionAnalyzer: 工具名映射为情绪
      ├──▶ EmotionState: 累积分数、衰减、阈值判定
      ├──▶ SoundService: 触发通知音
      ├──▶ [仅 Claude] SessionStore (Stop): 从 HookEvent.lastAssistantMessage 提取 AI 回复
      ├──▶ [仅 Claude] ClaudeUsageService: 用量追踪
      └──▶ [仅 Claude] PermissionResponseService: 标记 pending (仅 PermissionRequest)
              │
              ├──▶ NotchPanelManager.expand(): 自动展开灵动岛面板 (仅 PermissionRequest)
              ▼
      SwiftUI @Observable 自动刷新 UI
              │
              ▼ (用户点击 Allow / Deny / Always Allow)
      PermissionResponseService.allow/deny/alwaysAllow()
              │  构建 hookSpecificOutput JSON
              ▼
      SocketServer.respondToPermission()
              │  写回保持打开的客户端 socket fd
              ▼
      notchi-hook.sh 读取响应 → stdout → Claude Code 执行
```

## 目录结构

```
notchi/
├── notchi.xcodeproj/          # Xcode 项目文件
├── Info.plist                 # Sparkle 更新配置
├── Tests/                     # 单元测试
│   ├── ClaudeUsageServiceTests.swift
│   ├── EmotionAnalyzerTests.swift
│   ├── NotchiStateMachineTests.swift
│   ├── SocketServerTests.swift
│   └── ...
└── notchi/                    # 主 target 源码
    ├── notchiApp.swift        # @main App 入口
    ├── AppDelegate.swift      # NSApplicationDelegate, 初始化一切
    ├── NotchPanel.swift       # 自定义 NSPanel (浮动窗口)
    ├── NotchContentView.swift # 主 SwiftUI 视图
    ├── NotchShape.swift       # 刘海形状 Shape + 动画
    ├── ContentView.swift      # 面板内容宿主
    ├── NSScreen+Notch.swift   # 屏幕刘海检测扩展
    ├── notchi.entitlements     # 沙盒权限
    │
    ├── Core/                  # 核心工具
    │   ├── AppSettings.swift           # UserDefaults + Keychain 设置
    │   ├── NotchHitTestView.swift      # 事件穿透 NSView
    │   ├── ScreenSelector.swift        # 多屏幕选择
    │   └── SoundSelector.swift         # 声音选择
    │
    ├── Models/                # 数据模型
    │   ├── ClaudeSettings.swift        # ~/.claude/settings.json 模型
    │   ├── EmotionState.swift          # 情绪累积引擎
    │   ├── HookEvent.swift             # Hook 事件定义 (含 AgentSource 枚举: claude/codex)
    │   ├── NotchiState.swift           # 任务+情绪组合状态
    │   ├── NotificationSound.swift     # 通知音枚举 (系统+马里奥8-bit)
    │   ├── SessionData.swift           # 会话数据 (含 agentSource)
    │   ├── SessionStats.swift          # 会话统计
    │   └── UsageQuota.swift            # 用量配额
    │
    ├── Services/              # 业务服务
    │   ├── SocketServer.swift          # Unix Socket 服务器 (双向通信)
    │   ├── NotchiStateMachine.swift    # 核心状态机
    │   ├── ConversationParser.swift    # JSONL 增量解析器
    │   ├── HookInstaller.swift         # Hook 安装器 (Claude + Codex)
    │   ├── EmotionAnalyzer.swift       # 工具→情绪映射
    │   ├── SessionStore.swift          # 会话存储
    │   ├── ActiveSessionScanner.swift  # 启动时扫描 ~/.claude/sessions/ 发现已有会话
    │   ├── PermissionResponseService.swift # 权限决策管理 (Allow/Deny/Always Allow)
    │   ├── ClaudeSettingsStore.swift   # Claude 配置读写
    │   ├── ClaudeUsageService.swift    # API 用量查询
    │   ├── EventMonitor.swift          # 全局事件监听
    │   ├── KeychainManager.swift       # Keychain 封装
    │   ├── NotchPanelManager.swift     # 面板管理器
    │   ├── SoundService.swift          # 声音播放 (系统音效+自定义bundle音效)
    │   ├── TerminalFocusDetector.swift # 终端焦点检测
    │   └── Update/
    │       ├── NotchiUpdateUserDriver.swift
    │       └── UpdateManager.swift
    │
    ├── Views/                 # SwiftUI 视图
    │   ├── ClaudeSettingsView.swift    # Claude 配置编辑主视图
    │   ├── ClaudeSettings/             # Claude 配置编辑子视图
    │   │   ├── EnvSectionView.swift
    │   │   ├── PluginsSectionView.swift
    │   │   ├── HooksSectionView.swift
    │   │   ├── PermissionsSectionView.swift
    │   │   └── MiscSectionView.swift
    │   ├── ExpandedPanelView.swift     # 展开面板
    │   ├── GrassIslandView.swift       # 草地岛背景
    │   ├── PanelSettingsView.swift     # 应用设置
    │   ├── SessionListView.swift       # 会话列表
    │   ├── SessionRowView.swift        # 会话行
    │   ├── SessionSpriteView.swift     # 会话精灵
    │   ├── UsageBarView.swift          # 用量条
    │   └── Components/
    │       ├── BobAnimation.swift
    │       ├── ScreenPickerRow.swift
    │       ├── SoundPickerView.swift
    │       └── SpriteSheetView.swift
    │
    ├── UI/                    # UI 工具组件
    │   ├── TerminalColors.swift        # 深色主题配色
    │   ├── ActivityRowView.swift       # 活动行 (含可折叠 Diff 预览)
    │   ├── AssistantTextRowView.swift  # AI 回复行
    │   ├── CollapsedActivityView.swift # 灵动岛收起态: 活动/权限/AI总结展示
    │   ├── MarkdownRenderer.swift      # Markdown 渲染
    │   ├── ProcessingSpinner.swift     # 加载动画
    │   ├── ToolArgumentsView.swift     # 工具参数显示
    │   └── UserPromptBubbleView.swift  # 用户提示气泡
    │
    ├── Resources/
    │   ├── notchi-hook.sh              # Claude Code Hook 脚本 (含 last_assistant_message 提取)
    │   ├── notchi-codex-hook.sh        # Codex CLI Hook 脚本 (source_app=codex)
    │   └── Sounds/                     # 自定义音效文件 (8-bit .wav)
    │       ├── mario_coin.wav
    │       ├── mario_complete.wav
    │       ├── mario_oneup.wav
    │       └── mario_powerup.wav
    │
    └── Assets.xcassets/       # 图标和精灵图
        ├── AppIcon.appiconset/
        └── (各情绪+状态的 sprite sheet)
```

## 关键设计模式

### 1. 单例 + @Observable
核心服务均使用 `@MainActor @Observable` 单例模式，SwiftUI 视图自动响应状态变化：
- `NotchiStateMachine.shared`
- `SessionStore.shared`
- `NotchPanelManager.shared`
- `ClaudeSettingsStore.shared`

### 2. Actor 并发隔离
`ConversationParser` 使用 Swift Actor 保证文件解析的线程安全。

### 3. 事件穿透 (HitTest)
`NotchHitTestView` 覆盖 `hitTest(_:)` 方法，在非交互区域返回 `nil`，让鼠标事件穿透到底层窗口。

### 4. 情绪累积引擎
- 双维度评分 (happy/sad)，每个维度 0.0~1.0
- 阈值触发情绪切换 (neutral→happy→sad→sob)
- 时间衰减 (60s 周期, 0.92 衰减系数)
- 中和衰减机制 (neutral 输入削弱其他分数)

### 5. 增量文件解析
`ConversationParser` 记录文件偏移量 (`lastProcessedOffset`)，每次只读取新增行，避免全量重新解析。

### 6. 双向 Socket 通信 (权限响应)
- **单向事件** (多数事件): Hook → App，写完即关闭
- **双向交互** (PermissionRequest): Hook 发送事件后 `shutdown(SHUT_WR)` 半关闭写端，App 保留 `clientFd` 到 `pendingPermissionSockets` 字典
- 用户做出决策后，`PermissionResponseService` 构建 JSON → `SocketServer.respondToPermission()` 写回 → `close(clientFd)`
- Hook 脚本读取响应后 `print(json.dumps(parsed))` 输出到 stdout，Claude Code 据此执行
- 超时机制: Hook 脚本等待 120s，超时后静默退出
