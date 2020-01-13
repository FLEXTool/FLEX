//
//  FLEXRuntimeController.h
//  FLEX
//
//  Created by Tanner on 3/23/17.
//

#import "TBKeyPath.h"


@interface TBRuntimeController : NSObject

/// @return An array of strings if the key path only evaluates
///         to a class or bundle; otherwise, a list of lists of FLEXMethods.
+ (NSArray *)dataForKeyPath:(TBKeyPath *)keyPath;

/// Useful when you need to specify which classes to search in.
/// \c dataForKeyPath: will only search classes matching the class key.
/// We use this elsewhere when we need to search a class hierarchy.
+ (NSArray<NSArray<FLEXMethod *> *> *)methodsForToken:(TBToken *)token
                                             instance:(NSNumber *)onlyInstanceMethods
                                            inClasses:(NSArray<NSString*> *)classes;

/// Useful when you need the classes that are associated with the
/// double list of methods returned from \c dataForKeyPath
+ (NSMutableArray<NSString *> *)classesForKeyPath:(TBKeyPath *)keyPath;

+ (NSString *)shortBundleNameForClass:(NSString *)name;

+ (NSString *)imagePathWithShortName:(NSString *)suffix;

+ (NSArray<NSString*> *)allBundleNames;

@end
