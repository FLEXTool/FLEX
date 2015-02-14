//
//  FLEXFileBrowserFileOperationController.h
//  Flipboard
//
//  Created by Daniel Rodriguez Troitino on 2/13/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FLEXFileBrowserFileOperationController;

@protocol FLEXFileBrowserFileOperationControllerDelegate <NSObject>

- (void)fileOperationControllerDidDismiss:(id<FLEXFileBrowserFileOperationController>)controller;

@end

@protocol FLEXFileBrowserFileOperationController <NSObject>

@property (nonatomic, weak) id<FLEXFileBrowserFileOperationControllerDelegate> delegate;

- (instancetype)initWithPath:(NSString *)path;

- (void)show;

@end

@interface FLEXFileBrowserFileDeleteOperationController : NSObject <FLEXFileBrowserFileOperationController>
@end

@interface FLEXFileBrowserFileRenameOperationController : NSObject <FLEXFileBrowserFileOperationController>
@end
