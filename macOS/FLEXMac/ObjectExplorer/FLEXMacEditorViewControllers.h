//
//  FLEXMacEditorViewControllers.h
//  FLEX (macOS)
//
//  Editing properties and ivars, and calling methods.
//  AppKit counterparts of FLEXFieldEditorViewController
//  and FLEXMethodCallingViewController.
//

#import <AppKit/AppKit.h>
#import "FLEXProperty.h"
#import "FLEXIvar.h"
#import "FLEXMethod.h"

#import "FLEXMacNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

/// A scrolling vertical form
@interface FLEXMacFormViewController : NSViewController <FLEXMacNavigationItems>
@property (nonatomic) NSStackView *stack;
@property (nonatomic) NSTextField *statusLabel;
@property (nonatomic, nullable) NSView *initialFocus;
/// Subclasses override to add their contents to \c stack
- (void)buildForm;
- (NSTextField *)addInfo:(NSString *)title value:(nullable NSString *)value;
- (void)addFullWidth:(NSView *)view;
- (void)setStatus:(nullable NSString *)status isError:(BOOL)isError;
@end

@interface FLEXMacFieldEditorViewController : FLEXMacFormViewController

/// @return nil if the property cannot be edited on this target
+ (nullable instancetype)editorForProperty:(FLEXProperty *)property
                                    target:(id)target
                                    commit:(nullable void(^)(void))commitHandler;
/// @return nil if the ivar cannot be edited on this target
+ (nullable instancetype)editorForIvar:(FLEXIvar *)ivar
                                target:(id)target
                                commit:(nullable void(^)(void))commitHandler;

+ (BOOL)canEditProperty:(FLEXProperty *)property target:(nullable id)target;
+ (BOOL)canEditIvar:(FLEXIvar *)ivar target:(nullable id)target;

@end

@interface FLEXMacMethodCallViewController : FLEXMacFormViewController

+ (instancetype)callerForMethod:(FLEXMethod *)method target:(id)target;
+ (BOOL)canCallMethod:(FLEXMethod *)method;

@end

NS_ASSUME_NONNULL_END
