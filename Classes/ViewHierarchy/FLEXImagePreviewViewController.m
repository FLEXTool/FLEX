//
//  FLEXImagePreviewViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/12/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXImagePreviewViewController.h"
#import "FLEXUtility.h"

@interface FLEXImagePreviewViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation FLEXImagePreviewViewController

- (id)initWithImage:(UIImage *)image
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = @"Preview";
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [FLEXUtility scrollViewGrayColor];
    
    self.imageView = [[UIImageView alloc] initWithImage:self.image];
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = self.view.backgroundColor;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.scrollView addSubview:self.imageView];
    self.scrollView.contentSize = self.imageView.frame.size;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 2.0;
    [self.view addSubview:self.scrollView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
}

- (void)viewDidLayoutSubviews
{
    [self centerContentInScrollViewIfNeeded];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centerContentInScrollViewIfNeeded];
}

- (void)centerContentInScrollViewIfNeeded
{
    CGFloat horizontalInset = 0.0;
    CGFloat verticalInset = 0.0;
    if (self.scrollView.contentSize.width < self.scrollView.bounds.size.width) {
        horizontalInset = (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) / 2.0;
    }
    if (self.scrollView.contentSize.height < self.scrollView.bounds.size.height) {
        verticalInset = (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) / 2.0;
    }
    self.scrollView.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
}

- (void)actionButtonPressed:(id)sender
{
    static BOOL CanSaveToCameraRoll = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
            CanSaveToCameraRoll = YES;
            return;
        }
        
        NSBundle *mainBundle = [NSBundle mainBundle];
        if ([mainBundle.infoDictionary.allKeys containsObject:@"NSPhotoLibraryUsageDescription"]) {
            CanSaveToCameraRoll = YES;
        } else {
            NSLog(@"Add NSPhotoLibraryUsageDescription in app's Info.plist for saving captured image into camera roll.");
        }
    });
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.image] applicationActivities:@[]];
    
    if (!CanSaveToCameraRoll) {
        activityVC.excludedActivityTypes = @[UIActivityTypeSaveToCameraRoll];
    }
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

@end
