//
//  ExampleModels.m
//  FLEXMacExample
//

#import "ExampleModels.h"

static NSUInteger _instanceCount = 0;

@implementation ExamplePerson {
    NSString *_secretNickname;
    int _luckyNumber;
}

+ (instancetype)personWithName:(NSString *)name age:(NSInteger)age {
    ExamplePerson *person = [self new];
    person.name = name;
    person.age = age;
    person.height = 1.62 + (age % 20) / 100.0;
    person.favoriteRect = NSMakeRect(10, 20, 300, 200);
    person.favoriteColor = NSColor.systemPurpleColor;
    person.homepage = [NSURL URLWithString:@"https://github.com/FLEXTool/FLEX"];
    person.tags = @[@"debugging", @"objc", @"macOS"];
    person->_secretNickname = [name.lowercaseString stringByAppendingString:@"_the_great"];
    person->_luckyNumber = (int)age * 7;
    return person;
}

+ (NSUInteger)instanceCount {
    return _instanceCount;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _instanceCount++;
    }
    return self;
}

- (NSString *)greetingForName:(NSString *)name times:(NSInteger)times {
    NSMutableArray *parts = [NSMutableArray new];
    for (NSInteger i = 0; i < MAX(times, 1); i++) {
        [parts addObject:[NSString stringWithFormat:@"Hello %@, I'm %@!", name, self.name]];
    }
    return [parts componentsJoinedByString:@" "];
}

- (void)celebrateBirthday {
    self.age += 1;
    NSLog(@"🎂 %@ is now %ld", self.name, (long)self.age);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; name = %@; age = %ld>", self.class, self, self.name, (long)self.age];
}

@end
