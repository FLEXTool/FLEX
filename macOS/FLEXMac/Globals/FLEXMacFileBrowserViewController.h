//
//  FLEXMacFileBrowserViewController.h
//  FLEX (macOS)
//
//  Browse the file system, preview files and open SQLite databases.
//  The AppKit counterpart of FLEXFileBrowserController.
//

#import "FLEXMacTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacFileBrowserViewController : FLEXMacTableViewController

+ (instancetype)browserForPath:(NSString *)path;
/// The best viewer for the file at \c path, if any
+ (nullable NSViewController *)viewerForFileAtPath:(NSString *)path;

@end

/// Lists tables of a SQLite database, and shows rows of a table
@interface FLEXMacDatabaseViewController : FLEXMacTableViewController
+ (nullable instancetype)databaseAtPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
