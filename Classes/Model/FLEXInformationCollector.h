//
//  FLEXInformationCollector.h
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

@interface FLEXInformationCollector : NSObject

@property (nonatomic, getter = isEnabled) BOOL enabled;

/**
 *  Singleton access to specific information collector
 *
 *  @return shared instance of the collector
 */
+ (instancetype)sharedCollector;

+ (NSArray *)informationCollectors;

/**
 *  Starts collecting information
 */
- (void)activate;

@end
