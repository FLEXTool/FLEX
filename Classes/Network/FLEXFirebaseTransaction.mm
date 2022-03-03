//
//  FLEXFirebaseTransaction.m
//  FLEX
//
//  Created by Tanner Bennett on 12/24/21.
//

#import "FLEXNetworkTransaction.h"
#import "FLEXUtility.h"
#import <dlfcn.h>
#include <string>

typedef std::string (*ReturnsString)(void *);

@implementation FLEXFirebaseSetDataInfo

+ (instancetype)data:(NSDictionary *)data merge:(NSNumber *)merge mergeFields:(NSArray *)mergeFields {
    NSParameterAssert(data);
    NSParameterAssert(merge || mergeFields);

    FLEXFirebaseSetDataInfo *info = [self new];
    info->_documentData = data;
    info->_merge = merge;
    info->_mergeFields = mergeFields;

    return info;
}

@end

static NSString *FLEXStringFromFIRRequestType(FLEXFIRRequestType type) {
    switch (type) {
        case FLEXFIRRequestTypeNotFirebase:
            return @"not firebase";
        case FLEXFIRRequestTypeFetchQuery:
            return @"query fetch";
        case FLEXFIRRequestTypeFetchDocument:
            return @"document fetch";
        case FLEXFIRRequestTypeSetData:
            return @"set data";
        case FLEXFIRRequestTypeUpdateData:
            return @"update data";
        case FLEXFIRRequestTypeAddDocument:
            return @"create";
        case FLEXFIRRequestTypeDeleteDocument:
            return @"delete";
    }

    return nil;
}

static FLEXFIRTransactionDirection FIRDirectionFromRequestType(FLEXFIRRequestType type) {
    switch (type) {
        case FLEXFIRRequestTypeNotFirebase:
            return FLEXFIRTransactionDirectionNone;
        case FLEXFIRRequestTypeFetchQuery:
        case FLEXFIRRequestTypeFetchDocument:
            return FLEXFIRTransactionDirectionPull;
        case FLEXFIRRequestTypeSetData:
        case FLEXFIRRequestTypeUpdateData:
        case FLEXFIRRequestTypeAddDocument:
        case FLEXFIRRequestTypeDeleteDocument:
            return FLEXFIRTransactionDirectionPush;
    }

    return FLEXFIRTransactionDirectionNone;
}

@interface FLEXFirebaseTransaction ()
@property (nonatomic) id extraData;
@property (nonatomic, readonly) NSString *queryDescription;
@end

@implementation FLEXFirebaseTransaction
@synthesize queryDescription = _queryDescription;

+ (instancetype)initiator:(id)initiator requestType:(FLEXFIRRequestType)type extraData:(id)data {
    FLEXFirebaseTransaction *fire = [FLEXFirebaseTransaction withStartTime:NSDate.date];
    fire->_direction = FIRDirectionFromRequestType(type);
    fire->_initiator = initiator;
    fire->_requestType = type;
    fire->_extraData = data;
    return fire;
}

+ (instancetype)queryFetch:(FIRQuery *)initiator {
    return [self initiator:initiator requestType:FLEXFIRRequestTypeFetchQuery extraData:nil];
}

+ (instancetype)documentFetch:(FIRDocumentReference *)initiator {
    return [self initiator:initiator requestType:FLEXFIRRequestTypeFetchDocument extraData:nil];
}

+ (instancetype)setData:(FIRDocumentReference *)initiator data:(NSDictionary *)data
                  merge:(NSNumber *)merge mergeFields:(NSArray *)mergeFields {

    FLEXFirebaseSetDataInfo *info = [FLEXFirebaseSetDataInfo data:data merge:merge mergeFields:mergeFields];
    return [self initiator:initiator requestType:FLEXFIRRequestTypeSetData extraData:info];
}

+ (instancetype)updateData:(FIRDocumentReference *)initiator data:(NSDictionary *)data {
    return [self initiator:initiator requestType:FLEXFIRRequestTypeUpdateData extraData:data];
}

+ (instancetype)addDocument:(FIRCollectionReference *)initiator document:(FIRDocumentReference *)doc {
    return [self initiator:initiator requestType:FLEXFIRRequestTypeAddDocument extraData:doc];
}

+ (instancetype)deleteDocument:(FIRDocumentReference *)initiator {
    return [self initiator:initiator requestType:FLEXFIRRequestTypeDeleteDocument extraData:nil];
}

- (NSString *)queryDescription {
    if (_queryDescription) {
        return _queryDescription;
    }

    // Grab C++ symbol to describe FIRQuery.query
    static ReturnsString firebase_firestore_core_query_tostring = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Is Firebase available?
        if (NSClassFromString(@"FIRDocumentReference")) {
            firebase_firestore_core_query_tostring = (ReturnsString)dlsym(
                RTLD_DEFAULT, "_ZNK8firebase9firestore4core5Query8ToStringEv"
            );
        }
    });

    if (!firebase_firestore_core_query_tostring) {
        return @"nil";
    }

    FIRQuery *query = self.initiator_query;
    if (!query) return nil;

    void *core_query = query.query;
    std::string description = firebase_firestore_core_query_tostring(core_query);

    // Query strings are like 'Query(canonical_id=...)' so I remove the leading part, and the ()
    NSString *prefix = @"Query(canonical_id=";
    NSString *desc = @(description.c_str());
    desc = [desc stringByReplacingOccurrencesOfString:prefix withString:@""];
    desc = [desc stringByReplacingCharactersInRange:NSMakeRange(desc.length-1, 1) withString:@""];

    _queryDescription = desc;
    return _queryDescription;
}

