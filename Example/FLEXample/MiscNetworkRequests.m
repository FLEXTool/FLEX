//
//  MiscNetworkRequests.m
//  FLEXample
//
//  Created by Tanner on 3/12/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "MiscNetworkRequests.h"

@implementation MiscNetworkRequests

+ (void)sendExampleRequests {
    [[self new] sendExampleNetworkRequests];
}

- (NSMutableURLRequest *)request:(NSString *)url {
    return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
}

- (void)sendExampleNetworkRequests {
    NSString *kFlipboardIcon = @"https://cdn.flipboard.com/serviceIcons/v2/social-icon-flipboard-96.png";
    NSString *kRandomAnimal = @"https://lorempixel.com/248/250/animals/";
    NSString *kSnowLeopard = @"https://lorempixel.com/248/250/animals/4/";
    NSString *kRateLimit = @"https://api.github.com/rate_limit";
    NSString *kImgurUpload = @"https://api.imgur.com/3/upload";
    
    //#######################
    //                      #
    //     NSURLSession     #
    //                      #
    //#######################
    
    NSMutableArray *pendingTasks = [NSMutableArray array];
    
    // With delegate //
    
    NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
    config.timeoutIntervalForRequest = 10.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    // NSURLSessionDataTask
    [pendingTasks addObject:[session dataTaskWithURL:[NSURL URLWithString:kFlipboardIcon]]];
    // NSURLSessionDownloadTask
    [pendingTasks addObject:[session downloadTaskWithURL:[NSURL URLWithString:kRandomAnimal]]];
    
    // Without delegate //
    
    // NSURLSessionDownloadTask
    [pendingTasks addObject:[NSURLSession.sharedSession
        downloadTaskWithURL:[NSURL URLWithString:kSnowLeopard]
        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            NSInteger status = [(NSHTTPURLResponse *)response statusCode];
        
            if (status == 200) {
                NSLog(@"Image downloaded to %@", location.absoluteString);
            } else {
                NSLog(@"Image failed to download with status %@ (error: %@)",
                    @(status), error.localizedDescription
                );
            }
        }
    ]];

    // NSURLSessionDataTask
    [pendingTasks addObject:[NSURLSession.sharedSession
        dataTaskWithURL:[NSURL URLWithString:kRateLimit]
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    }]];

    // NSURLSessionUploadTask
    NSMutableURLRequest *upload = [self request:kImgurUpload];
    upload.HTTPMethod = @"POST";
    [upload setValue:@"Client-ID 0e8a1cb2eb594ef" forHTTPHeaderField:@"Authorization"];
    [pendingTasks addObject:[session
        uploadTaskWithRequest:upload
        fromFile:[NSBundle.mainBundle URLForResource:@"image" withExtension:@"jpg"]
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSInteger status = [(NSHTTPURLResponse *)response statusCode];
        
            if (status == 200) {
                NSError *jsonError = nil;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                
                if (json) {
                    NSLog(@"Image uploaded to %@", json[@"data"][@"link"]);
                } else {
                    NSLog(@"Error decoding JSON after uploading image: %@", jsonError.localizedDescription);
                }
            } else if (data) {
                NSError *jsonError = nil;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                
                if (json) {
                    NSLog(@"Image failed to upload with error: %@", json[@"data"][@"error"]);
                } else {
                    NSLog(@"Error decoding JSON after failing to upload image: %@", jsonError.localizedDescription);
                }
            } else {
                NSLog(@"Error uploading image: %@", error.localizedDescription);
            }
        }
    ]];

    NSTimeInterval delayTime = 5;
    const NSTimeInterval stagger = 1;

    // Stagger each task
    for (NSURLSessionTask *task in pendingTasks) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task resume];
        });
        
        delayTime += stagger;
    }
    
    //########################
    //                       #
    //    NSURLConnection    #
    //                       #
    //########################

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    // Remaining requests made through NSURLConnection with a delegate
    NSArray *requestURLStrings = @[ @"https://lorempixel.com/400/400/",
                                    @"https://google.com",
                                    @"https://api.github.com/users/Flipboard/repos",
                                    @"https://api.github.com/repos/Flipboard/FLEX/issues",
                                    @"https://cloud.githubusercontent.com/assets/516562/3971767/e4e21f58-27d6-11e4-9b07-4d1fe82b80ca.png",
                                    @"https://lorempixel.com/750/1334/" ];
    
    // Async NSURLConnection
    [NSURLConnection sendAsynchronousRequest:[self request:@"https://api.github.com/repos/Flipboard/FLEX/issues"]
        queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    }];
    
    // Begin staggering NSURLConnection requests
    self.connections = [NSMutableArray array];
    for (NSString *urlString in requestURLStrings) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.connections addObject:[NSURLConnection connectionWithRequest:[self request:urlString] delegate:self]];
        });
        
        delayTime += stagger;
    }
    
    #pragma clang diagnostic pop
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"URLSession didBecomeInvalidWithError: %@", error.localizedDescription);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"didFinishDownloadingToURL: %@", location.absoluteString);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.connections removeObject:connection];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.connections removeObject:connection];
}

@end
