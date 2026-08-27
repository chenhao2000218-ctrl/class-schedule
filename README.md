# 课程表 App

纯净、无广告的大学课程表应用，基于 Flutter 跨平台开发，兼容 iOS。

## 功能特性

### 核心功能
- **周课表视图**：主界面以周视图展示所有课程，支持切换周次
- **单日详情**：点击日期查看当天课程详情，支持左右切换日期
- **自定义作息**：自由设置每节课的开始/结束时间，支持拖拽排序、增删节次

### 课程录入
- 手动添加课程：课程名称、授课老师、教室、星期、节次
- 上课周范围：滑块选择起止周
- 单周/双周/每周 开关
- 自定义课程颜色
- 备注字段

### 数据导入导出
- **ICS 导入**：粘贴教务系统 ICS 链接一键导入
- **ICS 文件导入**：选择本地 .ics 文件导入
- **JSON 备份**：一键导出全部数据为 JSON 文件
- **JSON 恢复**：从备份文件恢复全部数据

### 调休与假期
- 标记假期：该日期自动隐藏所有课程
- 标记调休：设置调休日按星期几上课

### 上课提醒
- 每门课独立设置提前提醒时间（0/5/10/15/30 分钟）
- 本地通知，无需联网

### 桌面小组件（iOS）
- 小号：显示下一节课
- 中号：显示今日课程列表（最多3节）
- 大号：显示完整今日课程
- 遵循 WidgetKit 系统规范

### 配套功能
- 深色/浅色/跟随系统 三种模式
- 12 种主题色可选
- 考试安排录入模块
- 课程绑定作业待办清单（截止时间、完成状态）
- 课表导出分享图片

### 隐私保护
- 所有数据本地存储（SharedPreferences）
- 不上传任何课表数据到云端
- 无广告、无追踪

## 技术栈

- **框架**：Flutter 3.x (Dart 3.x)
- **状态管理**：Provider
- **本地存储**：shared_preferences
- **本地通知**：flutter_local_notifications + timezone
- **ICS 解析**：icalendar_parser
- **文件选择**：file_picker
- **截图分享**：screenshot + share_plus + image_gallery_saver
- **iOS 小组件**：WidgetKit (SwiftUI)

## 项目结构

```
class_schedule_app/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── models/                      # 数据模型
│   │   ├── course.dart              # 课程模型
│   │   ├── time_slot.dart           # 作息时间段
│   │   ├── exam.dart                # 考试模型
│   │   ├── homework.dart            # 作业模型
│   │   ├── holiday.dart             # 假期调休模型
│   │   └── app_settings.dart        # 应用设置
│   ├── services/                    # 服务层
│   │   ├── storage_service.dart     # 本地存储
│   │   ├── ics_service.dart         # ICS 解析导入
│   │   ├── notification_service.dart# 本地通知
│   │   ├── backup_service.dart      # JSON 备份恢复
│   │   └── widget_service.dart      # 小组件数据
│   ├── providers/
│   │   └── app_state.dart           # 全局状态管理
│   ├── screens/                     # 页面
│   │   ├── home_screen.dart         # 主界面（周课表+底部导航）
│   │   ├── day_detail_screen.dart   # 单日详情
│   │   ├── course_edit_screen.dart  # 课程添加/编辑
│   │   ├── schedule_settings_screen.dart # 作息时间设置
│   │   ├── import_screen.dart       # ICS/JSON 导入
│   │   ├── exam_screen.dart         # 考试安排
│   │   ├── homework_screen.dart     # 作业待办
│   │   ├── holiday_screen.dart      # 假期调休
│   │   ├── theme_screen.dart        # 主题设置
│   │   └── settings_screen.dart     # 设置页
│   ├── widgets/
│   │   └── week_timetable.dart      # 周课表组件
│   └── utils/
│       ├── constants.dart           # 常量（颜色、星期）
│       ├── date_utils.dart          # 日期工具
│       └── theme.dart               # 主题构建
├── ios/
│   └── Runner/
│       ├── AppDelegate.swift
│       ├── Info.plist
│       └── Widget/
│           └── ScheduleWidget.swift # iOS 桌面小组件
├── pubspec.yaml
└── README.md
```

---

## 部署与打包说明

### 一、环境准备

1. **安装 Flutter SDK**（3.10.0 或更高）
   ```bash
   # 下载 Flutter SDK
   git clone https://github.com/flutter/flutter.git -b stable
   # 添加到 PATH
   export PATH="$PATH:`pwd`/flutter/bin"
   # 运行诊断
   flutter doctor
   ```

