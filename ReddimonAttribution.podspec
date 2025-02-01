Pod::Spec.new do |spec|
  spec.name         = "ReddimonAttribution"
  spec.version      = "1.0.1"
  spec.summary      = "Attribution SDK for iOS apps"
  spec.description  = <<-DESC
                     Track app installations and conversions from creator links.
                     Includes fraud prevention and attribution tracking.
                     DESC
  spec.homepage     = "https://github.com/Davidon4/reddimon-attribution-ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Your Name" => "your.email@example.com" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/Davidon4/reddimon-attribution-ios.git", 
                       :tag => "#{spec.version}" }
  spec.source_files = "Attribution/**/*.swift"
  spec.swift_versions = "5.5"
end 