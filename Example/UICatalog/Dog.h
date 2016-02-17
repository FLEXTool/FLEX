//
//  Dog.h
//  UICatalog
//
//  Created by Tim Oliver on 17/02/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#if __has_include(<Realm/Realm.h>)

#import <Realm/Realm.h>
#import "Owner.h"

@interface Dog : RLMObject
@property NSString *name;
@property CGFloat height;
@property NSDate *birthdate;
@property BOOL vaccinated;
@property Owner *owner;
@end

#endif