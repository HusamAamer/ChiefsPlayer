# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'ChiefsPlayer' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ChiefsPlayer
  pod 'google-cast-sdk', "~> 4.5"
  
  post_install do |pi|
      pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
      end
  end
  
end
