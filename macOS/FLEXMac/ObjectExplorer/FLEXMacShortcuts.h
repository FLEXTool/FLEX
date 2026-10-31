//
//  FLEXMacShortcuts.h
//  FLEX (macOS)
//
//  Type-specific rows shown at the top of the object explorer,
//  such as a view's subviews or a collection's elements.
//  The AppKit counterpart of FLEXShortcutsFactory and FLEX's
//  collection content sections.
//

#import "FLEXMacTableModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacShortcuts : NSObject

+ (NSArray<FLEXMacSection *> *)sectionsForObject:(id)object;

@end

NS_ASSUME_NONNULL_END
