//
//  UIButton+Position.m
//

@implementation UIButton (Position)

- (void)setTitleBelowWithSpacing:(CGFloat)spacing
{
    // Get the size of the elements here for readability
    CGSize imageSize = self.imageView.frame.size;
    CGSize titleSize = self.titleLabel.frame.size;
    CGSize frameSize = self.frame.size;

    // Get the height they will take up as a unit
    CGFloat totalHeight = (imageSize.height + titleSize.height + spacing);

    //
    // Image should be in center, so we need to move it if it is not
    //
    
    CGFloat leftInset = fabs(frameSize.width - imageSize.width) / 2.0;
    
    self.imageEdgeInsets = UIEdgeInsetsMake(-(totalHeight - imageSize.height), leftInset, 0.0, 0.0);

    // Lower the text and push it left to center it
    self.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (totalHeight - titleSize.height), 0.0);
}

@end
