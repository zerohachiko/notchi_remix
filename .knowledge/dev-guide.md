# Notchi Remix 开发指南

## 环境要求

| 项目 | 最低版本 |
|------|----------|
| macOS | 15.0+ |
| Xcode | 26.0+ |
| Swift | 5.0 |
| create-dmg | 1.2+ (仅打包需要) |

## 快速开始

```bash
# 克隆项目
git clone git@github.com:zerohachiko/notchi_remix.git
cd notchi_remix

# 用 Xcode 打开
open notchi/notchi.xcodeproj

# 或命令行构建 (Debug)
cd notchi
xcodebuild build -scheme "notchi-remix" -destination "platform=macOS"
```

## 构建命令

### Debug 构建
```bash
cd notchi
xcodebuild build \
  -scheme "notchi-remix" \
  -destination "platform=macOS"
```

### Release 构建
```bash
cd notchi
xcodebuild build \
  -scheme "notchi-remix" \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath ./build
```

构建产物路径: `notchi/build/Build/Products/Release/notchi-remix.app`

### 运行测试
```bash
cd notchi
xcodebuild test \
  -scheme "notchi-remix" \
  -destination "platform=macOS"
```

## 打包 DMG

### 安装 create-dmg
```bash
brew install create-dmg
```

### 完整打包流程
```bash
# 1. Release 构建
cd notchi
xcodebuild build \
  -scheme "notchi-remix" \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath ./build

# 2. 打包 DMG
cd ..
rm -f "Notchi-Remix.dmg"
create-dmg \
  --volname "Notchi Remix" \
  --volicon "notchi/notchi/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 100 \
  --icon "notchi-remix.app" 180 190 \
  --hide-extension "notchi-remix.app" \
  --app-drop-link 480 190 \
  "Notchi-Remix.dmg" \
  "notchi/build/Build/Products/Release/notchi-remix.app"
```

### 一键打包脚本
```bash
# 在项目根目录执行
cd notchi && \
xcodebuild build -scheme "notchi-remix" -configuration Release -destination "platform=macOS" -derivedDataPath ./build -quiet && \
cd .. && \
rm -f "Notchi-Remix.dmg" && \
create-dmg \
  --volname "Notchi Remix" \
  --volicon "notchi/notchi/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 100 \
  --icon "notchi-remix.app" 180 190 \
  --hide-extension "notchi-remix.app" \
  --app-drop-link 480 190 \
  "Notchi-Remix.dmg" \
  "notchi/build/Build/Products/Release/notchi-remix.app" && \
echo "✅ DMG 打包完成: Notchi-Remix.dmg"
```

## Git 远程仓库

```bash
# origin: 自己的仓库
origin  git@github.com:zerohachiko/notchi_remix.git

# upstream: 上游原始仓库 (方便拉取更新)
upstream  git@github.com:sk-ruban/notchi.git

# 拉取上游更新
git fetch upstream
git merge upstream/main
```

## 项目配置

| 配置项 | 值 |
|--------|------|
| Bundle Identifier | `com.zerohachiko.notchi-remix` |
| Test Bundle ID | `com.zerohachiko.notchi-remix.Tests` |
| Scheme | `notchi-remix` |
| Display Name | Notchi Remix |
| Product Name | notchi-remix |
| App Entry | `notchiRemixApp` (notchiApp.swift) |
| Socket Path | `/tmp/notchi.sock` |
| Hook Script | `~/.claude/hooks/notchi-hook.sh` |
| Settings File | `~/.claude/settings.json` |

## 关键文件速查

| 文件 | 职责 |
|------|------|
| `notchiApp.swift` | @main 入口 |
| `AppDelegate.swift` | 应用初始化, 启动所有服务 |
| `NotchPanel.swift` | 自定义浮动窗口 |
| `NotchContentView.swift` | 主 UI 视图 |
| `NotchiStateMachine.swift` | **核心状态机** |
| `SocketServer.swift` | Unix Socket 服务器 (双向通信) |
| `PermissionResponseService.swift` | 权限决策管理 (Allow/Deny/Always Allow) |
| `ConversationParser.swift` | JSONL 增量解析 |
| `HookInstaller.swift` | Hook 安装/卸载 |
| `EmotionState.swift` | 情绪累积引擎 |
| `SessionData.swift` | 会话数据模型 |
| `AppSettings.swift` | 持久化设置 |
| `TerminalColors.swift` | UI 配色方案 |
| `notchi-hook.sh` | Claude Code Hook 脚本 |

## 开发注意事项

### 1. 命名约定
- 项目源码目录仍为 `notchi/notchi/`，未重命名
- Swift 类型名保持原始前缀 `Notchi` (如 `NotchiState`, `NotchiEmotion`)
- 仅显示名称和 Bundle ID 使用 `notchi-remix`

### 2. Hook 脚本兼容性
- Hook 脚本文件名为 `notchi-hook.sh`，与原版共用
- Socket 路径为 `/tmp/notchi.sock`，不能同时运行原版和 Remix
- 修改 Hook 脚本后需在应用设置中点击 "Reinstall Hook"

### 3. 签名注意
- 开发时使用自动签名 (Automatic)
- 发布 DMG 前建议配置 Developer ID 证书进行签名和公证
- Sparkle 更新需要 Ed25519 签名密钥

### 4. 添加新功能模式
1. **数据模型**: `Models/` 目录
2. **业务逻辑**: `Services/` 目录，使用 `@MainActor @Observable` 单例
3. **UI 视图**: `Views/` 目录，观察 Service 的 `@Observable` 属性
4. **集成入口**: 在 `NotchContentView` 或 `ExpandedPanelView` 中添加导航

### 5. 调试技巧
```bash
# 查看应用日志
log stream --predicate 'subsystem == "com.zerohachiko.notchi-remix"' --level debug

# 手动发送测试事件到 Socket
echo '{"session_id":"test","event":"UserPromptSubmit","status":"processing","cwd":"/tmp","interactive":true,"prompt":"hello"}' | nc -U /tmp/notchi.sock

# 检查 Hook 是否安装
cat ~/.claude/settings.json | python3 -m json.tool | grep notchi-hook
```
