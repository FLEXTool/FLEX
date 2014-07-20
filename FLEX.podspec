Pod::Spec.new do |spec|
  spec.name             = "FLEX"
  spec.version          = "1.0.0"
  spec.summary          = "A set of in-app debugging and exploration tools for iOS"
  spec.description      = <<-DESC
                        - Inspect and modify views in the hierarchy.
                        - See the properties and ivars on any object.
                        - Dynamically modify many properties and ivars.
                        - Dynamically call instance and class methods.
                        - Access any live object via a scan of the heap.
                        - View the file system within your app's sandbox.
                        - Explore all classes in your app and linked systems frameworks (public and private).
                        - Quickly access useful objects such as `[UIApplication sharedApplication]`, the app delegate, the root view controller on the key window, and more.
                        - Dynamically view and modify `NSUserDefaults` values.
                        DESC

  spec.homepage         = "https://github.com/Flipboard/FLEX"
  spec.screenshots      = [ "https://dl.dropboxusercontent.com/u/8298593/basic-view-exploration.gif",
                            "https://dl.dropboxusercontent.com/u/8298593/advanced-view-editing.gif",
                            "https://dl.dropboxusercontent.com/u/8298593/heap-browser.gif",
                            "https://dl.dropboxusercontent.com/u/8298593/file-browser.gif",
                            "https://dl.dropboxusercontent.com/u/8298593/nsuserdefaults-editor.gif",
                            "https://dl.dropboxusercontent.com/u/8298593/system-libraries-browser.gif",
                            "https://dl.dropboxusercontent.com/u/8298593/flex-readme-reverse-1.png",
                            "https://dl.dropboxusercontent.com/u/8298593/flex-readme-reverse-2.png" ]

  spec.license          = { :type => "BSD", :file => "LICENSE" }
  spec.author           = { "Ryan Olson" => "ryanolsonk@gmail.com" }
  spec.social_media_url = "https://twitter.com/ryanolsonk"
  spec.platform         = :ios, "6.0"
  spec.source           = { :git => "https://github.com/Flipboard/FLEX.git", :tag => "1.0.0" }
  spec.source_files     = "Classes/**/*.{h,m}"
  spec.frameworks       = "CoreGraphics"
  spec.requires_arc     = true
end
