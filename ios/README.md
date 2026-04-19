# 星序 iOS 项目配置指南

本目录包含将「星序」Web 应用封装为原生 iOS App 并添加桌面小组件所需的全部源代码文件。

## 📋 环境要求

- macOS 13.5 或更高版本
- Xcode 15.0 或更高版本
- iOS 16.0+ / iPadOS 16.0+ （小组件功能需要）
- Apple Developer 账号（免费账号可安装到真机，上架需要 688元/年的开发者计划）

## 🚀 快速开始

### 第一步：创建 Xcode 项目

1. 打开 **Xcode** → **File** → **New** → **Project** (⌘⇧N)
2. 选择模板 **iOS → App**，点击 **Next**
3. 填写项目信息：
   - **Name**: `XingXu`
   - **Team**: 选择你的 Apple ID（或 None）
   - **Organization Identifier**: `com.xingxu`
   - **Interface**: **Storyboard**（不要选 SwiftUI）
   - **Language**: **Swift**
   - 取消勾选 **Include Tests**（可选）
4. 选择保存位置，点击 **Create**

### 第二步：删除 Xcode 自动生成的文件

在项目导航栏中，删除以下自动生成的文件（选择 **Move to Trash**）：
- `ViewController.swift`
- `Main.storyboard`
- `SceneDelegate.swift`（如果 Xcode 生成了的话）

### 第三步：添加源代码文件

#### 3.1 添加主 App 文件

在项目导航栏中，右键点击 `XingXu` 文件夹 → **Add Files to "XingXu"**，选择以下文件（都在本目录的 `XingXu/` 中）：

- `AppDelegate.swift`
- `SceneDelegate.swift`
- `WebViewController.swift`
- `LaunchScreen.storyboard`

**注意**：勾选 **"Copy items if needed"** 和 **"Create groups"**，确保下方 **Target** 选中了 `XingXu`。

#### 3.2 添加共享数据文件（关键！）

在项目导航栏中，右键点击 `XingXu` 文件夹 → **Add Files to "XingXu"**，选择：

- `../Shared/SharedData.swift`

勾选 **"Copy items if needed"** 和 **"Create groups"**。

#### 3.3 添加 Entitlements 文件

将本目录根下的 `XingXu.entitlements` 拖入 Xcode 的 `XingXu` 文件夹中，勾选 **"Copy items if needed"**。

#### 3.4 添加图标资源

将 `XingXu/Assets.xcassets/AppIcon.appiconset/Contents.json` 拖入 Xcode 的 `Assets.xcassets/AppIcon.appiconset` 中，替换原有文件。

**你需要准备 App 图标**：为所有尺寸（20pt~1024pt，共 18 张）准备 PNG 图标，命名规则参考 `Contents.json`。也可以先用通用图标占位，后续替换。

