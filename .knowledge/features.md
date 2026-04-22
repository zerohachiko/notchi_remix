# Notchi Remix 功能明细

## 核心功能

### 1. 刘海区域浮动面板
- **实现**: `NotchPanel` (自定义 NSPanel) + `NotchContentView` (SwiftUI)
- 自动检测 MacBook 刘海位置 (`NSScreen+Notch.swift`)
- 窗口层级 `mainMenu + 3`，跨所有 Space 显示
- 非交互区域事件穿透 (`NotchHitTestView`)
- 支持多屏幕切换 (`ScreenSelector`)

### 2. 动画角色系统
- **实现**: `SpriteSheetView` + `SessionSpriteView` + `GrassIslandView`
- 精灵图 (Sprite Sheet) 逐帧动画，使用 `TimelineView` 驱动
- 根据任务状态切换动画集: idle / working / waiting / compacting / sleeping
- 根据情绪切换动画变体: neutral / happy / sad / sob
- 每个会话一个角色，随机位置分布在草地岛上
- 浮动摆动 (Bob) 动画

### 3. AI 编程助手事件监听 (Claude Code + Codex CLI)
- **实现**: `SocketServer` + `notchi-hook.sh` + `notchi-codex-hook.sh` + `HookInstaller`
- **AgentSource 枚举**: `HookEvent.sourceApp` 字段区分事件来源 (`claude` / `codex`)
- 统一通过 Unix Domain Socket (`/tmp/notchi.sock`) 接收 JSON 事件

#### Claude Code Hooks
- Hook 脚本自动安装到 `~/.claude/hooks/notchi-hook.sh`
- 自动注册到 `~/.claude/settings.json` 的所有事件类型
- 支持双向 Socket 通信 (PermissionRequest 响应)
- 支持的事件类型:
  | 事件 | 说明 |
  |------|------|
  | `UserPromptSubmit` | 用户提交提示词 |
  | `SessionStart` | 会话开始 |
  | `PreToolUse` | 工具调用前 |
  | `PostToolUse` | 工具调用后 |
  | `PermissionRequest` | 权限请求 |
  | `PreCompact` | 压缩前 |
  | `Stop` | 模型停止生成 |
  | `SubagentStop` | 子代理停止 |
  | `SessionEnd` | 会话结束 |

#### Codex CLI Hooks
- Hook 脚本自动安装到 `~/.codex/notchi-codex-hook.sh`
- 自动写入 `~/.codex/hooks.json` 配置
- 自动启用 `~/.codex/config.toml` 中的 `[features] codex_hooks = true` feature flag
- 仅单向事件推送 (无权限响应交互)
- 如果 `~/.codex` 目录不存在则静默跳过安装
- 支持的事件类型:
  | 事件 | matcher | 说明 |
  |------|---------|------|
  | `SessionStart` | `startup\|resume` | 会话启动/恢复 |
  | `UserPromptSubmit` | 无 | 用户提交提示词 |
  | `PreToolUse` | `Bash` | Bash 工具调用前 |
  | `PostToolUse` | `Bash` | Bash 工具调用后 |
  | `Stop` | 无 | 模型停止生成 |

#### Claude vs Codex 功能差异
| 功能 | Claude | Codex |
|------|--------|-------|
| 状态监控 (working/idle/sleeping) | ✅ | ✅ |
| 情绪分析 | ✅ | ✅ |
| 通知音 | ✅ | ✅ |
| JSONL 对话文件解析 | ✅ | ❌ (无对应文件) |
| 文件监听 (DispatchSource) | ✅ | ❌ |
| 权限交互 (Allow/Deny/Always Allow) | ✅ | ❌ |
| API 用量跟踪 | ✅ | ❌ |
| Agent 来源标签 (UI badge) | 琥珀色 "Claude" | 绿色 "Codex" |

