//
//  FHSView.h
//  FLEX
//
//  Created by Tanner Bennett on 1/6/20.
//

#import <UIKit/UIKit.h>

@interface FHSView : NSObject {
    @private
    BOOL _inScrollView;
}

+ (instancetype)forView:(UIView *)view isInScrollView:(BOOL)inScrollView;

/// Intentionally not weak
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) NSString *identifier;

@property (nonatomic, readonly) NSString *title;
/// Whether or not this view item should be visually distinguished
@property (nonatomic, readwrite) BOOL important;

@property (nonatomic, readonly) CGRect frame;
@property (nonatomic, readonly) BOOL hidden;
@property (nonatomic, readonly) UIImage *snapshotImage;

@property (nonatomic, readonly) NSArray<FHSView *> *children;
@property (nonatomic, readonly) NSString *summary;

/// @return importantAttr if .important, otherwise normalAttr
//- (id)ifImportant:(id)importantAttr ifNormal:(id)normalAttr;

@end