> 💡 快捷方案：使用 [appicon.co](https://appicon.co) 上传一张 1024×1024 的图片，自动生成全套图标，直接拖入即可。

#### 3.5 添加 Web 资源（核心！）

**这一步最重要**：需要将网页文件打包进 App。

1. 在项目导航栏中，右键点击 `XingXu` 文件夹 → **Add Files to "XingXu"**
2. 导航到项目根目录（即包含 `index.html` 的目录）
3. 选择以下文件（**不要勾选 "Copy items if needed"**，保持引用原文件即可，这样后续修改 Web 代码不需要重新导入）：
   - `index.html`
   - `app.js`
   - `styles.css`
   - `manifest.json`
   - `sw.js`
4. 确保 **Target** 中勾选了 `XingXu`

### 第四步：配置 Info.plist

1. 在 Xcode 中打开 `Info.plist`
2. 找到 **"Application Scene Manifest"** → **"Scene Configuration"** → **"Application Session Role"** → **"Item 0 (Default Configuration)"**
3. 确保有以下键值：
   - **Scene Delegate Class Name**: `$(PRODUCT_MODULE_NAME).SceneDelegate`
4. 如果没有 **"Launch screen interface file base name"**，手动添加：
   - 键名：`UILaunchStoryboardName`
   - 值：`LaunchScreen`

### 第五步：启用 App Group（关键！）

App Group 是主 App 和小组件共享数据的唯一方式，**必须配置**。

#### 5.1 为主 App 启用 App Group

1. 点击 Xcode 左侧项目导航栏最顶部的 **`XingXu`**（蓝色图标）
2. 选择 **TARGETS** 中的 `XingXu`
3. 切换到 **Signing & Capabilities** 标签
4. 点击 **+ Capability**，搜索并添加 **App Groups**
5. 点击 App Groups 下的 **+** 按钮，输入：`group.com.xingxu.schedule`
6. 如果你的开发者账号已登录，Xcode 会自动注册这个 Group；否则会显示错误，需要先在 Apple Developer 网站手动创建或在 Xcode 中登录账号后重试

#### 5.2 配置 Entitlements 文件

确保 `XingXu.entitlements` 文件内容如下（已包含在源码中）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.xingxu.schedule</string>
    </array>
</dict>
</plist>
```

### 第六步：添加小组件扩展（Widget Extension）

#### 6.1 创建 Widget Target

1. **File** → **New** → **Target**
2. 选择 **iOS → Widget Extension**，点击 **Next**
3. 配置：
   - **Product Name**: `XingXuWidget`
   - **Team**: 选择你的 Apple ID
   - **Language**: Swift
   - **Starting Point**: None
   - **Include Configuration Intent**: 取消勾选
4. 点击 **Finish**
5. 出现 "Activate scheme" 弹窗时，点击 **Activate**

#### 6.2 删除自动生成的 Widget 文件

在 `XingXuWidget` 文件夹中，删除 Xcode 自动生成的文件：
- `XingXuWidget.swift`（自动生成版本）
- `XingXuWidgetBundle.swift`（自动生成版本）
- `XingXuWidgetLiveActivity.swift`（如果有的话）
- `IntentHandler.swift`（如果有的话）
- `XingXuWidget.intentdefinition`（如果有的话）

#### 6.3 添加自定义 Widget 文件

右键点击 `XingXuWidget` 文件夹 → **Add Files to "XingXuWidget"**，选择以下文件（都在本目录的 `XingXuWidget/` 中）：

- `XingXuWidgetBundle.swift`
- `XingXuWidget.swift`
- `Provider.swift`
- `Entry.swift`

#### 6.4 添加共享数据文件到 Widget Target

右键点击 `XingXuWidget` 文件夹 → **Add Files to "XingXuWidget"**，选择：

- `../Shared/SharedData.swift`

**⚠️ 关键操作**：在弹出的对话框中，确保 **Target** 栏**只勾选** `XingXuWidget`（不要勾选主 App 的 Target）。

> 同一个 `SharedData.swift` 文件需要被添加到两个 Target 中。如果你之前添加到了主 App，现在再次添加到 Widget Target，Xcode 会自动处理。

#### 6.5 为 Widget 启用 App Group

1. 点击项目顶部 **`XingXu`**
2. 选择 **TARGETS** 中的 `XingXuWidget`
3. 切换到 **Signing & Capabilities**
4. 点击 **+ Capability**，添加 **App Groups**
5. 勾选 **同样的 Group**: `group.com.xingxu.schedule`

#### 6.6 添加 Widget Entitlements

将 `XingXuWidget/XingXuWidget.entitlements` 拖入 Xcode 的 `XingXuWidget` 文件夹中。

#### 6.7 配置 Widget Info.plist

在 `XingXuWidget` 文件夹中，将本目录提供的 `XingXuWidget/Info.plist` 替换 Xcode 自动生成的版本。

或者手动修改：
1. 打开 `XingXuWidget/Info.plist`
2. 找到 `NSExtension` → `NSExtensionPointIdentifier`
3. 确保值为 `com.apple.widgetkit-extension`

### 第七步：修改 Web 应用代码（增强桥接）

为了让小组件能**实时**响应任务变化，建议在 `app.js` 中添加主动同步逻辑。

打开项目根目录的 `app.js`，在 `Storage.saveTasks` 函数末尾添加：

```javascript
// 同步到 iOS 小组件
if (window.xingxuNative && window.xingxuNative.ready) {
    window.xingxuNative.postMessage({ action: 'syncTasks' });
}
```

在 `toggleComplete` 和 `deleteTask` 函数末尾也添加同样的代码。

这样每次任务变化时，原生端会立即刷新小组件。

> 如果暂时不想修改 `app.js`，也没关系，代码中已经实现了每 30 秒自动同步 + 进入前后台时同步。

### 第八步：构建与运行

1. 连接你的 iPhone/iPad（或使用 iOS Simulator）
2. 在 Xcode 顶部工具栏，选择目标设备
3. 点击 **▶ Run**（或 ⌘R）
4. 首次运行需要在 iPhone 上 **设置 → 通用 → VPN与设备管理** 中信任你的开发者证书

### 第九步：添加桌面小组件

1. 在 iPhone/iPad 主屏幕上**长按空白区域**
2. 点击左上角的 **+** 按钮
3. 搜索 **"星序"** 或 **"星序日程"**
4. 选择小组件尺寸：**小 / 中 / 大**
5. 点击 **添加小组件**

小组件会自动显示今日任务和完成进度！

## 📁 文件结构说明

```
ios/
├── README.md                          # 本文件
├── XingXu.entitlements               # 主 App 的 App Group 配置
├── Shared/
│   └── SharedData.swift              # 共享数据模型（主 App + Widget 共用）
├── XingXu/
│   ├── AppDelegate.swift             # 应用生命周期 + 通知权限
│   ├── SceneDelegate.swift           # 场景管理 + 前后台同步
│   ├── WebViewController.swift       # WKWebView 加载 PWA + 数据同步
│   ├── LaunchScreen.storyboard       # 启动画面
│   ├── Info.plist                    # 主 App 配置
│   └── Assets.xcassets/              # App 图标资源
└── XingXuWidget/
    ├── XingXuWidgetBundle.swift      # Widget 入口
    ├── XingXuWidget.swift            # 小/中/大三种尺寸小组件视图
    ├── Provider.swift                # 小组件时间线数据提供者
    ├── Entry.swift                   # 小组件数据条目
    ├── Info.plist                    # Widget 配置
    └── XingXuWidget.entitlements     # Widget 的 App Group 配置
```

## 🔧 常见问题

### 1. "App Group 不可用" 错误

- 确保你的 Apple ID 已添加到 Xcode（**Xcode → Settings → Accounts**）
- 免费开发者账号可能无法创建 App Group，需要在 Apple Developer 网站手动创建
- 或者暂时修改 `SharedData.swift` 中的 `suiteName` 为不使用 App Group 的方式（但小组件将无法显示数据）

### 2. Web 页面显示空白

- 检查 `index.html` 是否已添加到 Target（在文件检查器中确认 **Target Membership** 勾选了 `XingXu`）
- 检查 `app.js` 和 `styles.css` 是否也在同一个 Bundle 中
- 在 Xcode 控制台查看是否有加载错误

### 3. 小组件显示 "今日暂无任务"

- 在主 App 中添加一些任务
- 确保任务日期是今天
- 等待 30 秒或切换应用到后台再打开，触发同步
- 小组件本身有 15 分钟的刷新间隔，可以长按小组件 → **编辑小组件** → 目前暂不支持自定义，但可以移除后重新添加来立即刷新

### 4. 图标不显示

- 需要准备 PNG 格式的图标文件
- 使用 [appicon.co](https://appicon.co) 生成最方便

## 📝 后续优化建议

1. **推送通知**：可以配置远程推送，提醒即将开始的任务
2. **Siri 快捷指令**：通过 Intents Extension 支持 "今天有什么任务" 等语音查询
3. **灵动岛 / Live Activity**：iOS 16.1+ 支持在锁屏和灵动岛显示当前进行中的任务
4. **Apple Watch  complications**：添加 watchOS 扩展

## 🎨 小组件预览

| 尺寸 | 显示内容 |
|------|---------|
| **小** | 环形进度图 + 完成数/总数 |
| **中** | 进度圆环 + 前 4 个任务列表 |
| **大** | 完整任务列表（最多 8 条）+ 进度条 + 标签 |

---

如有问题，可以检查 Xcode 的 **控制台日志**（底部面板）查看详细错误信息。
