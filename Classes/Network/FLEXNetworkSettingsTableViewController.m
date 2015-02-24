//
//  FLEXNetworkSettingsTableViewController.m
//  FLEXInjected
//
//  Created by Ryan Olson on 2/20/15.
//
//

#import "FLEXNetworkSettingsTableViewController.h"
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXUtility.h"

@interface FLEXNetworkSettingsTableViewController () <UIActionSheetDelegate>

@property (nonatomic, copy) NSArray *cells;

@property (nonatomic, strong) UITableViewCell *cacheLimitCell;

@end

@implementation FLEXNetworkSettingsTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableArray *mutableCells = [NSMutableArray array];

    UITableViewCell *networkDebuggingCell = [self switchCellWithTitle:@"Network Debugging" toggleAction:@selector(networkDebuggingToggled:) isOn:[FLEXNetworkObserver isEnabled]];
    [mutableCells addObject:networkDebuggingCell];

    UITableViewCell *enableOnLaunchCell = [self switchCellWithTitle:@"Enable on Launch" toggleAction:@selector(enableOnLaunchToggled:) isOn:[FLEXNetworkObserver shouldEnableOnLaunch]];
    [mutableCells addObject:enableOnLaunchCell];

    UITableViewCell *cacheMediaResponsesCell = [self switchCellWithTitle:@"Cache Media Responses" toggleAction:@selector(cacheMediaResponsesToggled:) isOn:NO];
    [mutableCells addObject:cacheMediaResponsesCell];

    NSUInteger currentCacheLimit = [[FLEXNetworkRecorder defaultRecorder] responseCacheByteLimit];
    const NSUInteger fiftyMega = 50 * 1024 * 1024;
    NSString *cacheLimitTitle = [self titleForCacheLimitCellWithValue:currentCacheLimit];
    self.cacheLimitCell = [self sliderCellWithTitle:cacheLimitTitle changedAction:@selector(cacheLimitAdjusted:) minimum:0.0 maximum:fiftyMega initialValue:currentCacheLimit];
    [mutableCells addObject:self.cacheLimitCell];

    UITableViewCell *clearRecordedRequestsCell = [self buttonCellWithTitle:@"❌  Clear Recorded Requests" touchUpAction:@selector(clearRequestsTapped:) isDestructive:YES];
    [mutableCells addObject:clearRecordedRequestsCell];

    self.cells = mutableCells;
}

#pragma mark - Settings Actions

- (void)networkDebuggingToggled:(UISwitch *)sender
{
    [FLEXNetworkObserver setEnabled:sender.isOn];
}

- (void)enableOnLaunchToggled:(UISwitch *)sender
{
    [FLEXNetworkObserver setShouldEnableOnLaunch:sender.isOn];
}

- (void)cacheMediaResponsesToggled:(UISwitch *)sender
{
    [[FLEXNetworkRecorder defaultRecorder] setShouldCacheMediaResponses:sender.isOn];
}

- (void)cacheLimitAdjusted:(UISlider *)sender
{
    [[FLEXNetworkRecorder defaultRecorder] setResponseCacheByteLimit:sender.value];
    self.cacheLimitCell.textLabel.text = [self titleForCacheLimitCellWithValue:sender.value];
}

- (void)clearRequestsTapped:(UIButton *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear Recorded Requests" otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cells count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return [self.cells objectAtIndex:indexPath.row];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [[FLEXNetworkRecorder defaultRecorder] clearRecordedActivity];
    }
}

#pragma mark - Helpers

- (UITableViewCell *)switchCellWithTitle:(NSString *)title toggleAction:(SEL)toggleAction isOn:(BOOL)isOn
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = title;
    cell.textLabel.font = [[self class] cellTitleFont];

    UISwitch *theSwitch = [[UISwitch alloc] init];
    theSwitch.on = isOn;
    [theSwitch addTarget:self action:toggleAction forControlEvents:UIControlEventValueChanged];

    CGFloat switchOriginY = round((cell.contentView.frame.size.height - theSwitch.frame.size.height) / 2.0);
    CGFloat switchOriginX = CGRectGetMaxX(cell.contentView.frame) - theSwitch.frame.size.width - self.tableView.separatorInset.left;
    theSwitch.frame = CGRectMake(switchOriginX, switchOriginY, theSwitch.frame.size.width, theSwitch.frame.size.height);
    theSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [cell.contentView addSubview:theSwitch];

    return cell;
}

- (UITableViewCell *)buttonCellWithTitle:(NSString *)title touchUpAction:(SEL)action isDestructive:(BOOL)isDestructive
{
    UITableViewCell *buttonCell = [[UITableViewCell alloc] init];
    buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;

    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [actionButton setTitle:title forState:UIControlStateNormal];
    if (isDestructive) {
        actionButton.tintColor = [UIColor redColor];
    }
    actionButton.titleLabel.font = [[self class] cellTitleFont];;
    [actionButton addTarget:self action:@selector(clearRequestsTapped:) forControlEvents:UIControlEventTouchUpInside];

    [buttonCell.contentView addSubview:actionButton];
    actionButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    actionButton.frame = buttonCell.contentView.frame;
    actionButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, self.tableView.separatorInset.left, 0.0, self.tableView.separatorInset.left);
    actionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    return buttonCell;
}

- (NSString *)titleForCacheLimitCellWithValue:(long long)cacheLimit
{
    NSInteger limitInMB = round(cacheLimit / (1024 * 1024));
    return [NSString stringWithFormat:@"Cache Limit (%ld MB)", (long)limitInMB];
}

- (UITableViewCell *)sliderCellWithTitle:(NSString *)title changedAction:(SEL)changedAction minimum:(CGFloat)minimum maximum:(CGFloat)maximum initialValue:(CGFloat)initialValue
{
    UITableViewCell *sliderCell = [[UITableViewCell alloc] init];
    sliderCell.selectionStyle = UITableViewCellSelectionStyleNone;
    sliderCell.textLabel.text = title;
    sliderCell.textLabel.font = [[self class] cellTitleFont];

    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = minimum;
    slider.maximumValue = maximum;
    slider.value = initialValue;
    [slider addTarget:self action:changedAction forControlEvents:UIControlEventValueChanged];
    [slider sizeToFit];

    CGFloat sliderWidth = round(sliderCell.contentView.frame.size.width * 2.0 / 5.0);
    CGFloat sliderOriginY = round((sliderCell.contentView.frame.size.height - slider.frame.size.height) / 2.0);
    CGFloat sliderOriginX = CGRectGetMaxX(sliderCell.contentView.frame) - sliderWidth - self.tableView.separatorInset.left;
    slider.frame = CGRectMake(sliderOriginX, sliderOriginY, sliderWidth, slider.frame.size.height);
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [sliderCell.contentView addSubview:slider];

    return sliderCell;
}

+ (UIFont *)cellTitleFont
{
    return [FLEXUtility defaultFontOfSize:14.0];
}

@end
