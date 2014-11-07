//
//  FLEXInformationCollector.m
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

@import ObjectiveC.runtime;

#import "FLEXInformationCollector.h"

@implementation FLEXInformationCollector

+ (instancetype)sharedCollector;
{
    static id defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[self alloc] init];
    });
    return defaultInstance;
}


+ (NSArray *)informationCollectors
{
    //
    // http://stackoverflow.com/questions/7923586/objective-c-get-list-of-subclasses-from-superclass
    //
    
    Class parentClass = [FLEXInformationCollector class];
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++)
    {
        Class superClass = classes[i];
        do
        {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
        
        if (superClass == nil)
        {
            continue;
        }
        
        [result addObject:classes[i]];
    }
    
    free(classes);
    
    return [result copy];
}

- (void)activate
{
}

@end
