//
//  FLEXNetworkTransaction.m
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXNetworkTransaction.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"
#import "NSDateFormatter+FLEX.h"

@implementation FLEXNetworkTransaction

+ (NSString *)readableStringFromTransactionState:(FLEXNetworkTransactionState)state {
    NSString *readableString = nil;
    switch (state) {
        case FLEXNetworkTransactionStateUnstarted:
            readableString = @"Unstarted";
            break;
            
        case FLEXNetworkTransactionStateAwaitingResponse:
            readableString = @"Awaiting Response";
            break;
            
        case FLEXNetworkTransactionStateReceivingData:
            readableString = @"Receiving Data";
            break;
            
        case FLEXNetworkTransactionStateFinished:
            readableString = @"Finished";
            break;
            
        case FLEXNetworkTransactionStateFailed:
            readableString = @"Failed";
            break;
    }
    return readableString;
}

+ (instancetype)withStartTime:(NSDate *)startTime {
    FLEXNetworkTransaction *transaction = [self new];
    transaction->_startTime = startTime;
    return transaction;
}

- (NSString *)timestampStringFromRequestDate:(NSDate *)date {
    return [NSDateFormatter flex_stringFrom:date format:FLEXDateFormatPreciseClock];
}

- (void)setState:(FLEXNetworkTransactionState)transactionState {
    _state = transactionState;
    // Reset bottom description
    _tertiaryDescription = nil;
}

- (BOOL)displayAsError {
    return _error != nil;
}

- (NSString *)copyString {
    return nil;
}

- (BOOL)matchesQuery:(NSString *)filterString {
    return NO;
}

@end


@interface FLEXURLTransaction ()

@end

@implementation FLEXURLTransaction

+ (instancetype)withRequest:(NSURLRequest *)request startTime:(NSDate *)startTime {
    FLEXURLTransaction *transaction = [self withStartTime:startTime];
    transaction->_request = request;
    return transaction;
}

- (NSString *)primaryDescription {
    if (!_primaryDescription) {
        NSString *name = self.request.URL.lastPathComponent;
        if (!name.length) {
            name = @"/";
        }
        
        if (_request.URL.query) {
            name = [name stringByAppendingFormat:@"?%@", self.request.URL.query];
        }
        
        _primaryDescription = name;
    }
    
    return _primaryDescription;
}

