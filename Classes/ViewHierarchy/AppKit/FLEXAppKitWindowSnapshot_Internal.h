//
//  FLEXAppKitWindowSnapshot_Internal.h
//  FLEX
//
//  Internal readwrite surface for FLEXAppKitWalker. Not part of the public contract.
//
//  SPEC: domain.walker
//

#import "FLEXAppKitWindowSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitWindowSnapshot ()
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic) BOOL isKeyWindow;
@property (nonatomic) BOOL isMainWindow;
@property (nonatomic) BOOL isVisible;
@property (nonatomic) BOOL isPanel;
@property (nonatomic) CGRect frame;
@property (nonatomic, nullable) FLEXAppKitViewSnapshot *contentView;
@end

NS_ASSUME_NONNULL_END
