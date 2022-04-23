//
//  FLEXMITMDataSource.h
//  FLEX
//
//  Created by Tanner Bennett on 8/22/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMITMDataSource<__covariant TransactionType> : NSObject

+ (instancetype)dataSourceWithProvider:(NSArray<TransactionType> *(^)(void))future;

/// Whether or not the data in \c transactions and \c bytesReceived are actually filtered yet or not
@property (nonatomic, readonly) BOOL isFiltered;

/// The content of this array is filtered to match the input of \c filter:completion:
@property (nonatomic, readonly) NSArray<TransactionType> *transactions;
@property (nonatomic, readonly) NSArray<TransactionType> *allTransactions;

/// The content of this array is filtered to match the input of \c filter:completion:
@property (nonatomic) NSInteger bytesReceived;
@property (nonatomic) NSInteger totalBytesReceived;

- (void)reloadByteCounts;
- (void)reloadData:(void (^_Nullable)(FLEXMITMDataSource *dataSource))completion;
- (void)filter:(NSString *)searchString completion:(void(^_Nullable)(FLEXMITMDataSource *dataSource))completion;

@end

NS_ASSUME_NONNULL_END
