
[![Version](https://img.shields.io/cocoapods/v/KZBootstrap.svg?style=flat)](http://cocoadocs.org/docsets/KZBootstrap)
[![License](https://img.shields.io/cocoapods/l/KZBootstrap.svg?style=flat)](http://cocoadocs.org/docsets/KZBootstrap)
[![Platform](https://img.shields.io/cocoapods/p/KZBootstrap.svg?style=flat)](http://cocoadocs.org/docsets/KZBootstrap)

# iOS Project bootstrap
How do you setup your iOS projects?

Since we are approaching 2015 I’m working on refreshing my project bootstrap. I’ve decided to open source it so other can benefit or contribute. 

I think it’s pretty neat but decide for yourself. 

It’s still WIP so pull requests are most welcomed.

## Basic setup and configuration
A project by default has 3 configurations:

1. Debug
2. Release
3. Adhoc

Each configuration can be put side by side on same device, and you can clearly distingiush each build. Easier to find issues across different version and branches.
![](/Screenshots/Configurations.png?raw=true)

Looking at each of the icon you get following informations:
- Build number: 29
- Branch: Master
- Commit hash
- Version: 1.0
 - Configuration that the app was built with

> You can also use KZBootstrap API to query those informations while running your application.

![](/Screenshots/log.png?raw=true)

## Code Quality and Warnings
Warnings were added by compiler team for a reason, as such I start with Weverything and disable few warnings:
- Wno-objc-missing-property-synthesis - don’t want to do @synthesize on properties
- Wno-unused-macros - annoying when doing DSL
- Wno-disabled-macro-expansion - needed for DSL/Metaprogramming
- Wno-gnu-statement-expression - helpful
- Wno-language-extension-token - language extensions are useful
- Wno-overriding-method-mismatch - so I can change id to specific type and avoid unnecesary local variables

Also treat warnings as errors is a must.

### That’s not all, let’s add some scripts:

- turn all todo/fixme into warnings![](/Screenshots/todo.png?raw=true)
- warnings when files get to big ![](/Screenshots/lines.png?raw=true)
	- add KZBIgnoreLineCount anywhere in file to disable warning generation for that file.
- Automatically generate macro for current developer, that way a team can have different code paths while they are working on features, or different logging levels. Without git changes.
 
```objc
	#if merowing
	//! my code
	#endif 
```

One more thing, let’s add some macros:
To prevent nil passed in as arguments:

* KZB_REQUIRE_ALL_PARAMS
* KZB_REQUIRE_PARAMS(1,2)

![](/Screenshots/null.png?raw=true)

When your subclasses should call super:
* KZB_REQUIRE_SUPER

![](/Screenshots/super.png?raw=true)

When you want to avoid spelling errors:
* KZB_KEYPATH
* KZB_KEYPATH_T

![](/Screenshots/keypaths.png?raw=true)

## Environments
Often when working with big clients, you need to have multiple environments for Staging / Production / QA etc. They usually differ in some kind of configuration, eg. different URL endpoints.

Too many times I’ve seen people creating separate targets for each of them, which leads to maintenance costs and unnecessary bloat/clutter.

As such I’ve created a different approach, with some nice automation:
- Default environments can be changed either via xcodebuild user variable (on Jenkins) or via launch argument inside your schema.
	- on jenkins, xcodebuild …  KZBEnv=@”Production” build
	- in custom Schema: Edit Scheme-\>Arguments-\>Launch Arguments-\> “-KZBEnvOverride Production”
- Environments can be changed without reinstalling application, even while it’s running.
- All environments variables are created in a single plist ![](/Screenshots/plist.png?raw=true)
	- If any of the variables is missing entry for one of the environments you get **compile time error**. You can even click on it to go to configuration file. ![](/Screenshots/env_error.png?raw=true)
	- Settings bundle will be *automatically injected* to give you environment switching. ![](/Screenshots/Settings.png?raw=true)
	- You can register for callback when env changes, useful if you need to reset your database etc.
	- Production builds will remove all variables for other environments to prevent exposing non-production and unused configurations.

## Logging - Optional
If you are using CocoaLumberjack you can include KZBootstrap/Logging subspec to get log formatting that works as clickable links in AppCode.
![](/Screenshots/logs.png?raw=true)

## Debugging - Optional
If you decide to include KZBootstrap/Debug subspec, you will get:

- assertions when UIKit is layouted/displayed on background thread, so you can fix your code.
- API interception capabilities for AFNetworking, which you can either display yourself (or send me PR with universal UI). Or just look at during debuging by calling 

```objc
[KZBResponseTracker printAll]
```

![](/Screenshots/json.png?raw=true)


## Installing KZBootstrap
KZBootstrap is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

- KZBootstrap - for core functionality
- KZBootstrap/Logging - additional logging functionality
- KZBootstrap/Debug - additional debugging functionality

There are few things you need to do with your project, you can either use my crafter setup tool to make it automatic or do it manually:

- KZBEnvironments.plist with KZBEnvironments key containing array of all environments. All extra keys are treated as env variables and should have a value for each of the allowed env’s.
- BUNDLE_DISPLAY_NAME_SUFFIX _and BUNDLE_ID_SUFFIX should be added to User-Defined settings
	- In your target .plist file append both display name and bundle identifier keys with those variables eg. `app${BUNDLE_DISPLAY_NAME_SUFFIX}`
- Add KZBEnv user-defined setting with value of default env for each configuration then in preprocessor macros add KZBDefaultEnv=${KZBEnv}
- Add empty file named KZBootstrapUserMacros.h anywhere in your project, and include it into your \*prefix.pch file. Include that file in your .gitignore.
- Set warnings as described above.
- You should have Settings.bundle in the project so the code can inject it with environment switching functionality.
- Add script execution at the end of your Build Phases `"${SRCROOT}/Pods/KZBootstrap/Pod/Assets/Scripts/bootstrap.sh"`

Base [crafter](https://github.com/krzysztofzablocki/crafter) setup might look like this, replace CUSTOM with your preferred steps:
```ruby
# All your configuration should happen inside configure block
Crafter.configure do

  # This are projects wide instructions
  add_platform({:platform => :ios, :deployment => 7.0})
  add_git_ignore
  duplicate_configurations({:adhoc => :release})

  # set of options, warnings, static analyser and anything else normal xcode treats as build options
  set_options %w(
    RUN_CLANG_STATIC_ANALYZER
    GCC_TREAT_WARNINGS_AS_ERRORS
  )

  set_build_settings({
    :'WARNING_CFLAGS' => %w(
    -Weverything
    -Wno-objc-missing-property-synthesis
    -Wno-unused-macros
    -Wno-disabled-macro-expansion
    -Wno-gnu-statement-expression
    -Wno-language-extension-token
    -Wno-overriding-method-mismatch
    ).join(" ")
  })

  set_build_settings({
    :'BUNDLE_ID_SUFFIX' => '.dev',
    :'BUNDLE_DISPLAY_NAME_SUFFIX' => 'dev',
    :'KZBEnv' => 'QA'
  }, configuration: :debug)

  set_build_settings({
    :'BUNDLE_ID_SUFFIX' => '.adhoc',
    :'BUNDLE_DISPLAY_NAME_SUFFIX' => 'adhoc',
    :'KZBEnv' => 'QA'
  }, configuration: :adhoc)

  set_build_settings({
    :'BUNDLE_ID_SUFFIX' => '',
    :'BUNDLE_DISPLAY_NAME_SUFFIX' => '',
    :'KZBEnv' => 'PRODUCTION'
  }, configuration: :release)
  
  # CUSTOM: Modify plist file to include suffix and displayname
  # CUSTOM: Add empty KZBootstrapUserMacros.h file to your project and .gitignore
  # CUSTOM: Add KZBEnvironments.plist with list of your environments under KZBEnvironments key

  # target specific options, :default is just a name for you, feel free to call it whatever you like
  with :default do

    # each target have set of pods
    pods << %w(KZAsserts KZBootstrap KZBootstrap/Logging KZBootstrap/Debug)
    
    # add build script for bootstrap
    scripts << {:name => 'KZBootstrap setup', :script => '"${SRCROOT}/Pods/KZBootstrap/Pod/Assets/Scripts/bootstrap.sh'}

  end
end
```
In you want to support dynamic env switching app delegate you can add something like this:

```objc
 NSLog(@"user variable = %@, launch argument %@", @"d", [[NSUserDefaults standardUserDefaults] objectForKey:@"KZBEnvOverride"]);
  KZBootstrap.defaultBuildEnvironment = KZBEnv;
  KZBootstrap.onCurrentEnvironmentChanged = ^(NSString *newEnv, NSString *oldEnv) {
    NSLog(@"Changing env from %@ to %@", oldEnv, newEnv);
  };
  [KZBootstrap ready];
  
  NSLog(@"KZBootstrap:\n\tshortVersion: %@\n\tbranch: %@\n\tbuildNumber: %@\n\tenvironment: %@", KZBootstrap.shortVersionString, KZBootstrap.gitBranch, @(KZBootstrap.buildNumber), KZBootstrap.currentEnvironment);
```


# License
KZBootstrap is available under the MIT license. See the LICENSE file for more info.

## Author

Krzysztof Zablocki, krzysztof.zablocki@pixle.pl

[My blog](http://merowing.info)

[Follow me on twitter.](http://twitter.com/merowing_)

# Attributions
All of this wouldn’t be possible if we didn’t have such a great community, based on my own previous work but also countless other. Tried to reference everything but if you think I missed something [please let me know](http://twitter.com/merowing_).

References:

[http://stackoverflow.com/questions/10497552/how-to-configure-independent-sets-of-runtime-settings-in-xcode](%5Bhttp://stackoverflow.com/questions/10497552/how-to-configure-independent-sets-of-runtime-settings-in-xcode%5D)

[https://github.com/crushlovely/Amaro](https://github.com/crushlovely/Amaro)

[https://github.com/crushlovely/Sidecar](https://github.com/crushlovely/Sidecar)

[http://swwritings.com/post/2013-05-20-concurrent-debug-beta-app-store-builds](http://swwritings.com/post/2013-05-20-concurrent-debug-beta-app-store-builds)

[https://gist.github.com/dulaccc/a52154ac4c007db2be55](https://gist.github.com/dulaccc/a52154ac4c007db2be55)

[https://gist.github.com/steipete/5664345](https://gist.github.com/steipete/5664345)

[http://blog.manbolo.com/2013/05/17/passing-user-variable-to-xcodebuild](http://blog.manbolo.com/2013/05/17/passing-user-variable-to-xcodebuild)

[http://blog.jaredsinclair.com/post/97193356620/the-best-of-all-possible-xcode-automated-build](http://blog.jaredsinclair.com/post/97193356620/the-best-of-all-possible-xcode-automated-build)

[https://github.com/krzysztofzablocki/crafter](https://github.com/krzysztofzablocki/crafter)

[https://github.com/krzysztofzablocki/IconOverlaying](https://github.com/krzysztofzablocki/IconOverlaying)

Big thanks goes to [Lextech Global Services](http://lextech.com) for supporting my community work, they are awesome. If you need a mobile app for your enterprise, you should talk to them.

