Pod::Spec.new do |s|
  s.name         = "RicohAPIAuth"
  s.version      = "1.0.3"
  s.summary      = "Ricoh Auth Client"
  s.description  = "Ricoh Auth Client in Swift"
  s.homepage     = "https://github.com/ricohapi/auth-swift"
  s.license      = "MIT"
  s.author       = "Ricoh Company, Ltd."
  s.deprecated   = true

  s.source       = { :git => "https://github.com/ricohapi/auth-swift.git", :tag => "v#{s.version}" }
  s.source_files  = "Source/*.swift"

  s.ios.deployment_target = '9.0'
end
