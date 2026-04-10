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

### 3. Claude Code 事件监听
- **实现**: `SocketServer` + `notchi-hook.sh` + `HookInstaller`
- Hook 脚本自动安装到 `~/.claude/hooks/notchi-hook.sh`
- 自动注册到 `~/.claude/settings.json` 的所有事件类型
- 通过 Unix Domain Socket (`/tmp/notchi.sock`) 接收 JSON 事件
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

### 4. 多会话管理
- **实现**: `SessionStore` + `SessionData`
- 并行跟踪多个 Claude Code 会话
- 每个会话独立状态: 任务状态、情绪状态、工具使用记录
- 自动区分交互式 / 非交互式 (`-p`) 会话
- 会话持续时间实时计算
- 按工作目录项目名显示

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
- **实现**: `SoundService` + `AppSettings`
- 模型生成完成时播放提示音
- 内置多种提示音可选 (Purr, Pop, Hero 等)
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
- 修改即保存，未知字段向前兼容
- 保存状态提示 (成功/失败)

### 12. 应用设置
- **实现**: `PanelSettingsView` + `AppSettings`
- 通知音选择
- 静音开关
- Claude 用量跟踪开关
- Anthropic API Key 配置
- 多屏幕选择
- 重新安装 Hook
- 检查更新
- Claude 配置编辑入口
- 退出应用

## 状态枚举

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
