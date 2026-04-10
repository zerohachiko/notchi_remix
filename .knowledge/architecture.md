# Notchi Remix 项目架构

## 项目概述

Notchi Remix 是一个 macOS 原生应用，将 MacBook 的刘海 (Notch) 区域变成一个 Claude Code 的实时状态面板。通过 Claude Code 的 Hook 机制接收事件，在刘海区域显示动画角色、会话状态、工具使用情况等信息。

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
│                         │                                        │
│                         ▼                                        │
│              Unix Socket 发送 JSON 事件                           │
│              /tmp/notchi.sock                                     │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    Notchi Remix App                               │
│                                                                  │
│  ┌──────────────┐    ┌───────────────────┐    ┌──────────────┐  │
│  │ SocketServer │───▶│ NotchiStateMachine│───▶│ SessionStore │  │
│  │  (接收事件)   │    │   (状态机核心)     │    │  (会话管理)   │  │
│  └──────────────┘    └────────┬──────────┘    └──────┬───────┘  │
│                               │                      │           │
│                    ┌──────────▼──────────┐    ┌──────▼───────┐  │
│                    │ ConversationParser  │    │ SessionData  │  │
│                    │  (JSONL 增量解析)    │    │ (会话数据)    │  │
│                    └─────────────────────┘    └──────┬───────┘  │
│                                                      │           │
│                    ┌─────────────────────┐    ┌──────▼───────┐  │
│                    │  EmotionAnalyzer    │    │ EmotionState │  │
│                    │  (工具→情绪映射)     │    │ (情绪累积)    │  │
│                    └─────────────────────┘    └──────────────┘  │
│                                                                  │
│  ┌────────────────────────── UI 层 ─────────────────────────┐   │
│  │                                                           │   │
│  │  NotchPanel (NSPanel)                                     │   │
│  │    └── NotchContentView (SwiftUI)                         │   │
│  │          ├── GrassIslandView + SpriteSheetView (收起态)    │   │
│  │          ├── ExpandedPanelView (展开态)                    │   │
│  │          │     ├── 会话活动列表                             │   │
│  │          │     ├── PanelSettingsView (设置)                │   │
│  │          │     └── ClaudeSettingsView (Claude 配置编辑)    │   │
│  │          └── NotchShape (刘海形状动画)                     │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────── 辅助服务 ─────────────┐                           │
│  │ HookInstaller  (Hook 安装/卸载)   │                           │
│  │ SoundService   (通知音)           │                           │
│  │ UpdateManager  (Sparkle 更新)     │                           │
│  │ ClaudeUsageService (用量查询)     │                           │
│  │ EventMonitor   (全局事件监听)     │                           │
│  │ ClaudeSettingsStore (配置读写)    │                           │
│  └───────────────────────────────────┘                           │
└──────────────────────────────────────────────────────────────────┘
```

## 数据流

```
Claude Code 事件
      │
      ▼
notchi-hook.sh (Bash + Python)
      │  解析 stdin JSON, 构建精简 payload
      ▼
Unix Socket → SocketServer.start(onEvent:)
      │  解码为 HookEvent
      ▼
NotchiStateMachine.handleEvent(_:)
      │
      ├──▶ SessionStore: 创建/查找/更新会话
      ├──▶ SessionData: 更新任务状态、记录工具使用
      ├──▶ ConversationParser: 增量解析 JSONL 对话文件
      ├──▶ EmotionAnalyzer: 工具名映射为情绪
      ├──▶ EmotionState: 累积分数、衰减、阈值判定
      └──▶ SoundService: 触发通知音
              │
              ▼
      SwiftUI @Observable 自动刷新 UI
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
    │   ├── HookEvent.swift             # Hook 事件定义
    │   ├── NotchiState.swift           # 任务+情绪组合状态
    │   ├── SessionData.swift           # 会话数据
    │   ├── SessionStats.swift          # 会话统计
    │   └── UsageQuota.swift            # 用量配额
    │
    ├── Services/              # 业务服务
    │   ├── SocketServer.swift          # Unix Socket 服务器
    │   ├── NotchiStateMachine.swift    # 核心状态机
    │   ├── ConversationParser.swift    # JSONL 增量解析器
    │   ├── HookInstaller.swift         # Hook 安装器
    │   ├── EmotionAnalyzer.swift       # 工具→情绪映射
    │   ├── SessionStore.swift          # 会话存储
    │   ├── ClaudeSettingsStore.swift   # Claude 配置读写
    │   ├── ClaudeUsageService.swift    # API 用量查询
    │   ├── EventMonitor.swift          # 全局事件监听
    │   ├── KeychainManager.swift       # Keychain 封装
    │   ├── NotchPanelManager.swift     # 面板管理器
    │   ├── SoundService.swift          # 声音播放
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
    │   ├── ActivityRowView.swift       # 活动行
    │   ├── AssistantTextRowView.swift  # AI 回复行
    │   ├── MarkdownRenderer.swift      # Markdown 渲染
    │   ├── ProcessingSpinner.swift     # 加载动画
    │   ├── ToolArgumentsView.swift     # 工具参数显示
    │   └── UserPromptBubbleView.swift  # 用户提示气泡
    │
    ├── Resources/
    │   └── notchi-hook.sh              # Claude Code Hook 脚本
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
