//
//  FLEXMacObjectListViewController.h
//  FLEX (macOS)
//
//  A list of objects, such as live instances of a class.
//  The AppKit counterpart of FLEXObjectListViewController.
//

#import "FLEXMacTableViewController.h"
@class FLEXObjectRef;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacObjectListViewController : FLEXMacTableViewController

+ (instancetype)instancesOfClassWithName:(NSString *)className;
+ (instancetype)subclassesOfClassWithName:(NSString *)className;
+ (instancetype)objectsWithReferencesToObject:(id)object;

+ (instancetype)listWithTitle:(NSString *)title references:(NSArray<FLEXObjectRef *> *)references;
+ (instancetype)listWithTitle:(NSString *)title objects:(NSArray *)objects;

@end

NS_ASSUME_NONNULL_END
