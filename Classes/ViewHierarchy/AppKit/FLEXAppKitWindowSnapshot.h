//
//  FLEXAppKitWindowSnapshot.h
//  FLEX
//
//  A top-level NSWindow root produced by FLEXAppKitWalker. Each on-screen window
//  is a tree root; its contentView subtree hangs below.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class FLEXAppKitViewSnapshot;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitWindowSnapshot : NSObject

/// The real runtime NSWindow subclass via object_getClass.
@property (nonatomic, readonly, copy) NSString *className;
@property (nonatomic, readonly, copy, nullable) NSString *title;
@property (nonatomic, readonly, copy, nullable) NSString *identifier;
@property (nonatomic, readonly) BOOL isKeyWindow;
@property (nonatomic, readonly) BOOL isMainWindow;
@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly) BOOL isPanel;
/// Window frame in screen coordinates (bottom-left origin).
@property (nonatomic, readonly) CGRect frame;
/// Snapshot of the window's contentView subtree; nil if there is no contentView.
@property (nonatomic, readonly, nullable) FLEXAppKitViewSnapshot *contentView;

/// Transient/child windows nested under this one — attached sheets, child windows
/// (NSPopover content, panels). Only top-level windows are roots; these are not.
@property (nonatomic, readonly, copy) NSArray<FLEXAppKitWindowSnapshot *> *childWindows;

@end

NS_ASSUME_NONNULL_END
