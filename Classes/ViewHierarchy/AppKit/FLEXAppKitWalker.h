//
//  FLEXAppKitWalker.h
//  FLEX
//
//  The macOS view-tree walker: NSApp → NSWindow → NSView, capturing the per-node
//  facts in FLEXAppKitViewSnapshot. The macOS analog of FHSView.
//
//  Threading: every method must be called on the target's main thread. Main-thread
//  marshaling, the socket, and the node-id registry are the headless server's job,
//  not the walker's (see domain.walker).
//
//  SPEC: domain.walker
//

#import <Foundation/Foundation.h>

@class FLEXAppKitViewSnapshot;
@class FLEXAppKitWindowSnapshot;
@class NSView;
@class NSWindow;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitWalker : NSObject

/// Snapshot every NSApp window as a tree root (key/main/panel identified), each
/// with its contentView subtree. The rooted entry point for a full app walk.
+ (NSArray<FLEXAppKitWindowSnapshot *> *)snapshotApplicationWindows;

/// As above, bounded to `maxDepth` levels below each window's contentView. Nodes
/// at the bound report `truncated` + `childCount` with `children` omitted.
+ (NSArray<FLEXAppKitWindowSnapshot *> *)snapshotApplicationWindowsWithMaxDepth:(NSInteger)maxDepth;

/// Recursively snapshot `view` and its subtree (unbounded depth). Frames are
/// normalized against `window`'s full frame (titlebar included); pass the view's
/// window. When `window` is nil, `frameTopLeft` falls back to the raw frame.
+ (FLEXAppKitViewSnapshot *)snapshotForView:(NSView *)view inWindow:(nullable NSWindow *)window;

/// As above, bounded to `maxDepth` levels below `view`. A node at the bound with
/// subviews reports `truncated == YES` + `childCount` and omits `children`.
+ (FLEXAppKitViewSnapshot *)snapshotForView:(NSView *)view
                                   inWindow:(nullable NSWindow *)window
                                   maxDepth:(NSInteger)maxDepth;

/// The deepest view at `point` (window base coordinates, bottom-left origin),
/// snapshotted as a single node with its children omitted. The macOS substitute
/// for touch hit-testing. Returns nil if nothing is hit.
+ (nullable FLEXAppKitViewSnapshot *)snapshotForHitTestAtPoint:(CGPoint)point
                                                     inWindow:(NSWindow *)window;

@end

NS_ASSUME_NONNULL_END
