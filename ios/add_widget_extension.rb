#!/usr/bin/env ruby
# 自动添加 Widget Extension 到 Xcode 项目
# 在 Codemagic 构建前运行

require 'xcodeproj'
require 'fileutils'

project_path = 'ios/Runner.xcodeproj'
widget_dir = 'ios/Widget'

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
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.classSchedule.ScheduleWidget'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = '课程表'
  config.build_settings['INFOPLIST_KEY_NSHumanReadableCopyright'] = ''
end

# 创建 Widget entitlements
widget_entitlements = 'ios/Widget/ScheduleWidget.entitlements'
File.write(widget_entitlements, <<~PLIST)
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
main_entitlements = 'ios/Runner/Runner.entitlements'
if File.exist?(main_entitlements)
  main_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  end
end

# 嵌入 Widget 到主应用
embed_frameworks = main_target.frameworks_build_phase
embed_app_extensions = main_target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && p.name == 'Embed App Extensions' }
unless embed_app_extensions
  embed_app_extensions = main_target.new_copy_files_build_phase
  embed_app_extensions.name = 'Embed App Extensions'
  embed_app_extensions.symbol_dst_subfolder_spec = :app_extensions
end

widget_product = widget_target.product_reference
embed_app_extensions.add_file_reference(widget_product)

# 添加依赖关系
main_target.add_dependency(widget_target)

project.save
puts "Widget Extension added successfully!"
puts "Widget target: #{widget_target.name}"
puts "Bundle ID: com.example.classSchedule.ScheduleWidget"
puts "App Group: group.com.example.classSchedule"
