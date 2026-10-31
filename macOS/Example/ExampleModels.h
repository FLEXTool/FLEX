//
//  ExampleModels.h
//  FLEXMacExample
//
//  Sample objects to poke at with FLEX.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExamplePerson : NSObject
+ (instancetype)personWithName:(NSString *)name age:(NSInteger)age;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger age;
@property (nonatomic) double height;
@property (nonatomic, getter=isAdmin) BOOL admin;
@property (nonatomic) NSRect favoriteRect;
@property (nonatomic, nullable) NSColor *favoriteColor;
@property (nonatomic, nullable) NSURL *homepage;
@property (nonatomic) NSArray<NSString *> *tags;
@property (nonatomic, weak, nullable) ExamplePerson *friend;
@property (class, nonatomic, readonly) NSUInteger instanceCount;
- (NSString *)greetingForName:(NSString *)name times:(NSInteger)times;
- (void)celebrateBirthday;
@end

NS_ASSUME_NONNULL_END
