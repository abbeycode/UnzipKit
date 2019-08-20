Pod::Spec.new do |s|
  s.name             = "UnzipKit"
  s.version          = ENV["TRAVIS_TAG"]
  s.summary          = "An Objective-C zlib wrapper for compressing and decompressing Zip files"
  s.license          = "BSD"
  s.homepage         = "https://github.com/abbeycode/UnzipKit"
  s.author           = { "Dov Frankel" => "dov@abbey-code.com" }
  s.social_media_url = "https://twitter.com/dovfrankel"
  s.source           = { :git => "https://github.com/abbeycode/UnzipKit.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.14"
  s.swift_version         = "5.0"
  s.library = "z"
  s.requires_arc = 'Source/**/*'
  s.public_header_files  = "Source/UnzipKit.h",
                           "Source/UZKArchive.h",
                           "Source/UZKFileInfo.h"
  s.private_header_files = "Source/UZKFileInfo_Private.h"
  s.source_files         = "Source/**/*.{h,m,swift}"
  s.exclude_files        = 'Resources/**/Info.plist'
  s.resource_bundles = {
      'UnzipKitResources' => ['Resources/**/*']
  }
  s.script_phases = { :name => "Generate UnzipKit Swift Header",
                      :script => "\"${PODS_TARGET_SRCROOT}\"/Scripts/generate-swift-import-header.sh",
                      :execution_position => :before_compile }
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/*.{h,m,swift}'
    test_spec.exclude_files = 'Tests/ExtractFilesTests.m',
                              'Tests/UnzipKitTests-Bridging-Header.h'
    test_spec.preserve_paths = 'Tests/UnzipKitTests-Bridging-Header.h'
    test_spec.resources = ['Tests/Test Data']
    test_spec.pod_target_xcconfig = {
        "OTHER_CFLAGS" => "$(inherited) -Wno-unguarded-availability",
        "SWIFT_OBJC_BRIDGING_HEADER" => "$(PODS_TARGET_SRCROOT)/Tests/UnzipKitTests-Bridging-Header.h"
    }
    test_spec.scheme = {
        # Disable logging. Comment this line if you need diagnostic info
        :environment_variables => { "OS_ACTIVITY_MODE" => "disable" }
    }
  end

  s.subspec "minizip-lib" do |ss|
    ss.private_header_files = "Lib/MiniZip/*.h"
    ss.source_files = "Lib/MiniZip/*.{h,c}"
    ss.pod_target_xcconfig = { "OTHER_CFLAGS" => "$(inherited) -Wno-comma -Wno-strict-prototypes" }
  end
end
