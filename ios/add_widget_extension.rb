#!/usr/bin/env ruby
# 自动添加 Widget Extension 到 Xcode 项目
# 在 Codemagic 构建前运行

require 'xcodeproj'
require 'fileutils'

project_path = 'ios/Runner.xcodeproj'
widget_dir = 'Widget'  # 相对于 ios/ 目录

# 打开项目
project = Xcodeproj::Project.open(project_path)
main_target = project.targets.find { |t| t.name == 'Runner' }

# 检查是否已存在 Widget target
existing = project.targets.find { |t| t.name == 'ScheduleWidget' }
if existing
  puts "Widget target already exists, skipping"
  exit 0
end

# 创建 Widget Extension target
widget_target = project.new_target(:app_extension, 'ScheduleWidget', :ios, '16.0')
widget_target.product_name = 'ScheduleWidget'

# 添加 Widget 源文件
Dir.glob(File.join(widget_dir, '*.swift')).each do |file|
  file_ref = project.main_group.new_file(file)
  widget_target.add_file_references([file_ref])
end

# 设置 Widget target 的配置
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'ScheduleWidget'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.classSchedule.ScheduleWidget'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = '课程表'
  config.build_settings['WRAPPER_EXTENSION'] = 'appex'
  config.build_settings['SKIP_INSTALL'] = 'YES'
end

# 创建 Widget entitlements
widget_entitlements = 'Widget/ScheduleWidget.entitlements'
File.write(File.join('ios', widget_entitlements), <<~PLIST)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.application-groups</key>
  <array>
    <string>group.com.example.classSchedule</string>
  </array>
</dict>
</plist>
PLIST

# 添加 entitlements 到 Widget target
entitlements_ref = project.main_group.new_file(widget_entitlements)
widget_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Widget/ScheduleWidget.entitlements'
end

# 主应用也添加 App Group entitlements
main_entitlements = 'Runner/Runner.entitlements'
if File.exist?(File.join('ios', main_entitlements))
  main_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  end
end

# 嵌入 Widget 到主应用（标准方式：添加依赖 + Frameworks phase）
widget_product = widget_target.product_reference
main_target.add_dependency(widget_target)

# 添加到 Frameworks build phase（自动嵌入到 PlugIns）
frameworks_phase = main_target.frameworks_build_phase
build_file = frameworks_phase.add_file_reference(widget_product)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy', 'CodeSignOnCopy'] }

project.save
puts "Widget Extension added successfully!"
puts "Widget target: #{widget_target.name}"
puts "Bundle ID: com.example.classSchedule.ScheduleWidget"
puts "App Group: group.com.example.classSchedule"
