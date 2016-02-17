//
//  Owner.h
//  UICatalog
//
//  Created by Tim Oliver on 17/02/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#if __has_include(<Realm/Realm.h>)

#import <Realm/Realm.h>

@interface Owner : RLMObject
@property NSString *name;
@end

#endif