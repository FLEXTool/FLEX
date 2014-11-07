//
//  FLEXInformationManager.h
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

@interface FLEXInformationManager : NSObject

@property (nonatomic, readonly) NSArray *collectors;

+ (instancetype)sharedManager;

- (void)setupCollectors;

@end