### 4. 多会话管理
- **实现**: `SessionStore` + `SessionData` + `ActiveSessionScanner`
- 并行跟踪多个 Claude Code 和 Codex 会话
- 每个会话独立状态: 任务状态、情绪状态、工具使用记录、agent 来源 (`agentSource`)
- 自动区分交互式 / 非交互式 (`-p`) 会话
- 会话持续时间实时计算
- 按工作目录项目名显示
- 会话行 (`SessionRowView`) 和展开面板标题显示 agent 来源 badge (Claude=琥珀色 / Codex=绿色)
- **启动时已有会话发现**: 扫描 `~/.claude/sessions/*.json` 注册文件，验证 PID 存活性 (`kill(pid, 0)`)，为活跃会话注入合成 `SessionStart` 事件

### 5. 展开面板 UI
- **实现**: `ExpandedPanelView`
- 点击刘海区域展开 450x450 面板
- 会话活动流: 用户提示词、工具使用、AI 回复
- 用户提示词气泡 (`UserPromptBubbleView`)
- 工具参数折叠显示 (`ToolArgumentsView`)
- Markdown 渲染 (`MarkdownRenderer`)
- 实时滚动到最新内容

### 6. 情绪系统
- **实现**: `EmotionState` + `EmotionAnalyzer`
- 工具使用映射为情绪信号 (如: Write → happy, Error → sad)
- 累积评分制，阈值触发情绪切换
- 自动衰减回归中性状态 (60s 周期)
- 情绪影响角色动画表现

### 7. 对话文件解析
- **实现**: `ConversationParser` (Actor)
- 增量解析 Claude JSONL 对话文件
- 文件路径: `~/.claude/projects/{cwd_hash}/sessions/{session_id}.jsonl`
- 提取 assistant 文本消息
- 检测用户中断信号
- 使用 DispatchSource 文件监听实时更新

### 8. Claude 用量跟踪
- **实现**: `ClaudeUsageService` + `UsageBarView`
- 通过 Anthropic API 查询 Claude 使用配额
- 用量进度条可视化显示
- 支持 Anthropic API Key 和 OAuth Token 两种认证
- Keychain 安全存储密钥

### 9. 通知音
- **实现**: `SoundService` + `AppSettings` + `NotificationSound`
- 模型生成完成时播放提示音
- 两类音效来源:
  - **系统音效**: macOS 内置提示音 (Purr, Pop, Hero, Glass 等 14 种)
  - **自定义 8-bit 音效**: 马里奥风格电子音效，从 app bundle 的 `Resources/Sounds/` 加载 .wav 文件
- 马里奥音效 (Python 脚本 `scripts/generate_mario_sounds.py` 合成):
  | 枚举值 | 文件名 | 效果 |
  |--------|--------|------|
  | `marioCoin` | `mario_coin.wav` | 经典金币收集音 (方波 B5→E6) |
  | `marioComplete` | `mario_complete.wav` | 任务完成上行旋律 (方波 C5-E5-G5-C6) |
  | `marioOneUp` | `mario_oneup.wav` | 1-UP 音效 (三角波 E4-G4-E5-C5-D5-G5) |
  | `marioPowerUp` | `mario_powerup.wav` | 能量升级渐升音阶 (方波 16 阶) |
- `NotificationSound.isSystemSound` 属性区分系统/自定义音效
- `SoundService` 自定义音效使用 `NSSound(contentsOf:byReference:)` 加载并缓存
- `SoundPickerView` 中马里奥音效显示 🎮 游戏手柄图标 (绿色)，与系统音效的 🔊 喇叭图标区分
- 静音模式切换

### 10. 自动更新
- **实现**: Sparkle 框架 + `UpdateManager` + `NotchiUpdateUserDriver`
- 自动检查更新 (24h 间隔)
- 支持 Ed25519 签名验证
- 后台下载安装

### 11. Claude 配置可视化编辑
- **实现**: `ClaudeSettingsView` + `ClaudeSettingsStore`
- 可视化编辑 `~/.claude/settings.json`
- 分区管理:
  - 基础设置 (Extended Thinking, Raw URL)
  - 环境变量 (敏感字段自动遮掩)
  - 插件管理
  - Hooks 管理 (按事件分组, Notchi Hook 保护)
  - 权限管理 (Allow / Deny)
  - 状态栏命令
  - 扩展市场
