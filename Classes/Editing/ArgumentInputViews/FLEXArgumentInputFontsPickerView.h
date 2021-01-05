//
//  FLEXArgumentInputFontsPickerView.h
//  FLEX
//
//  Created by 啟倫 陳 on 2014/7/27.
//  Copyright (c) 2014年 f. All rights reserved.
//

#import "FLEXArgumentInputTextView.h"

#if TARGET_OS_TV
@interface FLEXArgumentInputFontsPickerView : FLEXArgumentInputTextView 
#else
@interface FLEXArgumentInputFontsPickerView : FLEXArgumentInputTextView <UIPickerViewDataSource, UIPickerViewDelegate>
#endif
@end
