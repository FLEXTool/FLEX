//
//  Person.m
//  UICatalog
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 f. All rights reserved.
//

#import "Person.h"

@implementation Person

+ (id)bob {
    Person *bob = [Person new];
    bob->_name = @"Bob";
    bob->_age = 50;
    bob->_height = 5.8;
    bob->_numberOfKids = @3;
    bob->_netWorth = [NSDecimalNumber decimalNumberWithString:@"12345.67"];
    return bob;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInteger:self.age forKey:@"age"];
    [coder encodeDouble:self.height forKey:@"height"];
    [coder encodeObject:self.numberOfKids forKey:@"numberOfKids"];
    [coder encodeObject:self.netWorth forKey:@"netWorth"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self->_name = [coder decodeObjectForKey:@"name"];
    self->_age = [coder decodeIntegerForKey:@"age"];
    self->_height = [coder decodeDoubleForKey:@"height"];
    self->_numberOfKids = [coder decodeObjectForKey:@"numberOfKids"];
    self->_netWorth = [coder decodeObjectForKey:@"netWorth"];
    return self;
}

- (void)setNetWorth:(NSDecimalNumber *)netWorth {
    _netWorth = netWorth;
}

- (NSUInteger)hash {
    return self.name.hash ^ @(self.age).hash ^ self.numberOfKids.hash ^ self.netWorth.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[Person class]])
        return [self isEqualToPerson:object];

    return [super isEqual:object];
}

- (BOOL)isEqualToPerson:(Person *)person {
    return [self.name isEqualToString:person.name];
}

+ (NSInteger)version {
    return 2;
}

@end