- **确认保存模式**: 修改仅暂存在内存，底部显示 Discard / Confirm 按钮，点击 Confirm 才写入磁盘
- 未知字段向前兼容
- 保存状态提示 (成功/失败)

### 11b. Codex 配置可视化编辑
- **实现**: `CodexSettingsView` + `CodexSettingsStore` + `CodexSettings` 模型
- 可视化编辑 `~/.codex/config.toml` (TOML 格式) 和 `~/.codex/hooks.json`
- 分区管理:
  - 基础设置 (Model, Approval Policy, Sandbox Mode, Reasoning Effort/Summary, Hide Reasoning, Disable Storage)
  - Features & Tools (动态读取 `[features]` / `[tools]` 下的布尔开关)
  - Hooks 管理 (按事件分组, Notchi Hook 保护)
- **确认保存模式**: 与 Claude 配置一致，修改暂存内存，Confirm 后写磁盘，Discard 回滚
- 简易 TOML 解析器 (支持 section、key=value、行内注释、引号)
- `~/.codex` 不存在时禁用入口按钮
- **关键文件**:
  | 文件 | 说明 |
  |------|------|
  | `Models/CodexSettings.swift` | Codex 配置模型 (CodexSettings, CodexHookEntry, CodexHookEventConfig) |
  | `Services/CodexSettingsStore.swift` | 读写 config.toml + hooks.json, TOML 解析/序列化, commitSave/discardChanges |
  | `Views/CodexSettingsView.swift` | 主视图 (ScrollView + 底部确认栏) |
  | `Views/CodexSettings/CodexBasicSectionView.swift` | 基础设置 (model 输入框 + picker 行) |
  | `Views/CodexSettings/CodexToolsSectionView.swift` | Features & Tools 开关 |
  | `Views/CodexSettings/CodexHooksSectionView.swift` | Hooks 管理 (DisclosureGroup + 增删改) |

### 11c. Per-Hook 音效配置
- **实现**: `HookSoundPickerView` + `AppSettings.hookSounds` + `SoundService.playHookSound`
- 每个 hook 条目可单独配置通知音效，默认为空 (Muted)
- 音效配置存储在 UserDefaults (key 格式: `{source}:{eventType}:{command}`)，不写入 CLI 配置文件
- 内联下拉菜单组件 `HookSoundPickerView`: 喇叭图标 + 音效名 + 上下箭头，支持全部 19 种音效
- 选中后立即试听 (调用 `SoundService.previewSound`)
- **运行时播放**: `NotchiStateMachine.handleEvent` 在收到每个事件时，通过 `resolveHookCommands` 查找对应事件类型的 hook 命令列表，调用 `SoundService.playHookSound` 按 key 查找并播放配置的音效
- 同时适用于 Claude Code 和 Codex 的 hooks
- **关键修改文件**:
  | 文件 | 改动 |
  |------|------|
  | `Core/AppSettings.swift` | 新增 hookSounds 存储 (hookSoundKey/hookSound/setHookSound) |
  | `Views/Components/HookSoundPickerView.swift` | 新增内联音效选择器组件 |
  | `Views/ClaudeSettings/HooksSectionView.swift` | HookEntryRow 中嵌入 HookSoundPickerView |
  | `Views/CodexSettings/CodexHooksSectionView.swift` | CodexHookEntryRow 中嵌入 HookSoundPickerView |
  | `Services/SoundService.swift` | 新增 playHookSound 方法 |
  | `Services/NotchiStateMachine.swift` | handleEvent 中调用 playHookSound + resolveHookCommands |

