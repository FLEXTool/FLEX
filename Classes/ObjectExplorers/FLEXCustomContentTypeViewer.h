//
//  FLEXCustomContentTypeViewer.h
//  FLEX
//
//  Created by Georgy Kasapidi on 11.11.17.
//  Copyright © 2017 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef UIViewController *(^FLEXCustomContentTypeViewerViewControllerFuture)(NSString *mimeType, NSData *data);

@interface FLEXCustomContentTypeViewer : NSObject

@property (copy, nonatomic) NSString *contentType;
@property (copy, nonatomic) FLEXCustomContentTypeViewerViewControllerFuture viewControllerFuture;

@end
