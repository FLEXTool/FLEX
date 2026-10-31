//
//  FLEXMacToolbarPanel.h
//  FLEX (macOS)
//
//  The floating FLEX toolbar. The AppKit counterpart of FLEXExplorerToolbar.
//

#import <AppKit/AppKit.h>
#import "FLEXMacUtility.h"

NS_ASSUME_NONNULL_BEGIN

@class FLEXMacToolbarPanel;

@protocol FLEXMacToolbarPanelDelegate <NSObject>
- (void)toolbarDidSelectGlobals:(FLEXMacToolbarPanel *)toolbar;
- (void)toolbarDidSelectHierarchy:(FLEXMacToolbarPanel *)toolbar;
- (void)toolbarDidSelectSelect:(FLEXMacToolbarPanel *)toolbar;
- (void)toolbarDidSelectNetwork:(FLEXMacToolbarPanel *)toolbar;
- (void)toolbarDidSelectDetails:(FLEXMacToolbarPanel *)toolbar;
- (void)toolbarDidSelectClose:(FLEXMacToolbarPanel *)toolbar;
@end

@interface FLEXMacToolbarPanel : NSPanel <FLEXMacInternalWindow>

+ (instancetype)toolbar;

@property (nonatomic, weak, nullable) id<FLEXMacToolbarPanelDelegate> toolbarDelegate;

/// The currently selected view, shown below the buttons
@property (nonatomic, weak, nullable) NSView *selectedView;
/// Whether select mode is active; updates the select button state
@property (nonatomic) BOOL selecting;

@end

NS_ASSUME_NONNULL_END
