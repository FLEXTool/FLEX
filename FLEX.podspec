Pod::Spec.new do |spec|
  spec.name             = "FLEX"
  spec.version          = "2.3.0"
  spec.summary          = "A set of in-app debugging and exploration tools for iOS"
  spec.description      = <<-DESC
                        - Inspect and modify views in the hierarchy.
                        - View Detailed network request history.
                        - See the properties and ivars on any object.
                        - Dynamically modify many properties and ivars.
                        - Dynamically call instance and class methods.
                        - Access any live object via a scan of the heap.
                        - See system log messages (i.e. from `NSLog()`).
                        - View the file system within your app's sandbox.
                        - Explore all classes in your app and linked systems frameworks (public and private).
                        - Quickly access useful objects such as `[UIApplication sharedApplication]`, the app delegate, the root view controller on the key window, and more.
                        - Dynamically view and modify `NSUserDefaults` values.
                        DESC

  spec.homepage         = "https://github.com/Flipboard/FLEX"
  spec.screenshots      = [ "http://engineering.flipboard.com/assets/flex/basic-view-exploration.gif",
                            "http://engineering.flipboard.com/assets/flex/advanced-view-editing.gif",
                            "http://engineering.flipboard.com/assets/flex/heap-browser.gif",
                            "http://engineering.flipboard.com/assets/flex/file-browser.gif",
                            "http://engineering.flipboard.com/assets/flex/nsuserdefaults-editor.gif",
                            "http://engineering.flipboard.com/assets/flex/system-libraries-browser.gif",
                            "http://engineering.flipboard.com/assets/flex/flex-readme-reverse-1.png",
                            "http://engineering.flipboard.com/assets/flex/flex-readme-reverse-2.png" ]

  spec.license          = { :type => "BSD", :file => "LICENSE" }
  spec.author           = { "Ryan Olson" => "ryanolsonk@gmail.com" }
  spec.social_media_url = "https://twitter.com/ryanolsonk"
  spec.platform         = :ios, "8.0"
  spec.source           = { :git => "https://github.com/Flipboard/FLEX.git", :tag => "#{spec.version}" }
  spec.source_files     = "Classes/**/*.{h,m}"
  spec.frameworks       = [ "Foundation", "UIKit", "CoreGraphics" ]
  spec.libraries        = [ "z", "sqlite3" ]
  spec.requires_arc     = true
  spec.public_header_files = [ "Classes/**/FLEXManager.h", "Classes/FLEX.h" ]
end
