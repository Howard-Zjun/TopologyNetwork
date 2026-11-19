platform :ios, '27.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'TopologyNetwork' do
  use_frameworks!
  pod 'SnapKit', '5.7.1'
  pod 'MyBaseExtension', '0.0.6'
  pod 'SwiftSVG', '2.3.2'
  pod 'RxSwift'
  pod 'RxRelay'
end

post_install do |installer|
  minimum_ios_version = Gem::Version.new('27.0')
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      current_version = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if current_version.nil? || Gem::Version.new(current_version) < minimum_ios_version
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = minimum_ios_version.to_s
      end
    end
  end
end
