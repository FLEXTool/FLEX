//
//  FLEXNetworkExporter.h
//  FLEX
//
//  Created by Enes OZTURK on 4/1/26.
//

#import <Foundation/Foundation.h>

@class FLEXHTTPTransaction;

NS_ASSUME_NONNULL_BEGIN

/// Export formats for network requests
typedef NS_ENUM(NSUInteger, FLEXNetworkExportFormat) {
    FLEXNetworkExportFormatRequestOnly,
    FLEXNetworkExportFormatResponseOnly,
    FLEXNetworkExportFormatRaw,
    FLEXNetworkExportFormatHAR,
    FLEXNetworkExportFormatPostman,
    FLEXNetworkExportFormatSwagger,
    FLEXNetworkExportFormatCurlZip,
};

/// A helper class for exporting network transactions in various formats.
@interface FLEXNetworkExporter : NSObject

#pragma mark - Single Transaction Export

/// Export a single transaction as request-only text
+ (NSString *)requestStringForTransaction:(FLEXHTTPTransaction *)transaction;

/// Export a single transaction as response-only text
+ (NSString *)responseStringForTransaction:(FLEXHTTPTransaction *)transaction;

/// Export a single transaction as raw text (request + response)
+ (NSString *)rawStringForTransaction:(FLEXHTTPTransaction *)transaction;

/// Export a single transaction as HAR entry dictionary
+ (NSDictionary *)harEntryForTransaction:(FLEXHTTPTransaction *)transaction;

#pragma mark - Multiple Transactions Export

/// Export multiple transactions as raw text
+ (NSString *)rawStringForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions;

/// Export multiple transactions as HAR file dictionary
+ (NSDictionary *)harFileForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions;

/// Export multiple transactions as HAR JSON string
+ (NSString *)harJSONStringForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions;

/// Export multiple transactions as Postman Collection v2.1 JSON string
+ (NSString *)postmanCollectionForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions;

/// Export multiple transactions as Swagger/OpenAPI 3.0 JSON string
+ (NSString *)swaggerSpecForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions;

/// Export multiple transactions as curl commands in a ZIP file, returns file URL
+ (nullable NSURL *)curlZipForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions;

#pragma mark - Filtering

/// Filter transactions based on user settings (images, analytics, Firebase)
+ (NSArray<FLEXHTTPTransaction *> *)filterTransactionsForExport:(NSArray<FLEXHTTPTransaction *> *)transactions;

#pragma mark - File Operations

/// Save content to a temporary file and return the file URL
+ (nullable NSURL *)saveToTemporaryFile:(NSString *)content
                           withFilename:(NSString *)filename;

/// Get a suggested filename for the export
+ (NSString *)suggestedFilenameForFormat:(FLEXNetworkExportFormat)format
                              isMultiple:(BOOL)isMultiple;

@end

NS_ASSUME_NONNULL_END