- (FIRDocumentReference *)initiator_doc {
    if ([_initiator isKindOfClass:cFIRDocumentReference]) {
        return _initiator;
    }

    return nil;
}
- (FIRQuery *)initiator_query {
    if ([_initiator isKindOfClass:cFIRQuery]) {
        return _initiator;
    }

    return nil;
}

- (FIRCollectionReference *)initiator_collection {
    if ([_initiator isKindOfClass:cFIRCollectionReference]) {
        return _initiator;
    }

    return nil;
}

- (FLEXFirebaseSetDataInfo *)setDataInfo {
    if (self.requestType == FLEXFIRRequestTypeSetData) {
        return self.extraData;
    }

    return nil;
}

- (NSDictionary *)updateData {
    if (self.requestType == FLEXFIRRequestTypeUpdateData) {
        return self.extraData;
    }

    return nil;
}

- (NSString *)path {
    switch (self.direction) {
        case FLEXFIRTransactionDirectionNone:
            return nil;
        case FLEXFIRTransactionDirectionPush:
        case FLEXFIRTransactionDirectionPull: {
            switch (self.requestType) {
                case FLEXFIRRequestTypeNotFirebase:
                    @throw NSInternalInconsistencyException;

                case FLEXFIRRequestTypeFetchQuery:
                case FLEXFIRRequestTypeAddDocument:
                    return self.initiator_collection.path ?: self.queryDescription;
                case FLEXFIRRequestTypeFetchDocument:
                case FLEXFIRRequestTypeSetData:
                case FLEXFIRRequestTypeUpdateData:
                case FLEXFIRRequestTypeDeleteDocument:
                    return self.initiator_doc.path;
            }
        }
    }

    return nil;
}

- (NSString *)primaryDescription {
    if (!_primaryDescription) {
        _primaryDescription = self.path.lastPathComponent;
    }

    return _primaryDescription;
}

- (NSString *)secondaryDescription {
    if (!_secondaryDescription) {
        _secondaryDescription = self.path.stringByDeletingLastPathComponent;
    }

    return _secondaryDescription;
}

- (NSString *)tertiaryDescription {
    if (!_tertiaryDescription) {
        NSMutableArray<NSString *> *detailComponents = [NSMutableArray new];

        NSString *timestamp = [self timestampStringFromRequestDate:self.startTime];
        if (timestamp.length > 0) {
            [detailComponents addObject:timestamp];
        }

        [detailComponents addObject:self.direction == FLEXFIRTransactionDirectionPush ?
            @"Push ↑" : @"Pull ↓"
        ];

        if (self.direction == FLEXFIRTransactionDirectionPush) {
            [detailComponents addObjectsFromArray:@[FLEXStringFromFIRRequestType(self.requestType)]];
        }

        if (self.state == FLEXNetworkTransactionStateFinished || self.state == FLEXNetworkTransactionStateFailed) {
            if (self.direction == FLEXFIRTransactionDirectionPull) {
                NSString *docCount = [NSString stringWithFormat:@"%@ document(s)", @(self.documents.count)];
                [detailComponents addObjectsFromArray:@[docCount]];
            }
        } else {
            // Unstarted, Awaiting Response, Receiving Data, etc.
            NSString *state = [self.class readableStringFromTransactionState:self.state];
            [detailComponents addObject:state];
        }

        _tertiaryDescription = [detailComponents componentsJoinedByString:@" ・ "];
    }

    return _tertiaryDescription;
}

- (NSString *)copyString {
    return self.path;
}

- (BOOL)matchesQuery:(NSString *)filterString {
    if ([self.path localizedCaseInsensitiveContainsString:filterString]) {
        return YES;
    }

    BOOL isPull = self.direction == FLEXFIRTransactionDirectionPull;
    BOOL isPush = self.direction == FLEXFIRTransactionDirectionPush;

    // Allow filtering for push or pull directly
    if (isPull && [filterString localizedCaseInsensitiveCompare:@"pull"] == NSOrderedSame) {
        return YES;
    }
    if (isPush && [filterString localizedCaseInsensitiveCompare:@"push"] == NSOrderedSame) {
        return YES;
    }

    return NO;
}

//- (NSString *)responseString {
//    if (!_responseString) {
//        _responseString = [NSString stringWithUTF8String:(char *)self.response.bytes];
//    }
//
//    return _responseString;
//}
//
//- (NSDictionary *)responseObject {
//    if (!_responseObject) {
//        _responseObject = [NSJSONSerialization JSONObjectWithData:self.response options:0 error:nil];
//    }
//
//    return _responseObject;
//}

@end
