# Claude Code Settings 可视化编辑器 Spec

## Why

当前修改 `~/.claude/settings.json` 只能通过手动编辑 JSON 文件，容易出错且不直观。需要在 Notchi 的展开面板中提供一个可视化的设置编辑界面，让用户可以安全、直观地查看和修改 Claude Code 的配置。

## What Changes

- 新增 `ClaudeSettingsStore` 服务：负责读写 `~/.claude/settings.json`，提供类型安全的数据模型
- 新增 `ClaudeSettingsView` 视图：集成到 Notchi 展开面板的设置页面中，提供分组表单式的配置编辑界面
- 修改 `PanelSettingsView`：在现有设置界面新增 "Claude Code Settings" 入口按钮
- 修改 `NotchContentView`：增加 Claude 设置页面的导航状态

## Impact

- 受影响视图：`PanelSettingsView`、`NotchContentView`、`ExpandedPanelView`
- 新增文件：`Models/ClaudeSettings.swift`、`Services/ClaudeSettingsStore.swift`、`Views/ClaudeSettingsView.swift` 及其子视图
- 不影响现有 Hook、Socket、StateMachine 等核心功能

## ADDED Requirements

### Requirement: Claude Settings 数据模型

系统需要提供一个类型安全的 Swift 数据模型来映射 `~/.claude/settings.json` 的全部字段。

#### 场景: 读取配置文件

- **WHEN** 用户打开 Claude Settings 编辑页面
- **THEN** 系统读取 `~/.claude/settings.json` 并解析为 `ClaudeSettings` 模型
- **THEN** 如果文件不存在或解析失败，使用默认空值

#### 场景: 保存配置文件

- **WHEN** 用户修改任意配置项
- **THEN** 系统将完整的 `ClaudeSettings` 模型序列化回 JSON 并写入文件
- **THEN** 写入使用 `.prettyPrinted` + `.sortedKeys` 格式化，保持可读性
- **THEN** 保留文件中模型未覆盖的未知字段（向前兼容）

### Requirement: Claude Settings 可视化编辑界面

系统需要在 Notchi 展开面板中提供分组表单式的配置编辑界面。

#### 场景: 界面分区

编辑界面按以下分区组织：

**1. 基础设置区**
- `alwaysThinkingEnabled`：Toggle 开关
- `rawUrl`：Toggle 开关

**2. 环境变量区（env）**
- 以 key-value 列表形式展示所有环境变量
- 每行显示变量名（不可编辑）和变量值（可编辑 TextField）
- 敏感字段（含 TOKEN/KEY 的变量名）值默认以 `••••` 遮掩，点击可显示
- 支持新增环境变量（底部 "+" 按钮，弹出 key-value 输入行）
- 支持删除环境变量（滑动或长按出现删除按钮）

**3. 插件管理区（enabledPlugins）**
- 以列表展示所有插件，每个插件一行：插件名 + Toggle 开关
- 支持新增插件条目（底部 "+" 按钮输入插件名）
- 支持删除插件条目

**4. Hooks 管理区（hooks）**
- 以事件类型分组展示（折叠式 DisclosureGroup）
- 每个事件下显示挂载的 Hook 列表
- 每个 Hook 显示：command（可编辑）、type（只读 "command"）、timeout（可选数字输入）、matcher（可选文本输入）
- 支持新增/删除 Hook 条目
- Notchi 自身的 Hook（包含 `notchi-hook.sh` 的条目）标记为 "Notchi" 标签且不可删除

**5. 权限管理区（permissions）**
- `allow` 列表：可增删权限条目的列表
- `deny` 列表：可增删权限条目的列表

**6. 状态栏区（statusLine）**
- command 字段：文本输入框
- type 字段：只读显示 "command"

**7. 扩展市场区（extraKnownMarketplaces）**
- 以列表展示市场名称 + GitHub 仓库源
- 支持新增/删除

#### 场景: 导航入口

- **WHEN** 用户在 Notchi 设置页面点击 "Claude Code Settings" 按钮
- **THEN** 界面切换到 Claude Settings 编辑页面
- **THEN** 顶部显示 "Back" 返回按钮

#### 场景: 保存反馈

- **WHEN** 用户修改某个字段并失去焦点或按下回车
- **THEN** 系统自动保存到文件
- **THEN** 界面显示短暂的 "Saved" 提示（1.5 秒后消失）

#### 场景: 错误处理

- **WHEN** 保存失败（如权限不足）
- **THEN** 界面显示红色错误提示

## MODIFIED Requirements

### Requirement: PanelSettingsView 新增入口

在现有 `PanelSettingsView` 的 `actionsSection` 中新增 "Claude Code Settings" 按钮行，使用 `doc.text.magnifyingglass` SF Symbol 图标。

### Requirement: NotchContentView 导航状态

在 `NotchContentView` 中新增 `showingClaudeSettings` 状态，与现有 `showingPanelSettings` 并列，控制 Claude Settings 页面的显示/隐藏。面板关闭时自动重置该状态。
