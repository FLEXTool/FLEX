//
//  FLEXTableViewCell.m
//  FLEX
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTableViewCell.h"
#import "FLEXUtility.h"
#import "FLEXTableView.h"

@interface UITableView (Internal)
// Exists at least since iOS 5
- (BOOL)_canPerformAction:(SEL)action forCell:(UITableViewCell *)cell sender:(id)sender;
- (void)_performAction:(SEL)action forCell:(UITableViewCell *)cell sender:(id)sender;
@end

@interface UITableViewCell (Internal)
// Exists at least since iOS 5
@property (nonatomic, readonly) FLEXTableView *_tableView;
@end

@implementation FLEXTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
        self.textLabel.font = cellFont;
        self.detailTextLabel.font = cellFont;
        self.detailTextLabel.textColor = [UIColor grayColor];
    }

    return self;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return [self._tableView _canPerformAction:action forCell:self sender:sender];
}

/// We use this to allow our table view to allow its delegate
/// to handle any action it chooses to support, without
/// explicitly implementing the method ourselelves.
///
/// Alternative considered: override respondsToSelector
/// to return NO. I decided against this for simplicity's
/// sake. I see this as "fixing" a poorly designed API.
/// That approach would require lots of boilerplate to
/// make the menu appear above this cell.
- (void)forwardInvocation:(NSInvocation *)invocation
{
    // Must be unretained to avoid over-releasing
    __unsafe_unretained id sender;
    [invocation getArgument:&sender atIndex:2];
    SEL action = invocation.selector;

    // [self._tableView _performAction:action forCell:[self retain] sender:[sender retain]];
    invocation.selector = @selector(_performAction:forCell:sender:);
    [invocation setArgument:&action atIndex:2];
    [invocation setArgument:(void *)&self atIndex:3];
    [invocation setArgument:(void *)&sender atIndex:4];
    [invocation invokeWithTarget:self._tableView];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    if ([self canPerformAction:selector withSender:nil]) {
        return [self._tableView methodSignatureForSelector:@selector(_performAction:forCell:sender:)];
    }

    return [super methodSignatureForSelector:selector];
}

@end
