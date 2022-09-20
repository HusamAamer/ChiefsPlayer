# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'ChiefsPlayer' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ChiefsPlayer
	# google-cast-sdk version +4.7 drops support for iOS10+iOS11 😭
  pod 'google-cast-sdk', "~> 4.6"
  
  post_install do |pi|
      pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
      end

      pi.pods_project.build_configurations.each do |config|
        config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
				config.build_settings["ENABLE_BITCODE"] = "YES"
      end
  end
  
end
