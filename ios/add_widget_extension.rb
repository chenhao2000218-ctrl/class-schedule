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
widget_target = existing || project.new_target(:app_extension, 'ScheduleWidget', :ios, '16.0')
widget_target.product_name = 'ScheduleWidget'

# 添加 Widget 源文件
Dir.glob(File.join(widget_dir, '*.swift')).each do |file|
  file_ref = project.files.find { |ref| ref.path == file } || project.main_group.new_file(file)
  widget_target.add_file_references([file_ref])
end

# 设置 Widget target 的配置
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'ScheduleWidget'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.classSchedule.ScheduleWidget'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['INFOPLIST_FILE'] = 'Widget/Info.plist'
  config.build_settings['WRAPPER_EXTENSION'] = 'appex'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
end

# 确保 Widget entitlements 存在
widget_entitlements = 'Widget/ScheduleWidget.entitlements'
unless File.exist?(File.join('ios', widget_entitlements))
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
end

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

# 只添加 target 依赖（主应用构建时会先构建 Widget），不添加嵌入 phase
# 嵌入在构建脚本中手动处理，避免 Xcode 26 的循环依赖问题
widget_product = widget_target.product_reference
main_target.add_dependency(widget_target)

project.save
puts existing ? "Widget Extension repaired successfully!" : "Widget Extension added successfully!"
puts "Widget target: #{widget_target.name}"
puts "Bundle ID: com.example.classSchedule.ScheduleWidget"
puts "App Group: group.com.example.classSchedule"
