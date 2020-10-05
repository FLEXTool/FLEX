//
//  FLEXShortcutsFactory+Defaults.h
//  FLEX
//
//  Created by Tanner Bennett on 8/29/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXShortcutsSection.h"

@interface FLEXShortcutsFactory (UIApplication) @end

@interface FLEXShortcutsFactory (Views) @end

@interface FLEXShortcutsFactory (ViewControllers) @end

@interface FLEXShortcutsFactory (UIImage) @end

@interface FLEXShortcutsFactory (NSBundle) @end

@interface FLEXShortcutsFactory (Classes) @end

@interface FLEXShortcutsFactory (Activities) @end

@interface FLEXShortcutsFactory (Blocks) @end

@interface FLEXShortcutsFactory (Foundation) @end

@interface FLEXShortcutsFactory (Public)
#ifdef DISABLE_FLEX_RUNTIME_LOAD
+ (void)setupFLEXRuntimeAndShortcuts;
#endif
@end