### 12. 权限请求交互 (Allow / Deny / Always Allow)
- **实现**: `PermissionResponseService` + `SocketServer` (双向通信) + `notchi-hook.sh`
- Claude Code 发起 `PermissionRequest` 事件时，灵动岛直接显示操作按钮
- 三种操作:
  | 操作 | 快捷键 | 行为 |
  |------|--------|------|
  | **Deny** | ⌘N | 拒绝本次权限请求 |
  | **Allow** | ⌘Y | 允许本次权限请求 |
  | **Always Allow** | ⌘⇧Y | 允许并通过 `updatedPermissions` 将规则持久化到 `localSettings` |
- 选择后选择框立即隐藏 (调用 `clearPendingQuestions()`)
- **双向 Socket 通信机制**:
  1. Hook 脚本发送事件后执行 `shutdown(SHUT_WR)` (半关闭写端)
  2. 应用侧保留客户端 socket fd，等待用户决策
  3. 用户点击按钮后，应用将 JSON 响应写回同一 socket
  4. Hook 脚本读取响应并输出到 stdout，Claude Code 读取执行
- `PendingQuestion` 结构携带 `toolName`，用于 Always Allow 构建精确的工具级权限规则
- Always Allow 响应格式 (Claude Code `hookSpecificOutput`):
  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PermissionRequest",
      "decision": {
        "behavior": "allow",
        "updatedPermissions": [{
          "type": "addRules",
          "rules": [{"toolName": "Bash"}],
          "behavior": "allow",
          "destination": "localSettings"
        }]
      }
    }
  }
  ```

### 13. 应用设置
- **实现**: `PanelSettingsView` + `AppSettings`
- 通知音选择
- 静音开关
- Claude 用量跟踪开关
- Anthropic API Key 配置
- 多屏幕选择
- 重新安装 Claude Hook (状态: Installed/Not Installed/Error)
- 重新安装 Codex Hook (状态: Installed/Not Installed/Not Found/Error，`~/.codex` 不存在时禁用)
- 检查更新
- Claude 配置编辑入口
- Codex 配置编辑入口 (`~/.codex` 不存在时禁用)
- 退出应用

### 14. 灵动岛收起态活动信息展示
- **实现**: `CollapsedActivityView` + `CollapsedPermissionView` + `CollapsedSummaryView` (新增 `UI/CollapsedActivityView.swift`)
- 灵动岛收起状态下，在刘海区域第二行 (notch 下方) 自动延伸显示当前最新操作信息
- **布局**: VStack 两行结构 — 第一行为 notch 占位 + 精灵图 (固定高度 `notchSize.height`), 第二行为活动信息 (因摄像头遮挡, 文字只能放在第二行)
- **展示优先级**: 权限请求 > AI 任务总结 (idle 时) > 工具活动 (working 时)
- **工具活动展示** (`CollapsedActivityView`):
  - 状态指示符: ● (运行中/amber) / ✓ (成功/green) / ✗ (失败/red)
  - 工具名 (Write / Bash / Read / Edit 等)
  - 简短描述 (文件名或命令前 30 字符)
- **权限请求展示** (`CollapsedPermissionView`):
  - ⚠ 图标 + 权限请求问题文本
  - 优先级最高 (有权限请求时优先显示)
- **AI 总结展示** (`CollapsedSummaryView`):
  - ✓ 图标 (绿色) + 最后一条 AI 回复的首行文本 (最多 40 字符)
  - 任务完成 (idle) 且有 `recentAssistantMessages` 时显示
- **灵动岛形状适配**:
  - 有活动信息时不使用系统刘海曲线裁切, 改用 `NotchShape` 以支持向下延伸
  - 最大宽度限制为 `notchSize.width`, 防止内容溢出
  - `.easeInOut(duration: 0.25)` 动画控制展示/隐藏过渡
- **关键修改文件**:
  | 文件 | 改动 |
  |------|------|
  | `NotchContentView.swift` | `headerRow` 改为 VStack 两行, 增加 `hasCollapsedActivity`/`collapsedActivityLabel`, 修改 `notchClipShape` 适配 |
  | `UI/CollapsedActivityView.swift` | 新增文件, 包含 `CollapsedActivityView`、`CollapsedPermissionView`、`CollapsedSummaryView` |

### 15. 权限请求自动展开灵动岛
- **实现**: `NotchiStateMachine` + `NotchPanelManager` + `ExpandedPanelView`
- 收到 `PermissionRequest` 事件时, 自动调用 `NotchPanelManager.shared.expand()` 展开面板
- 展开后 ScrollView 自动聚焦到 `QuestionPromptView` (权限操作按钮区域)
- `ExpandedPanelView.onAppear` 优先检查 `pendingQuestions`, 有则滚动到 `"question-prompt"`
- **关键修改文件**:
  | 文件 | 改动 |
  |------|------|
  | `Services/NotchiStateMachine.swift` | `PermissionRequest` case 中增加 `NotchPanelManager.shared.expand()` |
  | `Views/ExpandedPanelView.swift` | `onAppear` 滚动逻辑优先处理 pendingQuestions |

### 16. 展开面板活动内容详情 (可折叠 Diff 预览)
- **实现**: `ActivityRowView` + `ActivityContentPreview` (在 `UI/ActivityRowView.swift` 中)
- 展开面板中的工具活动行支持点击展开/折叠内容详情
- 有可展开内容的行显示 ▶/▼ 箭头指示
- **内容展示**:
  | 工具 | 展示内容 |
  |------|----------|
  | Write | 写入的文件内容 (等宽字体, 最多 6 行, 300 字符截断) |
  | Edit | diff 风格: `- old` (红色旧代码) + `+ new` (绿色新代码) |
  | Bash | 执行的命令内容 |
- 展开/收起动画: `easeInOut(duration: 0.15)`
- **关键修改文件**:
  | 文件 | 改动 |
  |------|------|
  | `UI/ActivityRowView.swift` | `ActivityRowView` 增加 `isContentExpanded` 状态和点击交互; 新增 `ActivityContentPreview` 私有视图 |

### 17. 任务完成后 AI 回复总结
- **实现**: `notchi-hook.sh` + `HookEvent` + `SessionStore` + `CollapsedSummaryView`
- Claude Code 任务完成 (`Stop`/`SubagentStop` 事件) 后，提取 AI 的最后一条回复消息
- 灵动岛收起态展示任务总结 (首行文本, 绿色 ✓ 图标)
- **数据流**:
  1. `notchi-hook.sh` 从 `Stop`/`SubagentStop` 事件的 `input_data` 中提取 `last_assistant_message` 字段
  2. Hook 脚本将该字段传递到 Socket payload
  3. `HookEvent` 模型新增 `lastAssistantMessage: String?` 属性
  4. `SessionStore` 在处理 Stop 事件时, 将消息封装为 `AssistantMessage` 并调用 `session.recordAssistantMessages()`
  5. `NotchContentView.collapsedActivityLabel` 在 idle 状态检测 `recentAssistantMessages`, 使用 `CollapsedSummaryView` 展示
- **关键修改文件**:
  | 文件 | 改动 |
  |------|------|
  | `Resources/notchi-hook.sh` | Stop/SubagentStop 事件提取并传递 `last_assistant_message` |
  | `Models/HookEvent.swift` | 新增 `lastAssistantMessage` 属性和 CodingKeys |
  | `Services/SessionStore.swift` | Stop 事件处理中记录 `AssistantMessage` |
  | `UI/CollapsedActivityView.swift` | 新增 `CollapsedSummaryView` 视图 |

### NotchiTask (任务状态)
| 值 | 说明 |
|------|------|
| `idle` | 空闲 |
| `waitingForInput` | 等待用户输入 |
| `processing` | 处理中 |
| `runningTool` | 执行工具 |
| `compacting` | 压缩上下文 |
| `sleeping` | 睡眠 (300s 无活动) |

### NotchiEmotion (情绪状态)
| 值 | 阈值 | 说明 |
|------|------|------|
| `neutral` | 默认 | 中性 |
| `happy` | ≥ 0.6 | 开心 |
| `sad` | ≥ 0.45 | 难过 |
| `sob` | ≥ 0.9 | 大哭 |
