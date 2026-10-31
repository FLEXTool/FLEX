//
//  FLEXManager+Private.h
//  FLEX (macOS)
//

#import "FLEXManager.h"
#import "FLEXMacTableModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager (Private)

/// Rows for entries registered with -registerGlobalEntryWithName:...
@property (nonatomic, readonly) NSArray<FLEXMacRow *> *userGlobalEntryRows;

/// Called when a view is selected from outside the toolbar, e.g. by the hierarchy
- (void)setSelectedView:(nullable NSView *)view;

@end

NS_ASSUME_NONNULL_END
