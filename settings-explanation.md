# Claude Code settings.json 配置字段说明

> 文件路径：`~/.claude/settings.json`
>
> 这是 Claude Code（CLI 版本）的全局用户配置文件，定义了 Claude Code 在本地运行时的各种行为和参数。

---

## `alwaysThinkingEnabled`

| 类型 | 默认值 |
|------|--------|
| `boolean` | — |

是否始终开启"深度思考"模式。设为 `true` 时，Claude 在回答前会进行扩展推理（extended thinking），而非直接生成回复。适合需要更深度分析的场景。

---

## `enabledPlugins`

| 类型 | 格式 |
|------|------|
| `object` | `"插件名@来源": boolean` |

启用/禁用的插件列表。每个键是 `插件名@发布者` 的格式，值为 `true` 表示启用。

常见插件示例：
- `skill-creator@claude-plugins-official` — 用于创建和管理自定义 Skill
- `swift-lsp@claude-plugins-official` — Swift 语言服务器协议支持，提供智能补全/诊断等能力

---

## `env`

| 类型 | 格式 |
|------|------|
| `object` | `"变量名": "值"` |

Claude Code 运行时注入的环境变量。常见变量说明：

| 变量名 | 说明 |
|--------|------|
| `ANTHROPIC_AUTH_TOKEN` | API 认证 Token |
| `ANTHROPIC_BASE_URL` | API 基础请求地址（可用于配置代理或私有部署端点） |
| `API_TIMEOUT_MS` | API 请求超时时间（毫秒） |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | 设为 `"1"` 禁用非必要网络流量（如遥测/分析数据上报） |
| `CLAUDE_CODE_DISABLE_TERMINAL_TITLE` | 设为 `"1"` 禁止 Claude Code 修改终端窗口标题 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | 设为 `"1"` 启用实验性多智能体协作功能 |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 单次回复的最大输出 Token 数量 |

---

## `extraKnownMarketplaces`

| 类型 | 格式 |
|------|------|
| `object` | 嵌套对象 |

注册额外的 Skill 市场来源，用于发现和安装第三方 Skill。

```json
{
  "市场名称": {
    "source": {
      "repo": "GitHub 用户/仓库名",
      "source": "github"
    }
  }
}
```

---

## `hooks`

| 类型 | 格式 |
|------|------|
| `object` | `"事件名": [钩子配置数组]` |

生命周期钩子配置。Claude Code 在特定事件发生时自动执行指定的外部命令。

### 支持的事件类型

| 事件名 | 触发时机 |
|--------|----------|
| `Notification` | Claude Code 需要用户注意时 |
| `PermissionRequest` | 请求用户授权某项操作时 |
| `PreToolUse` | 工具调用前 |
| `PostToolUse` | 工具调用完成后 |
| `PostToolUseFailure` | 工具调用失败后 |
| `PreCompact` | 上下文压缩前（`matcher` 可区分 `auto` 自动压缩和 `manual` 手动压缩） |
| `SessionStart` | 会话开始时 |
| `SessionEnd` | 会话结束时 |
| `Stop` | Claude 停止响应时 |
| `SubagentStart` | 子智能体启动时 |
| `SubagentStop` | 子智能体停止时 |
| `UserPromptSubmit` | 用户提交提示词时 |

### 钩子配置结构

```json
{
  "hooks": [
    {
      "command": "要执行的命令",
      "type": "command",
      "timeout": 2           // 可选，超时时间（秒）
    }
  ],
  "matcher": ""              // 可选，匹配条件（"*" 匹配所有，"auto"/"manual" 等特定值）
}
```

---

## `permissions`

| 类型 | 格式 |
|------|------|
| `object` | `{ "allow": [], "deny": [] }` |

权限控制列表，用于预先批准或拒绝 Claude Code 的特定操作。

- `allow`：预先允许的操作列表（跳过确认）
- `deny`：预先拒绝的操作列表（直接阻止）

列表为空时，所有需要权限的操作都会实时询问用户确认。

---

## `rawUrl`

| 类型 | 默认值 |
|------|--------|
| `boolean` | — |

是否启用原始 URL 模式。设为 `true` 时，URL 不会被转义处理，保持原始格式。

---

## `statusLine`

| 类型 | 格式 |
|------|------|
| `object` | `{ "command": "命令", "type": "command" }` |

自定义状态栏配置。指定一个命令，其标准输出将显示在 Claude Code 界面底部的状态栏中。

```json
{
  "command": "/bin/zsh /path/to/statusline.sh",
  "type": "command"
}
```
