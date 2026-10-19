//
//  FLEXSwiftUIInspector.h
//  FLEX
//
//  Created by Ethan Park on 10/13/26.
//  Copyright (c) 2026 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLEXSwiftUIViewKind) {
    /// A view the app defined, such as \c AView
    FLEXSwiftUIViewKindCustom,
    /// A view that lays out others, such as \c VStack or \c ScrollView
    FLEXSwiftUIViewKindContainer,
    /// A view that draws or responds, such as \c Text or \c Button
    FLEXSwiftUIViewKindComponent,
};

/// A node of the SwiftUI view tree. SwiftUI views have no UIView or CALayer of their
/// own, so this stands in for one when selecting or listing them.
@interface FLEXSwiftUIViewNode : NSObject
/// "AView", "VStack", "Text"
@property (nonatomic, readonly) NSString *name;
/// "FLEXample.AView"
@property (nonatomic, readonly) NSString *typeName;
@property (nonatomic, readonly) FLEXSwiftUIViewKind kind;
/// The nearest custom view this node is declared in, if any.
@property (nonatomic, readonly, nullable) NSString *enclosingName;
@property (nonatomic, readonly, weak, nullable) UIView *hostingView;
@property (nonatomic, readonly, weak, nullable) FLEXSwiftUIViewNode *parent;
@property (nonatomic, readonly) NSArray<FLEXSwiftUIViewNode *> *children;
/// \c CGRectNull when SwiftUI recorded no geometry for it.
@property (nonatomic, readonly) CGRect frameInHostingView;
@property (nonatomic, readonly) CGRect frameInWindow;
@end

/// Reads the view tree SwiftUI records for Xcode's view debugger, through private API
/// that is checked before every use. SwiftUI only records it when the
/// \c SWIFTUI_VIEW_DEBUG environment variable is set before its first view graph is
/// built, so FLEX sets it at load if \c flex_recordSwiftUIViews is on. That makes
/// SwiftUI keep a debug tree for every view graph in the process.
@interface FLEXSwiftUIInspector : NSObject

/// Whether SwiftUI records its view tree in this launch. Nothing is read otherwise.
@property (nonatomic, readonly, class) BOOL isRecording;

+ (BOOL)isHostingView:(UIView *)view;
/// The hosting view that owns \c layer, if \c layer was drawn by SwiftUI.
+ (nullable UIView *)hostingViewForLayer:(CALayer *)layer;

/// Discards what was read from every hosting view. Reading is cached until then, so
/// call this when the screen may have changed, such as before resolving a new tap.
+ (void)invalidate;

/// The top-level nodes of \c hostingView's SwiftUI view tree.
+ (NSArray<FLEXSwiftUIViewNode *> *)rootNodesInHostingView:(UIView *)hostingView;

/// The custom views in \c hostingView whose frame contains the point, outermost first.
/// The same view is the same object across calls, even after \c +invalidate.
+ (NSArray<FLEXSwiftUIViewNode *> *)customViewNodesInHostingView:(UIView *)hostingView
                                                  containingPoint:(CGPoint)pointInWindow;

/// The node of the SwiftUI view tree that drew \c layer, if any.
+ (nullable FLEXSwiftUIViewNode *)nodeForLayer:(CALayer *)layer;

/// The SwiftUI component that drew \c layer, such as \c "Text" or \c "Button", and the
/// innermost custom view containing it, such as \c "AView". Either may be nil.
+ (void)describeLayer:(CALayer *)layer
            component:(NSString *_Nullable *_Nonnull)component
                owner:(NSString *_Nullable *_Nonnull)owner;

@end

NS_ASSUME_NONNULL_END
