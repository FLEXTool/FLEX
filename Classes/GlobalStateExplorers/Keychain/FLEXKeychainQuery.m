//
//  FLEXKeychainQuery.m
//  FLEXKeychain
//
//  Created by Caleb Davenport on 3/19/13.
//  Copyright (c) 2013-2014 Sam Soffes. All rights reserved.
//

#import "FLEXKeychainQuery.h"
#import "FLEXKeychain.h"

@implementation FLEXKeychainQuery

#pragma mark - Public

- (BOOL)save:(NSError *__autoreleasing *)error {
    OSStatus status = FLEXKeychainErrorBadArguments;
    if (!self.service || !self.account || !self.passwordData) {
        if (error) {
            *error = [self errorWithCode:status];
        }
        return NO;
    }
    
    NSMutableDictionary *query = nil;
    NSMutableDictionary * searchQuery = [self query];
    status = SecItemCopyMatching((__bridge CFDictionaryRef)searchQuery, nil);
    if (status == errSecSuccess) {//item already exists, update it!
        query = [[NSMutableDictionary alloc]init];
        query[(__bridge id)kSecValueData] = self.passwordData;
        #if __IPHONE_4_0 && TARGET_OS_IPHONE
        CFTypeRef accessibilityType = FLEXKeychain.accessibilityType;
        if (accessibilityType) {
            query[(__bridge id)kSecAttrAccessible] = (__bridge id)accessibilityType;
        }
        #endif
        status = SecItemUpdate((__bridge CFDictionaryRef)(searchQuery), (__bridge CFDictionaryRef)(query));
    }
    else if (status == errSecItemNotFound){//item not found, create it!
        query = [self query];
        if (self.label) {
            query[(__bridge id)kSecAttrLabel] = self.label;
        }
        query[(__bridge id)kSecValueData] = self.passwordData;
        #if __IPHONE_4_0 && TARGET_OS_IPHONE
        CFTypeRef accessibilityType = FLEXKeychain.accessibilityType;
        if (accessibilityType) {
            query[(__bridge id)kSecAttrAccessible] = (__bridge id)accessibilityType;
        }
        #endif
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    
    if (status != errSecSuccess && error != NULL) {
        *error = [self errorWithCode:status];
    }
    
    return (status == errSecSuccess);
}


- (BOOL)deleteItem:(NSError *__autoreleasing *)error {
    OSStatus status = FLEXKeychainErrorBadArguments;
    if (!self.service || !self.account) {
        if (error) {
            *error = [self errorWithCode:status];
        }
        
        return NO;
    }
    
    NSMutableDictionary *query = [self query];
    #if TARGET_OS_IPHONE
    status = SecItemDelete((__bridge CFDictionaryRef)query);
    #else
    // On Mac OS, SecItemDelete will not delete a key created in a different
    // app, nor in a different version of the same app.
    //
    // To replicate the issue, save a password, change to the code and
    // rebuild the app, and then attempt to delete that password.
    //
    // This was true in OS X 10.6 and probably later versions as well.
    //
    // Work around it by using SecItemCopyMatching and SecKeychainItemDelete.
    CFTypeRef result = NULL;
    query[(__bridge id)kSecReturnRef] = @YES;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess) {
        status = SecKeychainItemDelete((SecKeychainItemRef)result);
        CFRelease(result);
    }
    #endif
    
    if (status != errSecSuccess && error != NULL) {
        *error = [self errorWithCode:status];
    }
    
    return (status == errSecSuccess);
}


- (NSArray *)fetchAll:(NSError *__autoreleasing *)error {
    NSMutableDictionary *query = [self query];
    query[(__bridge id)kSecReturnAttributes] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
    #if __IPHONE_4_0 && TARGET_OS_IPHONE
    CFTypeRef accessibilityType = FLEXKeychain.accessibilityType;
    if (accessibilityType) {
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)accessibilityType;
    }
    #endif
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess && error != NULL) {
        *error = [self errorWithCode:status];
        return nil;
    }
    
    return (__bridge_transfer NSArray *)result ?: @[];
}


- (BOOL)fetch:(NSError *__autoreleasing *)error {
    OSStatus status = FLEXKeychainErrorBadArguments;
    if (!self.service || !self.account) {
        if (error) {
            *error = [self errorWithCode:status];
        }
        return NO;
    }
    
    CFTypeRef result = NULL;
    NSMutableDictionary *query = [self query];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status != errSecSuccess) {
        if (error) {
            *error = [self errorWithCode:status];
        }
        return NO;
    }
    
    self.passwordData = (__bridge_transfer NSData *)result;
    return YES;
}


