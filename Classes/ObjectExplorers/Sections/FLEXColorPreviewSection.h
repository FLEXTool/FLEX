//
//  FLEXColorPreviewSection.h
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXSingleRowSection.h"
#import "FLEXObjectInfoSection.h"

@interface FLEXColorPreviewSection : FLEXSingleRowSection <FLEXObjectInfoSection>

+ (instancetype)forObject:(UIColor *)color;

@end
