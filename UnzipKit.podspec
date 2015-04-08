Pod::Spec.new do |s|
  s.name          = "UnzipKit"
  s.version       = "1.2"
  s.summary       = "An Objective-C zlib wrapper for compressing and decompressing Zip files"
  s.license       = "BSD"
  s.homepage      = "https://github.com/abbeycode/UnzipKit"
  s.author        = { "Dov Frankel" => "dov@abbey-code.com" }
  s.source        = { :git => "https://github.com/abbeycode/UnzipKit.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.9"
  s.requires_arc = 'Source/**/*'
  s.source_files = "Source/**/*.{m,h}",
                   "Lib/**/*.{c,h}"
  s.library      = "z"
end