- (NSString *)secondaryDescription {
    if (!_secondaryDescription) {
        NSMutableArray<NSString *> *mutablePathComponents = self.request.URL.pathComponents.mutableCopy;
        if (mutablePathComponents.count > 0) {
            [mutablePathComponents removeLastObject];
        }
        
        NSString *path = self.request.URL.host;
        for (NSString *pathComponent in mutablePathComponents) {
            path = [path stringByAppendingPathComponent:pathComponent];
        }
        
        _secondaryDescription = path;
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
        
        // Omit method for GET (assumed as default)
        NSString *httpMethod = self.request.HTTPMethod;
        if (httpMethod.length > 0) {
            [detailComponents addObject:httpMethod];
        }
        
        if (self.state == FLEXNetworkTransactionStateFinished || self.state == FLEXNetworkTransactionStateFailed) {
            [detailComponents addObjectsFromArray:self.details];
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
    return self.request.URL.absoluteString;
}

- (BOOL)matchesQuery:(NSString *)filterString {
    return [self.request.URL.absoluteString localizedCaseInsensitiveContainsString:filterString];
}

@end

@interface FLEXHTTPTransaction ()
@property (nonatomic, readwrite) NSData *cachedRequestBody;
@end

@implementation FLEXHTTPTransaction

+ (instancetype)request:(NSURLRequest *)request identifier:(NSString *)requestID {
    FLEXHTTPTransaction *httpt = [self withRequest:request startTime:NSDate.date];
    httpt->_requestID = requestID;
    return httpt;
}

- (NSString *)description {
    NSString *description = [super description];
    
    description = [description stringByAppendingFormat:@" id = %@;", self.requestID];
    description = [description stringByAppendingFormat:@" url = %@;", self.request.URL];
    description = [description stringByAppendingFormat:@" duration = %f;", self.duration];
    description = [description stringByAppendingFormat:@" receivedDataLength = %lld", self.receivedDataLength];
    
    return description;
}

- (NSData *)cachedRequestBody {
    if (!_cachedRequestBody) {
        if (self.request.HTTPBody != nil) {
            _cachedRequestBody = self.request.HTTPBody;
        } else if ([self.request.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
            NSInputStream *bodyStream = [self.request.HTTPBodyStream copy];
            const NSUInteger bufferSize = 1024;
            uint8_t buffer[bufferSize];
            NSMutableData *data = [NSMutableData new];
            [bodyStream open];
            NSInteger readBytes = 0;
            do {
                readBytes = [bodyStream read:buffer maxLength:bufferSize];
                [data appendBytes:buffer length:readBytes];
            } while (readBytes > 0);
            [bodyStream close];
            _cachedRequestBody = data;
        }
    }
    return _cachedRequestBody;
}

- (NSArray *)detailString {
    NSMutableArray<NSString *> *detailComponents = [NSMutableArray new];
    
    NSString *statusCodeString = [FLEXUtility statusCodeStringFromURLResponse:self.response];
    if (statusCodeString.length > 0) {
        [detailComponents addObject:statusCodeString];
    }

    if (self.receivedDataLength > 0) {
        NSString *responseSize = [NSByteCountFormatter
            stringFromByteCount:self.receivedDataLength
            countStyle:NSByteCountFormatterCountStyleBinary
        ];
        [detailComponents addObject:responseSize];
    }

    NSString *totalDuration = [FLEXUtility stringFromRequestDuration:self.duration];
    NSString *latency = [FLEXUtility stringFromRequestDuration:self.latency];
    NSString *duration = [NSString stringWithFormat:@"%@ (%@)", totalDuration, latency];
    [detailComponents addObject:duration];
    
    return detailComponents;
}

- (BOOL)displayAsError {
    return [FLEXUtility isErrorStatusCodeFromURLResponse:self.response] || super.displayAsError;
}

@end


@implementation FLEXWebsocketTransaction

+ (instancetype)withMessage:(NSURLSessionWebSocketMessage *)message
                       task:(NSURLSessionWebSocketTask *)task
                  direction:(FLEXWebsocketMessageDirection)direction
                  startTime:(NSDate *)started {
    FLEXWebsocketTransaction *wst = [self withRequest:task.originalRequest startTime:started];
    wst->_message = message;
    wst->_direction = direction;
    
    // Populate receivedDataLength
    if (direction == FLEXWebsocketIncoming) {
        wst.receivedDataLength = wst.dataLength;
        wst.state = FLEXNetworkTransactionStateFinished;
    }
    
    // Populate thumbnail image
    if (message.type == NSURLSessionWebSocketMessageTypeData) {
        wst.thumbnail = FLEXResources.binaryIcon;
    } else {
        wst.thumbnail = FLEXResources.textIcon;
    }
    
    return wst;
}

+ (instancetype)withMessage:(NSURLSessionWebSocketMessage *)message
                       task:(NSURLSessionWebSocketTask *)task
                  direction:(FLEXWebsocketMessageDirection)direction {
    return [self withMessage:message task:task direction:direction startTime:NSDate.date];
}

- (NSArray<NSString *> *)details API_AVAILABLE(ios(13.0)) {
    return @[
        self.direction == FLEXWebsocketOutgoing ? @"SENT →" : @"→ RECEIVED",
        [NSByteCountFormatter
            stringFromByteCount:self.dataLength
            countStyle:NSByteCountFormatterCountStyleBinary
        ]
    ];
}

- (int64_t)dataLength {
    if (self.message) {
        if (self.message.type == NSURLSessionWebSocketMessageTypeString) {
            return self.message.string.length;
        }
        
        return self.message.data.length;
    }
    
    return 0;
}

@end
