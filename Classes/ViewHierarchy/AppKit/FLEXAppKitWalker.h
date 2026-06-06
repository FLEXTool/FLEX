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

/// Recursively snapshot `view` and its subtree. Frames are normalized against
/// `window`'s full frame (titlebar included); pass the view's window. When `window`
/// is nil, `frameTopLeft` falls back to the raw frame.
+ (FLEXAppKitViewSnapshot *)snapshotForView:(NSView *)view inWindow:(nullable NSWindow *)window;

@end

NS_ASSUME_NONNULL_END
