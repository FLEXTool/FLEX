//
//  FLEXSwiftMirror.h
//  FLEX
//
//  Created by Tanner on 10/28/17.
//  Copyright © 2017 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLEXSwiftMirror : NSObject

+ (BOOL)isSwiftObjectOrClass:(id)objectOrClass;

+ (instancetype)reflecting:(id)objectOrClass;

@property (nonatomic, readonly) id target;
@property (nonatomic, readonly) FLEXSwiftMirror *classMirror;

- (NSString *)typeNameForIvarAtOffset:(NSUInteger)offset;

@end
