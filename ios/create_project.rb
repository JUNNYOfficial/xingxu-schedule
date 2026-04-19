#!/usr/bin/env ruby
# 自动生成星序 iOS Xcode 项目

require 'xcodeproj'

PROJECT_PATH = 'XingXu.xcodeproj'
BUNDLE_ID = 'com.xingxu.schedule'
WIDGET_BUNDLE_ID = 'com.xingxu.schedule.widget'
IOS_DEPLOYMENT_TARGET = '16.0'
SWIFT_VERSION = '5.9'

# ========== 清理旧项目 ==========
if File.exist?(PROJECT_PATH)
  require 'fileutils'
  FileUtils.rm_rf(PROJECT_PATH)
  puts "已删除旧项目"
end

# ========== 创建项目 ==========
project = Xcodeproj::Project.new(PROJECT_PATH)
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = IOS_DEPLOYMENT_TARGET
  config.build_settings['SWIFT_VERSION'] = SWIFT_VERSION
end

# ========== 主 App Target ==========
app_target = project.new_target(:application, 'XingXu', :ios, IOS_DEPLOYMENT_TARGET)
app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  config.build_settings['INFOPLIST_FILE'] = 'XingXu/Info.plist'
  config.build_settings['SWIFT_VERSION'] = SWIFT_VERSION
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'YES'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'XingXu.entitlements'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0.0'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
end

# 添加系统框架
app_target.add_system_framework('UIKit')
app_target.add_system_framework('WebKit')
app_target.add_system_framework('UserNotifications')
app_target.add_system_framework('WidgetKit')

# ========== 创建文件组 ==========
main_group = project.main_group
app_group = main_group.new_group('XingXu')
shared_group = main_group.new_group('Shared')
web_group = main_group.new_group('WebResources')

# ========== 添加主 App 源文件 ==========
app_sources = [
  'XingXu/AppDelegate.swift',
  'XingXu/SceneDelegate.swift',
  'XingXu/WebViewController.swift',
]

app_sources.each do |path|
  file_ref = app_group.new_file(path)
  app_target.source_build_phase.add_file_reference(file_ref)
end

# ========== 添加共享数据文件（主 App） ==========
shared_file = shared_group.new_file('Shared/SharedData.swift')
app_target.source_build_phase.add_file_reference(shared_file)

# ========== 添加资源文件 ==========
# LaunchScreen.storyboard
launch_ref = app_group.new_file('XingXu/LaunchScreen.storyboard')
app_target.resources_build_phase.add_file_reference(launch_ref)

# Info.plist (作为引用，不作为资源打包)
info_ref = app_group.new_file('XingXu/Info.plist')

# Entitlements
entitlements_ref = main_group.new_file('XingXu.entitlements')

# Assets
assets_ref = app_group.new_file('XingXu/Assets.xcassets')
app_target.resources_build_phase.add_file_reference(assets_ref)

# ========== 添加 Web 资源 ==========
web_files = ['index.html', 'app.js', 'styles.css', 'manifest.json', 'sw.js']
web_files.each do |filename|
  # Web 文件在项目根目录，需要向上走一级
  file_ref = web_group.new_file("../#{filename}")
  app_target.resources_build_phase.add_file_reference(file_ref)
end

# ========== Widget Extension Target ==========
widget_target = project.new_target(:app_extension, 'XingXuWidget', :ios, IOS_DEPLOYMENT_TARGET)
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
  config.build_settings['INFOPLIST_FILE'] = 'XingXuWidget/Info.plist'
  config.build_settings['SWIFT_VERSION'] = SWIFT_VERSION
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0.0'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'XingXuWidget/XingXuWidget.entitlements'
  config.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
end

# Widget 框架
widget_target.add_system_framework('WidgetKit')
widget_target.add_system_framework('SwiftUI')

# ========== 添加 Widget 源文件 ==========
widget_group = main_group.new_group('XingXuWidget')
widget_sources = [
  'XingXuWidget/XingXuWidgetBundle.swift',
  'XingXuWidget/XingXuWidget.swift',
  'XingXuWidget/Provider.swift',
  'XingXuWidget/Entry.swift',
]

widget_sources.each do |path|
  file_ref = widget_group.new_file(path)
  widget_target.source_build_phase.add_file_reference(file_ref)
end

# 添加共享数据文件到 Widget
widget_target.source_build_phase.add_file_reference(shared_file)

# Widget entitlements
widget_entitlements_ref = widget_group.new_file('XingXuWidget/XingXuWidget.entitlements')

# Widget Info.plist (引用)
widget_info_ref = widget_group.new_file('XingXuWidget/Info.plist')

# ========== 设置 Target 依赖 ==========
app_target.add_dependency(widget_target)

# 嵌入 Widget Extension
embed_phase = app_target.new_copy_files_build_phase('Embed Foundation Extensions')
embed_phase.dst_subfolder_spec = '13'  # PlugIns folder
widget_product = widget_target.product_reference
embed_phase.add_file_reference(widget_product)

# ========== 设置 Launch Screen ==========
app_target.build_configurations.each do |config|
  config.build_settings['UILaunchStoryboardName'] = 'LaunchScreen'
end

# ========== 保存项目 ==========
project.save
puts "✅ Xcode 项目已生成: #{PROJECT_PATH}"
puts ""
puts "下一步："
puts "1. 在 Xcode 中打开 #{PROJECT_PATH}"
puts "2. 选择你的 Team（Signing & Capabilities）"
puts "3. 添加 App Groups capability: group.com.xingxu.schedule"
puts "4. 运行编译"