2. **安装 Xcode**（iOS 打包必需，仅 macOS）
   - 从 App Store 安装 Xcode 15+
   - 安装命令行工具：`xcode-select --install`
   - 同意许可：`sudo xcodebuild -license`

3. **安装 CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

### 二、初始化项目

由于本工程未包含 `flutter create` 生成的原生脚手架，首次使用需执行：

```bash
cd class_schedule_app
# 生成 iOS 原生工程（保留已有的 lib/ 和 ios/ 自定义文件）
flutter create . --org com.example --project-name class_schedule
# 安装依赖
flutter pub get
# 安装 iOS Pods
cd ios && pod install && cd ..
```

> 注意：`flutter create .` 不会覆盖已存在的 lib/ 下的 Dart 文件，但会重置 ios/ 目录。
> 执行后请将本工程 `ios/Runner/` 下的 `AppDelegate.swift`、`Info.plist`、`Widget/` 目录复制回去。

### 三、iOS 桌面小组件配置

iOS 小组件需要在 Xcode 中手动配置 Widget Extension：

1. **打开 Xcode 工程**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **添加 Widget Extension**
   - File → New → Target → Widget Extension
   - Product Name: `ScheduleWidget`
   - 取消勾选 "Include Configuration App Intent"
   - Finish → Activate

3. **替换小组件代码**
   - 将 `ios/Runner/Widget/ScheduleWidget.swift` 的内容复制到新创建的 `ScheduleWidget.swift` 中

4. **配置 App Group**
   - 选中 Runner target → Signing & Capabilities → + Capability → App Groups
   - 添加 App Group：`group.com.example.classschedule`
   - 选中 ScheduleWidget target → 同样添加该 App Group
   - 确保两个 target 使用相同的 App Group ID

5. **修改 Bundle Identifier**
   - Runner: `com.example.classschedule`
   - ScheduleWidget: `com.example.classschedule.widget`

6. **设置 Deployment Target**
   - 两个 target 均设置为 iOS 16.0 或更高

### 四、Flutter 端 App Group 配置

在 `lib/services/widget_service.dart` 中确认 App Group ID 与 Xcode 中一致：

```dart
static const String appGroupId = 'group.com.example.classschedule';
```

同时需要在 iOS 原生层通过 MethodChannel 将数据写入 App Group 共享目录，
或使用 `path_provider` 的 `getApplicationSupportDirectory` 配合 App Group 桥接。

> 简化方案：在 AppDelegate 中添加 MethodChannel，接收 Flutter 传来的 JSON 数据，
> 写入 `group.com.example.classschedule` 共享容器的 `widget_data.json`。

### 五、调试运行

```bash
# 查看可用设备
flutter devices

# 运行到 iOS 模拟器
flutter run -d <模拟器ID>

# 运行到真机（需先在 Xcode 中签名）
flutter run -d <设备ID>
```

### 六、iOS 打包发布

1. **配置签名**
   - Xcode → Runner target → Signing & Capabilities
   - Team 选择你的 Apple Developer 账号
   - Bundle Identifier 修改为唯一标识（如 `com.yourname.classschedule`）

2. **构建 Release IPA**
   ```bash
   flutter build ipa --release
   ```
   产物位于 `build/ios/ipa/class_schedule.ipa`

3. **上传 App Store**
   - 使用 Xcode → Product → Archive → Distribute App
   - 或使用 Transporter App 上传 IPA

4. **TestFlight 测试**
   - 上传后在 App Store Connect 中添加测试人员
   - 通过 TestFlight 分发测试

### 七、Android 打包（可选）

虽然本项目重点在 iOS，但 Flutter 天然支持 Android：

```bash
# 生成签名密钥
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# 构建 APK
flutter build apk --release

# 构建 App Bundle（Google Play 推荐）
flutter build appbundle --release
```

### 八、常见问题

**Q: ICS 链接导入失败？**
A: 部分教务系统的 ICS 链接需要登录态。建议先在浏览器中下载 .ics 文件，再使用本地文件导入。

**Q: 通知不生效？**
A: iOS 需在首次启动时允许通知权限。检查 设置 → 通知 → 课程表 → 允许通知。

**Q: 小组件不显示数据？**
A: 确认 App Group 配置正确，两个 target 都添加了相同的 App Group ID。首次添加课程后小组件会在1小时内刷新，也可手动移除重新添加。

**Q: 如何修改默认作息时间？**
A: 在 设置 → 作息时间 中自由调整，或修改 `lib/models/time_slot.dart` 中的 `defaultTimeSlots()`。

---

## 许可证

MIT License
