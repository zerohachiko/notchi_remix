# Tasks

- [x] Task 1: 创建 ClaudeSettings 数据模型（`Models/ClaudeSettings.swift`）
  - [x] 1.1: 定义 `ClaudeSettings` 结构体，包含 `alwaysThinkingEnabled`、`rawUrl`、`env`、`enabledPlugins`、`hooks`、`permissions`、`statusLine`、`extraKnownMarketplaces` 全部字段
  - [x] 1.2: 定义 hooks 相关的嵌套类型：`HookEventConfig`（包含 `matcher` 和 `hooks` 数组）、`HookEntry`（包含 `command`、`type`、`timeout`）
  - [x] 1.3: 定义 `PermissionsConfig`（`allow` + `deny` 数组）、`StatusLineConfig`（`command` + `type`）、`MarketplaceConfig`（`source` 嵌套）
  - [x] 1.4: 实现 Codable 协议，使用 `CodingKeys` 映射 snake_case JSON 字段
  - [x] 1.5: 用 `[String: AnyCodable]` 或类似机制保留模型未覆盖的未知字段（向前兼容）

- [x] Task 2: 创建 ClaudeSettingsStore 服务（`Services/ClaudeSettingsStore.swift`）
  - [x] 2.1: 创建 `@MainActor @Observable` 单例类，包含 `settings: ClaudeSettings` 属性
  - [x] 2.2: 实现 `load()` 方法：读取 `~/.claude/settings.json` 并解析，失败时使用默认值
  - [x] 2.3: 实现 `save()` 方法：序列化为 `.prettyPrinted` + `.sortedKeys` 的 JSON 并写回文件，合并保留未知字段
  - [x] 2.4: 实现 `saveStatus` 枚举状态（idle / saved / error）和自动 1.5 秒回退逻辑
  - [x] 2.5: 各 section 的 CRUD 便捷方法：`addEnvVar`、`removeEnvVar`、`addPlugin`、`removePlugin`、`addHookEntry`、`removeHookEntry`、`addPermission`、`removePermission`、`addMarketplace`、`removeMarketplace` 等

- [x] Task 3: 创建 ClaudeSettingsView 主视图（`Views/ClaudeSettingsView.swift`）
  - [x] 3.1: 创建主视图骨架，包含 ScrollView + VStack + 各 section 分区 + Divider 分隔
  - [x] 3.2: 实现基础设置区：两个 Toggle 行（alwaysThinkingEnabled、rawUrl），复用 `SettingsRowView` + `ToggleSwitch` 组件
  - [x] 3.3: 实现保存状态提示条：底部显示 "Saved ✓"（绿色）或错误信息（红色），1.5 秒后自动消失
  - [x] 3.4: 调用 `ClaudeSettingsStore.shared.load()` 在 `.onAppear` 时加载数据

- [x] Task 4: 实现环境变量编辑区（`Views/ClaudeSettings/EnvSectionView.swift`）
  - [x] 4.1: 以列表展示所有 env key-value 对，key 不可编辑显示在左侧，value 以 TextField 可编辑
  - [x] 4.2: 敏感字段（变量名含 TOKEN/KEY/SECRET）默认显示 `••••`，点击眼睛图标切换显示
  - [x] 4.3: 底部 "+" 按钮新增环境变量，出现两个 TextField（key + value）输入行
  - [x] 4.4: 每行右侧有删除按钮（红色 "minus.circle" 图标），点击删除
  - [x] 4.5: 修改值后 `.onSubmit` 或失焦自动触发保存

- [x] Task 5: 实现插件管理区（`Views/ClaudeSettings/PluginsSectionView.swift`）
  - [x] 5.1: 列表展示所有插件，每行：插件名（Text）+ Toggle 开关
  - [x] 5.2: 底部 "+" 按钮新增插件条目（TextField 输入插件名，默认启用）
  - [x] 5.3: 每行支持删除
  - [x] 5.4: Toggle 变更后自动保存

- [x] Task 6: 实现 Hooks 管理区（`Views/ClaudeSettings/HooksSectionView.swift`）
  - [x] 6.1: 按事件类型分组展示，每个事件类型一个 DisclosureGroup（可折叠），标题显示事件名 + Hook 数量
  - [x] 6.2: 每个 Hook 条目显示：command（可编辑 TextField）、timeout（可选数字输入）、matcher（可选文本输入）
  - [x] 6.3: 包含 `notchi-hook.sh` 的条目标记 "Notchi" 绿色标签，删除按钮禁用
  - [x] 6.4: 每个事件组底部有 "+" 按钮可新增 Hook 条目
  - [x] 6.5: 修改后自动保存

- [x] Task 7: 实现权限管理区（`Views/ClaudeSettings/PermissionsSectionView.swift`）
  - [x] 7.1: 分为 Allow 和 Deny 两个子区域
  - [x] 7.2: 每个子区域是一个字符串列表，每行一个权限条目（TextField 可编辑）
  - [x] 7.3: 每个子区域底部有 "+" 按钮新增条目
  - [x] 7.4: 每行支持删除

- [x] Task 8: 实现状态栏 + 扩展市场区（`Views/ClaudeSettings/MiscSectionView.swift`）
  - [x] 8.1: 状态栏区：command 字段为可编辑 TextField，type 只读显示 "command"
  - [x] 8.2: 扩展市场区：列表展示市场名称 + repo 源，支持新增/删除
  - [x] 8.3: 修改后自动保存

- [x] Task 9: 集成到 Notchi 面板（修改现有文件）
  - [x] 9.1: 修改 `PanelSettingsView`：在 `actionsSection` 中新增 "Claude Code Settings" 按钮行（使用 `doc.text.magnifyingglass` 图标），点击触发回调
  - [x] 9.2: 修改 `NotchContentView`：新增 `@State private var showingClaudeSettings = false` 状态
  - [x] 9.3: 在 `NotchContentView` 的 `notchLayout` 中，当 `showingClaudeSettings == true` 时，替换 ExpandedPanelView 为 ClaudeSettingsView
  - [x] 9.4: 顶部 Back 按钮支持从 Claude Settings 返回
  - [x] 9.5: 面板关闭时重置 `showingClaudeSettings = false`

- [x] Task 10: 构建验证
  - [x] 10.1: 运行 `xcodebuild build` 确认编译通过，无 error 和 warning

# Task Dependencies

- Task 2 依赖 Task 1（Store 依赖 Model）
- Task 3 依赖 Task 2（主视图依赖 Store）
- Task 4、5、6、7、8 依赖 Task 2 和 Task 3（子视图依赖 Store 和主视图骨架）
- Task 4、5、6、7、8 之间无依赖，可并行开发
- Task 9 依赖 Task 3（集成依赖主视图完成）
- Task 10 依赖所有其他 Task
