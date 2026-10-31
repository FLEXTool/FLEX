//
//  FLEXMacTableModel.h
//  FLEX (macOS)
//
//  Lightweight row/section models that drive FLEXMacTableViewController.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacRow : NSObject

+ (instancetype)title:(NSString *)title;
+ (instancetype)title:(NSString *)title subtitle:(nullable NSString *)subtitle;
/// A row which explores \c object when activated
+ (instancetype)title:(NSString *)title subtitle:(nullable NSString *)subtitle exploring:(nullable id)object;
/// A row which pushes the view controller returned by \c provider when activated
+ (instancetype)title:(NSString *)title subtitle:(nullable NSString *)subtitle
          pushing:(NSViewController *_Nullable(^)(void))provider;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *subtitle;
@property (nonatomic, nullable) NSImage *image;
@property (nonatomic, nullable) NSColor *titleColor;
/// Use a monospaced font for the title
@property (nonatomic) BOOL monospaced;
/// Max number of lines for the subtitle, defaults to 3
@property (nonatomic) NSInteger subtitleMaxLines;

/// Activating the row (double click or return) pushes this view controller
@property (nonatomic, copy, nullable) NSViewController *_Nullable(^viewControllerProvider)(void);
/// Activating the row runs this action; used if there is no view controller provider
@property (nonatomic, copy, nullable) void (^action)(NSViewController *host);
/// Extra items for the row's context menu
@property (nonatomic, copy, nullable) NSArray<NSMenuItem *> *(^contextMenuProvider)(NSViewController *host);
/// The string copied by Copy; defaults to "title: subtitle"
@property (nonatomic, copy, nullable) NSString *copyString;
/// Arbitrary associated object
@property (nonatomic, nullable) id representedObject;

@property (nonatomic, readonly) BOOL isActionable;
- (BOOL)matchesQuery:(NSString *)query;

@end

@interface FLEXMacSection : NSObject

+ (instancetype)title:(nullable NSString *)title rows:(NSArray<FLEXMacRow *> *)rows;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy) NSArray<FLEXMacRow *> *rows;
/// Sections which ignore search queries
@property (nonatomic) BOOL alwaysVisible;

- (FLEXMacSection *)filteredWithQuery:(NSString *)query;

@end

/// Makes an NSMenuItem which runs a block
NSMenuItem *FLEXMacMenuItem(NSString *title, void (^handler)(void));

NS_ASSUME_NONNULL_END
