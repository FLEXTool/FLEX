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
    return bob;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInteger:self.age forKey:@"age"];
    [coder encodeDouble:self.height forKey:@"height"];
    [coder encodeObject:self.numberOfKids forKey:@"numberOfKids"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self->_name = [coder decodeObjectForKey:@"name"];
    self->_age = [coder decodeIntegerForKey:@"age"];
    self->_height = [coder decodeDoubleForKey:@"height"];
    self->_numberOfKids= [coder decodeObjectForKey:@"numberOfKids"];
    return self;
}

@end
