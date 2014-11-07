# KZAsserts - Asserts on roids, test all your assumptions with ease.

[![Version](http://cocoapod-badges.herokuapp.com/v/KZAsserts/badge.png)](http://cocoadocs.org/docsets/KZAsserts)
[![Platform](http://cocoapod-badges.herokuapp.com/p/KZAsserts/badge.png)](http://cocoadocs.org/docsets/KZAsserts)

There are many ways in which we can improve quality of our code-base, Assertions are one of them.
Yet very few people actually use asserts, why is that?

An assert is used to make certain that a specific condition is true, because our apps don't exist in a vacuum  and we often work with other API's (or our own), we need to make sure our assumptions about it are actually valid or we might have really weird bugs.

If our assumption is wrong, assert will crash on the line that checks that condition thus allowing us to find bugs in our code very quickly. 

This is great concept, *crash early and crash often*, it makes it easy to have clean and bug free code.

On the other hand Release build should avoid crashing whenever possible, unless you like 1-star rating?

Because of that normal assertions are **not enough**, you need to make sure your code handles errors even in release builds, if you just strip assertions from release you are still going to crash if your assumption was wrong (eg. after striping asserts you'll have code that mismatches types etc.)!  


How great would it be to assert all assumptions regarding server API responses, so that if backend changes you know it immediately and you can fix your code? So people end up with something like this:  

````
NSParameterAssert([dataFromServer isKindOfClass:[NSDictionary class]]);
if ([dataFromServer isKindOfClass:[NSDictionary class]]) {
  //! create NSError, handle it
}

NSParameterAssert([something isKindOfClass:[NSString class]]);
if ([something isKindOfClass:[NSString class]]) {
  //! create NSError, handle it
}
````
Obviously they could store that condition once and reuse it in assert and if statement, it still sucks!

Now imagine testing your whole response format, that would be so much unnecesary and hard to read code!

That's why I've come up with KZAsserts around 2 years ago, this is how that could can look:

````
AssertTrueOrReturnError([dataFromServer isKindOfClass:[NSDictionary class]]);
AssertTrueOrReturnError([something isKindOfClass:[NSString class]]);
````

This will crash in debug, but in release it will automatically generate NSError for you, it will then return that error object from the current scope. It can also log message to your logger / server / console:
![IMAGE](../master/Log.png?raw=true) 

And that's not all, you probably write a lot of async code in your apps? KZAsserts handles that as easily:
````
- (void)downloadFromURL:(NSURL*)url withCompletion:(void (^)(NSData *, NSError *))completionBlock
{
	AssertTrueOrReturnNilBlock([something isKindOfClass:[NSString class]], ^(NSError *error) {
  		completionBlock(nil, error);
	});
	//! ...
}
````

With those kind of macros, you can now assert all your assumptions. 
I'd also encourage you to use Asserts for enforcing API contracts:
eg. if you have a method that downloads NSData * and the only way to get the results is via completion block, you should assert there actually is completion block. Otherwise you are wasting your user battery/network.

## Assert macros

KZAsserts provies following asserts:

````
  AssertTrueOr[X](condition) - if condition fails to be true, on debug builds it will crash by using Assertion, on Release builds it calls error creation and perform specific action. Asserts with block param will execute ^(NSError *){} passed in block with auto-generated NSError.

  AssertTrueOrReturnError
  AssertTrueOrReturnErrorBlock

  AssertTrueOrReturn
  AssertTrueOrReturnBlock

  AssertTrueOrReturnNo
  AssertTrueOrReturnNoBlock

  AssertTrueOrReturnNil
  AssertTrueOrReturnNilBlock

  AssertTrueOrContinue
  AssertTrueOrContinueBlock

  AssertTrueOrBreak
  AssertTrueOrBreakBlock

````

## Installation

KZAsserts is available through [CocoaPods](http://cocoapods.org) for both OSX and iOS, to install
it simply add the following line to your Podfile:

    pod "KZAsserts"

## Supplying your own NSError creation function
If you want to have your own NSError creation function you can just add following line on top of your applicationDidFinishLaunching:
````
[KZAsserts registerErrorFunction:myErrorCreationFunction];
````
You can also change whole format of logging by defining your own KZAMakeError macro.

## Author

Krzysztof Zablocki, [@merowing_](http://twitter.com/merowing_)
[my blog](http://merowing.info)
## License

KZAsserts is available under the MIT license. See the LICENSE file for more info.

