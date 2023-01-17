//
//  FLEXColorPreviewSection.h
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "Classes/Headers/FLEXSingleRowSection.h"
#import "Classes/Headers/FLEXObjectInfoSection.h"

@interface FLEXColorPreviewSection : FLEXSingleRowSection <FLEXObjectInfoSection>

+ (instancetype)forObject:(UIColor *)color;

@end
