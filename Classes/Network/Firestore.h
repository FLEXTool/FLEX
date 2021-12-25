//
//  Firestore.h
//  Pods
//
//  Created by Tanner Bennett on 10/13/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Forward Declarations

@class FIRQuery;
@class FIRQuerySnapshot;
@class FIRDocumentReference;
@class FIRDocumentSnapshot;
@class FIRQueryDocumentSnapshot;
@class FIRCollectionReference;
@class FIRFirestore;
@protocol FIRListenerRegistration;

#define cFIRQuery objc_getClass("FIRQuery")
#define cFIRCollectionReference objc_getClass("FIRCollectionReference")
#define cFIRDocumentReference objc_getClass("FIRDocumentReference")

typedef void (^FIRDocumentSnapshotBlock)(FIRDocumentSnapshot *_Nullable snapshot,
                                         NSError *_Nullable error);
typedef void (^FIRQuerySnapshotBlock)(FIRQuerySnapshot *_Nullable snapshot,
                                      NSError *_Nullable error);

typedef NS_ENUM(NSUInteger, FIRFirestoreSource) {
    FIRFirestoreSourceDefault,
    FIRFirestoreSourceServer,
    FIRFirestoreSourceCache
} NS_SWIFT_NAME(FirestoreSource);

#pragma mark - Query
@interface FIRQuery : NSObject

- (id)init __attribute__((unavailable()));

@property(nonatomic, readonly) FIRFirestore *firestore;
@property(nonatomic, readonly) void *query;

- (void)getDocumentsWithCompletion:(FIRQuerySnapshotBlock)completion
    NS_SWIFT_NAME(getDocuments(completion:));
- (void)getDocumentsWithSource:(FIRFirestoreSource)source
                    completion:(FIRQuerySnapshotBlock)completion
    NS_SWIFT_NAME(getDocuments(source:completion:));

@end


typedef void (^FIRDocumentSnapshotBlock)(FIRDocumentSnapshot *_Nullable snapshot,
                                         NSError *_Nullable error);

#pragma mark - DocumentReference
NS_SWIFT_NAME(DocumentReference)
@interface FIRDocumentReference : NSObject

- (instancetype)init __attribute__((unavailable));

@property(nonatomic, readonly) NSString *documentID;
@property(nonatomic, readonly) FIRCollectionReference *parent;
@property(nonatomic, readonly) FIRFirestore *firestore;
@property(nonatomic, readonly) NSString *path;

- (FIRCollectionReference *)collectionWithPath:(NSString *)collectionPath
    NS_SWIFT_NAME(collection(_:));

#pragma mark Writing Data

- (void)setData:(NSDictionary<NSString *, id> *)documentData;
- (void)setData:(NSDictionary<NSString *, id> *)documentData merge:(BOOL)merge;
- (void)setData:(NSDictionary<NSString *, id> *)documentData mergeFields:(NSArray<id> *)mergeFields;
- (void)setData:(NSDictionary<NSString *, id> *)documentData
     completion:(nullable void (^)(NSError *_Nullable error))completion;
- (void)setData:(NSDictionary<NSString *, id> *)documentData
          merge:(BOOL)merge
     completion:(nullable void (^)(NSError *_Nullable error))completion;
- (void)setData:(NSDictionary<NSString *, id> *)documentData
    mergeFields:(NSArray<id> *)mergeFields
     completion:(nullable void (^)(NSError *_Nullable error))completion;

- (void)updateData:(NSDictionary<id, id> *)fields;
- (void)updateData:(NSDictionary<id, id> *)fields
        completion:(nullable void (^)(NSError *_Nullable error))completion;

- (void)deleteDocument NS_SWIFT_NAME(delete());
- (void)deleteDocumentWithCompletion:(nullable void (^)(NSError *_Nullable error))completion
    NS_SWIFT_NAME(delete(completion:));

#pragma mark Retrieving Data

- (void)getDocumentWithCompletion:(FIRDocumentSnapshotBlock)completion
    NS_SWIFT_NAME(getDocument(completion:));
- (void)getDocumentWithSource:(FIRFirestoreSource)source
                   completion:(FIRDocumentSnapshotBlock)completion
    NS_SWIFT_NAME(getDocument(source:completion:));

- (id<FIRListenerRegistration>)addSnapshotListener:(FIRDocumentSnapshotBlock)listener
    NS_SWIFT_NAME(addSnapshotListener(_:));
- (id<FIRListenerRegistration>)addSnapshotListenerWithIncludeMetadataChanges:(BOOL)includeMetadataChanges
                                                                    listener:(FIRDocumentSnapshotBlock)listener
    NS_SWIFT_NAME(addSnapshotListener(includeMetadataChanges:listener:));

@end


#pragma mark - CollectionReference
NS_SWIFT_NAME(CollectionReference)
@interface FIRCollectionReference : FIRQuery

- (id)init __attribute__((unavailable()));

@property(nonatomic, readonly) NSString *collectionID;
@property(nonatomic, nullable, readonly) FIRDocumentReference *parent;
@property(nonatomic, readonly) NSString *path;

- (FIRDocumentReference *)documentWithAutoID NS_SWIFT_NAME(document());
- (FIRDocumentReference *)documentWithPath:(NSString *)documentPath NS_SWIFT_NAME(document(_:));
- (FIRDocumentReference *)addDocumentWithData:(NSDictionary<NSString *, id> *)data
    NS_SWIFT_NAME(addDocument(data:));
- (FIRDocumentReference *)addDocumentWithData:(NSDictionary<NSString *, id> *)data
                                   completion:(nullable void (^)(NSError *_Nullable error))completion
    NS_SWIFT_NAME(addDocument(data:completion:));
@end

#pragma mark - QuerySnapshot
NS_SWIFT_NAME(QuerySnapshot)
@interface FIRQuerySnapshot : NSObject

- (id)init __attribute__((unavailable()));

@property(nonatomic, readonly) FIRQuery *query;
@property(nonatomic, readonly, getter=isEmpty) BOOL empty;
@property(nonatomic, readonly) NSInteger count;
@property(nonatomic, readonly) NSArray<FIRQueryDocumentSnapshot *> *documents;

@end

#pragma mark - DocumentSnapshot
NS_SWIFT_NAME(DocumentSnapshot)
@interface FIRDocumentSnapshot : NSObject

- (instancetype)init __attribute__((unavailable()));

@property(nonatomic, readonly) BOOL exists;
@property(nonatomic, readonly) FIRDocumentReference *reference;
@property(nonatomic, copy, readonly) NSString *documentID;

@property(nonatomic, readonly, nullable) NSDictionary<NSString *, id> *data;

- (nullable id)valueForField:(id)field NS_SWIFT_NAME(get(_:));
- (nullable id)objectForKeyedSubscript:(id)key;

@end

#pragma mark - QueryDocumentSnapshot
NS_SWIFT_NAME(QueryDocumentSnapshot)
@interface FIRQueryDocumentSnapshot : FIRDocumentSnapshot

- (instancetype)init __attribute__((unavailable()));

@property(nonatomic, readonly) NSDictionary<NSString *, id> *data;

@end

NS_ASSUME_NONNULL_END


#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
