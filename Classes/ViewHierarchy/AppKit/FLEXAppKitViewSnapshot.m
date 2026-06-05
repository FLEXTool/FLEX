//
//  FLEXAppKitViewSnapshot.m
//  FLEX
//
//  SPEC: domain.walker
//

#import "FLEXAppKitViewSnapshot.h"

@implementation FLEXAppKitViewSnapshot

- (instancetype)initWithClassName:(NSString *)className
                            frame:(CGRect)frame
                     frameTopLeft:(CGRect)frameTopLeft
                        isFlipped:(BOOL)isFlipped
                           hidden:(BOOL)hidden
                            alpha:(double)alpha
                       identifier:(nullable NSString *)identifier
                             font:(nullable FLEXAppKitFont *)font
                         children:(NSArray<FLEXAppKitViewSnapshot *> *)children {
    self = [super init];
    if (self) {
        _className = [className copy];
        _frame = frame;
        _frameTopLeft = frameTopLeft;
        _isFlipped = isFlipped;
        _hidden = hidden;
        _alpha = alpha;
        _identifier = [identifier copy];
        _font = font;
        _children = [children copy];
    }
    return self;
}

@end
