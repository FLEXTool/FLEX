//
//  UIViewController+BackgroundImage.m
//

#import "UIViewController+BackgroundImage.h"

#define SWAP_DISSOLVE_ANIMATION_DURATION    2.0f
#define BACKGROUND_IMAGEVIEW_TAG            NSIntegerMax

@implementation UIViewController (BackgroundImage)

- (void)setBackgroundImage:(UIImage *)image
{
    [self setBackgroundImage:image animated:NO];
}

- (void)setBackgroundImage:(UIImage *)image animated:(BOOL)animated
{
    UIImageView* imageView = nil;
    
    if ([self.view.subviews count] && [self.view.subviews[0] isKindOfClass:[UIImageView class]] && [self.view.subviews[0] tag] == BACKGROUND_IMAGEVIEW_TAG)
    {
        imageView = self.view.subviews[0];
    }
    else if ([self.view.subviews count])
    {
        imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.tag = BACKGROUND_IMAGEVIEW_TAG;
        
        [self.view insertSubview:imageView atIndex:0];
    }
    else
    {
        imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.tag = BACKGROUND_IMAGEVIEW_TAG;
        
        [self.view addSubview:imageView];
    }
    
    if (animated)
    {
        [UIView transitionWithView:imageView duration:SWAP_DISSOLVE_ANIMATION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve animations:^
         {
             imageView.image = image;
         }
                        completion:nil];
    }
    else
    {
        imageView.image = image;
    }
}

- (UIImage *)backgroundImage
{
    if ([self.view.subviews count] && [self.view.subviews[0] isKindOfClass:[UIImageView class]] && [self.view.subviews[0] tag] == BACKGROUND_IMAGEVIEW_TAG)
    {
        UIImageView* imageView = self.view.subviews[0];
        
        return imageView.image;
    }
    
    return nil;
}

- (UIImageView *)backgroundImageView
{
    if ([self.view.subviews count] && [self.view.subviews[0] isKindOfClass:[UIImageView class]] && [self.view.subviews[0] tag] == BACKGROUND_IMAGEVIEW_TAG)
    {
        return self.view.subviews[0];
    }
    
    return nil;
}

@end
