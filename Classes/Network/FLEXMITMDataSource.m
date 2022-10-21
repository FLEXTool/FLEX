//
//  FLEXMITMDataSource.m
//  FLEX
//
//  Created by Tanner Bennett on 8/22/21.
//

#import "FLEXMITMDataSource.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXUtility.h"

@interface FLEXMITMDataSource ()
@property (nonatomic, readonly) NSArray *(^dataProvider)(void);
@property (nonatomic) NSString *filterString;
@end

@implementation FLEXMITMDataSource

+ (instancetype)dataSourceWithProvider:(NSArray<id> *(^)(void))future {
    FLEXMITMDataSource *ds = [self new];
    ds->_dataProvider = future;
    [ds reloadData:nil];
    
    return ds;
}

- (BOOL)isFiltered {
    return self.filterString.length > 0;
}

- (void)reloadByteCounts {
    [self updateBytesReceived];
    [self updateFilteredBytesReceived];
}

- (void)reloadData:(void (^)(FLEXMITMDataSource *dataSource))completion {
    self.allTransactions = self.dataProvider();
    [self filter:self.filterString completion:completion];
}

- (void)filter:(NSString *)searchString completion:(void (^)(FLEXMITMDataSource *dataSource))completion {
    self.filterString = searchString;
    
    if (!searchString.length) {
        self.filteredTransactions = self.allTransactions;
        if (completion) completion(self);
    } else {
        NSArray<FLEXNetworkTransaction *> *allTransactions = self.allTransactions.copy;
        [self onBackgroundQueue:^NSArray *{
            return [allTransactions flex_filtered:^BOOL(FLEXNetworkTransaction *entry, NSUInteger idx) {
                return [entry matchesQuery:searchString];
            }];
        } thenOnMainQueue:^(NSArray *filteredNetworkTransactions) {
            if ([self.filterString isEqual:searchString]) {
                self.filteredTransactions = filteredNetworkTransactions;
                if (completion) completion(self);
            }
        }];
    }
}

- (void)setAllTransactions:(NSArray *)transactions {
    _allTransactions = transactions.copy;
    [self updateBytesReceived];
}

/// This is really just a semantic setter for \c _transactions
- (void)setFilteredTransactions:(NSArray *)filteredTransactions {
    _transactions = filteredTransactions.copy;
    [self updateFilteredBytesReceived];
}

- (void)setTransactions:(NSArray *)transactions {
    self.filteredTransactions = transactions;
}

- (void)updateBytesReceived {
    NSInteger bytesReceived = 0;
    for (FLEXNetworkTransaction *transaction in self.transactions) {
        bytesReceived += transaction.receivedDataLength;
    }
    
    self.bytesReceived = bytesReceived;
}

- (void)updateFilteredBytesReceived {
    NSInteger filteredBytesReceived = 0;
    for (FLEXNetworkTransaction *transaction in self.transactions) {
        filteredBytesReceived += transaction.receivedDataLength;
    }
    
    self.bytesReceived = filteredBytesReceived;
}

- (void)onBackgroundQueue:(NSArray *(^)(void))backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *items = backgroundBlock();
        dispatch_async(dispatch_get_main_queue(), ^{
            mainBlock(items);
        });
    });
}

@end
