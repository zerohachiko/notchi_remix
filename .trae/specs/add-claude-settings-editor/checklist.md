# Checklist

## 数据模型

- [x] `ClaudeSettings` 模型能正确解码真实的 `~/.claude/settings.json` 文件
- [x] `ClaudeSettings` 模型重新编码后写入的 JSON 与原文件语义一致（字段不丢失）
- [x] 模型中未覆盖的 JSON 字段在读写过程中被保留（向前兼容）

## 数据读写

- [x] `ClaudeSettingsStore.load()` 能正确读取并解析配置文件
- [x] `ClaudeSettingsStore.load()` 在文件不存在时不崩溃，使用默认值
- [x] `ClaudeSettingsStore.save()` 写入的 JSON 格式化为 prettyPrinted + sortedKeys
- [x] 保存成功后 `saveStatus` 转为 `.saved`，1.5 秒后回退为 `.idle`
- [x] 保存失败时 `saveStatus` 转为 `.error`，显示错误信息

## UI 界面

- [x] 基础设置区：`alwaysThinkingEnabled` 和 `rawUrl` Toggle 开关正常工作
- [x] 环境变量区：能展示所有 env 条目，值可编辑，敏感字段遮掩
- [x] 环境变量区：支持新增和删除环境变量
- [x] 插件管理区：能展示所有插件，Toggle 可切换启用/禁用
- [x] 插件管理区：支持新增和删除插件
- [x] Hooks 管理区：按事件类型分组折叠展示
- [x] Hooks 管理区：Notchi 自身的 Hook 条目标记 "Notchi" 标签且不可删除
- [x] Hooks 管理区：支持新增和删除非 Notchi 的 Hook 条目
- [x] 权限管理区：Allow 和 Deny 列表可展示、新增、删除
- [x] 状态栏区：command 字段可编辑
- [x] 扩展市场区：列表可展示、新增、删除

## 集成与导航

- [x] `PanelSettingsView` 中有 "Claude Code Settings" 入口按钮
- [x] 点击入口按钮后正确导航到 Claude Settings 编辑页面
- [x] 顶部 Back 按钮可返回原设置页面
- [x] 面板关闭时自动重置 Claude Settings 页面状态

## UI 风格一致性

- [x] 使用项目现有的 `TerminalColors` 配色方案（深色主题）
- [x] 复用 `SettingsRowView`、`ToggleSwitch` 等现有组件
- [x] 字体、间距、圆角与 `PanelSettingsView` 一致

## 构建

- [x] `xcodebuild build` 编译通过，无 error