#pragma mark - Accessors


- (void)setPassword:(NSString *)password {
    self.passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
}


- (NSString *)password {
    if (self.passwordData.length) {
        return [[NSString alloc] initWithData:self.passwordData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}


#pragma mark - Synchronization Status

#ifdef FLEXKEYCHAIN_SYNCHRONIZATION_AVAILABLE
+ (BOOL)isSynchronizationAvailable {
    #if TARGET_OS_IPHONE
    return YES;
    #else
    return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_8_4;
    #endif
}
#endif


#pragma mark - Private

- (NSMutableDictionary *)query {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    
    if (self.service) {
        dictionary[(__bridge id)kSecAttrService] = self.service;
    }
    
    if (self.account) {
        dictionary[(__bridge id)kSecAttrAccount] = self.account;
    }
    
    #ifdef FLEXKEYCHAIN_ACCESS_GROUP_AVAILABLE
    #if !TARGET_IPHONE_SIMULATOR
    if (self.accessGroup) {
        dictionary[(__bridge id)kSecAttrAccessGroup] = self.accessGroup;
    }
    #endif
    #endif
    
    #ifdef FLEXKEYCHAIN_SYNCHRONIZATION_AVAILABLE
    if ([[self class] isSynchronizationAvailable]) {
        id value;
        
        switch (self.synchronizationMode) {
            case FLEXKeychainQuerySynchronizationModeNo: {
                value = @NO;
                break;
            }
            case FLEXKeychainQuerySynchronizationModeYes: {
                value = @YES;
                break;
            }
            case FLEXKeychainQuerySynchronizationModeAny: {
                value = (__bridge id)(kSecAttrSynchronizableAny);
                break;
            }
        }
        
        dictionary[(__bridge id)(kSecAttrSynchronizable)] = value;
    }
    #endif
    
    return dictionary;
}

- (NSError *)errorWithCode:(OSStatus)code {
    static dispatch_once_t onceToken;
    static NSBundle *resourcesBundle = nil;
    dispatch_once(&onceToken, ^{
        NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"FLEXKeychain" withExtension:@"bundle"];
        resourcesBundle = [NSBundle bundleWithURL:url];
    });
    
    NSString *message = nil;
    switch (code) {
        case errSecSuccess: return nil;
        case FLEXKeychainErrorBadArguments: message = NSLocalizedStringFromTableInBundle(@"FLEXKeychainErrorBadArguments", @"FLEXKeychain", resourcesBundle, nil); break;
            
        #if TARGET_OS_IPHONE
        case errSecUnimplemented: {
            message = NSLocalizedStringFromTableInBundle(@"errSecUnimplemented", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecParam: {
            message = NSLocalizedStringFromTableInBundle(@"errSecParam", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecAllocate: {
            message = NSLocalizedStringFromTableInBundle(@"errSecAllocate", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecNotAvailable: {
            message = NSLocalizedStringFromTableInBundle(@"errSecNotAvailable", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecDuplicateItem: {
            message = NSLocalizedStringFromTableInBundle(@"errSecDuplicateItem", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecItemNotFound: {
            message = NSLocalizedStringFromTableInBundle(@"errSecItemNotFound", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecInteractionNotAllowed: {
            message = NSLocalizedStringFromTableInBundle(@"errSecInteractionNotAllowed", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecDecode: {
            message = NSLocalizedStringFromTableInBundle(@"errSecDecode", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        case errSecAuthFailed: {
            message = NSLocalizedStringFromTableInBundle(@"errSecAuthFailed", @"FLEXKeychain", resourcesBundle, nil);
            break;
        }
        default: {
            message = NSLocalizedStringFromTableInBundle(@"errSecDefault", @"FLEXKeychain", resourcesBundle, nil);
        }
        #else
        default:
            message = (__bridge_transfer NSString *)SecCopyErrorMessageString(code, NULL);
        #endif
    }
    
    NSDictionary *userInfo = message ? @{ NSLocalizedDescriptionKey : message } : nil;
    return [NSError errorWithDomain:kFLEXKeychainErrorDomain code:code userInfo:userInfo];
}

@end
