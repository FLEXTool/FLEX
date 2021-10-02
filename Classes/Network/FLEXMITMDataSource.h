//
//  FLEXMITMDataSource.h
//  FLEX
//
//  Created by Tanner Bennett on 8/22/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMITMDataSource<__covariant TransactionType> : NSObject

+ (instancetype)dataSourceWithProvider:(NSArray<TransactionType> *(^)())future;

@property (nonatomic, readonly) NSArray<TransactionType> *transactions;
@property (nonatomic, readonly) NSArray<TransactionType> *allTransactions;
/// Equal to \c allTransactions if not filtered
@property (nonatomic, readonly) NSArray<TransactionType> *filteredTransactions;

/// Use this instead of either of the other two as it updates based on whether we have a filter or not
@property (nonatomic) NSInteger bytesReceived;
@property (nonatomic) NSInteger totalBytesReceived;
/// Equal to \c totalBytesReceived if not filtered
@property (nonatomic) NSInteger filteredBytesReceived;

- (void)reloadByteCounts;
- (void)reloadData:(void (^_Nullable)(FLEXMITMDataSource *dataSource))completion;
- (void)filter:(NSString *)searchString completion:(void(^_Nullable)(FLEXMITMDataSource *dataSource))completion;


@end

NS_ASSUME_NONNULL_END
