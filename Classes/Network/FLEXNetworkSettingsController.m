//
//  FLEXNetworkSettingsController.m
//  FLEXInjected
//
//  Created by Ryan Olson on 2/20/15.
//

#import "FLEXNetworkSettingsController.h"
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXUtility.h"
#import "FLEXTableView.h"
#import "FLEXColor.h"
#import "NSUserDefaults+FLEX.h"

@interface FLEXNetworkSettingsController () <UIActionSheetDelegate>
@property (nonatomic) float cacheLimitValue;
@property (nonatomic, readonly) NSString *cacheLimitCellTitle;

@property (nonatomic, readonly) UISwitch *observerSwitch;
@property (nonatomic, readonly) UISwitch *cacheMediaSwitch;
@property (nonatomic, readonly) UISwitch *jsonViewerSwitch;
@property (nonatomic, readonly) UISlider *cacheLimitSlider;
@property (nonatomic) UILabel *cacheLimitLabel;

@property (nonatomic) NSMutableArray<NSString *> *hostDenylist;
@end

@implementation FLEXNetworkSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self disableToolbar];
    self.hostDenylist = FLEXNetworkRecorder.defaultRecorder.hostDenylist.mutableCopy;
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    
    _observerSwitch = [UISwitch new];
    _cacheMediaSwitch = [UISwitch new];
    _jsonViewerSwitch = [UISwitch new];
    _cacheLimitSlider = [UISlider new];
    
    self.observerSwitch.on = FLEXNetworkObserver.enabled;
    [self.observerSwitch addTarget:self
        action:@selector(networkDebuggingToggled:)
        forControlEvents:UIControlEventValueChanged
    ];
    
    self.cacheMediaSwitch.on = FLEXNetworkRecorder.defaultRecorder.shouldCacheMediaResponses;
    [self.cacheMediaSwitch addTarget:self
        action:@selector(cacheMediaResponsesToggled:)
        forControlEvents:UIControlEventValueChanged
    ];
    
    self.jsonViewerSwitch.on = defaults.flex_registerDictionaryJSONViewerOnLaunch;
    [self.jsonViewerSwitch addTarget:self
        action:@selector(jsonViewerSettingToggled:)
        forControlEvents:UIControlEventValueChanged
    ];
    
    [self.cacheLimitSlider addTarget:self
        action:@selector(cacheLimitAdjusted:)
        forControlEvents:UIControlEventValueChanged
    ];
    
    UISlider *slider = self.cacheLimitSlider;
    self.cacheLimitValue = FLEXNetworkRecorder.defaultRecorder.responseCacheByteLimit;
    const NSUInteger fiftyMega = 50 * 1024 * 1024;
    slider.minimumValue = 0;
    slider.maximumValue = fiftyMega;
    slider.value = self.cacheLimitValue;
}

- (void)setCacheLimitValue:(float)cacheLimitValue {
    _cacheLimitValue = cacheLimitValue;
    self.cacheLimitLabel.text = self.cacheLimitCellTitle;
    [FLEXNetworkRecorder.defaultRecorder setResponseCacheByteLimit:cacheLimitValue];
}

- (NSString *)cacheLimitCellTitle {
    NSInteger cacheLimit = self.cacheLimitValue;
    NSInteger limitInMB = round(cacheLimit / (1024 * 1024));
    return [NSString stringWithFormat:@"Cache Limit (%@ MB)", @(limitInMB)];
}


#pragma mark - Settings Actions

- (void)networkDebuggingToggled:(UISwitch *)sender {
    FLEXNetworkObserver.enabled = sender.isOn;
}

- (void)cacheMediaResponsesToggled:(UISwitch *)sender {
    FLEXNetworkRecorder.defaultRecorder.shouldCacheMediaResponses = sender.isOn;
}

- (void)jsonViewerSettingToggled:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults flex_toggleBoolForKey:kFLEXDefaultsRegisterJSONExplorerKey];
}

- (void)cacheLimitAdjusted:(UISlider *)sender {
    self.cacheLimitValue = sender.value;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 5;
        case 1: return self.hostDenylist.count;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"General";
        case 1: return @"Host Denylist";
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"By default, JSON is rendered in a webview. Turn on "
        "\"View JSON as a dictionary/array\" to convert JSON payloads "
        "to objects and view them in an object explorer. "
        "This setting requires a restart of the app.";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = [self.tableView
        dequeueReusableCellWithIdentifier:kFLEXDefaultCell forIndexPath:indexPath
    ];
    
    cell.accessoryView = nil;
    cell.textLabel.textColor = FLEXColor.primaryTextColor;
    
    switch (indexPath.section) {
        // Settings
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Network Debugging";
                    cell.accessoryView = self.observerSwitch;
                    break;
                case 1:
                    cell.textLabel.text = @"Cache Media Responses";
                    cell.accessoryView = self.cacheMediaSwitch;
                    break;
                case 2:
                    cell.textLabel.text = @"View JSON as a dictionary/array";
                    cell.accessoryView = self.jsonViewerSwitch;
                    break;
                case 3:
                    cell.textLabel.text = @"Reset Host Denylist";
                    cell.textLabel.textColor = tableView.tintColor;
                    break;
                case 4:
                    cell.textLabel.text = self.cacheLimitCellTitle;
                    self.cacheLimitLabel = cell.textLabel;
                    [self.cacheLimitSlider removeFromSuperview];
                    [cell.contentView addSubview:self.cacheLimitSlider];
                    
                    CGRect container = cell.contentView.frame;
                    UISlider *slider = self.cacheLimitSlider;
                    [slider sizeToFit];
                    
                    CGFloat sliderWidth = 150.f;
                    CGFloat sliderOriginY = FLEXFloor((container.size.height - slider.frame.size.height) / 2.0);
                    CGFloat sliderOriginX = CGRectGetMaxX(container) - sliderWidth - tableView.separatorInset.left;
                    self.cacheLimitSlider.frame = CGRectMake(
                        sliderOriginX, sliderOriginY, sliderWidth, slider.frame.size.height
                    );
                    
                    // Make wider, keep in middle of cell, keep to trailing edge of cell
                    self.cacheLimitSlider.autoresizingMask = ({
                        UIViewAutoresizingFlexibleWidth |
                        UIViewAutoresizingFlexibleLeftMargin |
                        UIViewAutoresizingFlexibleTopMargin |
                        UIViewAutoresizingFlexibleBottomMargin;
                    });
                    break;
            }
            
            break;
        }
        
        // Denylist entries
        case 1: {
            cell.textLabel.text = self.hostDenylist[indexPath.row];
            break;
        }
        
        default:
            @throw NSInternalInconsistencyException;
            break;
    }

    return cell;
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)ip {
    // Can only select the "Reset Host Denylist" row
    return ip.section == 0 && ip.row == 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Reset Host Denylist");
        make.message(@"You cannot undo this action. Are you sure?");
        make.button(@"Reset").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            self.hostDenylist = nil;
            [FLEXNetworkRecorder.defaultRecorder.hostDenylist removeAllObjects];
            [FLEXNetworkRecorder.defaultRecorder synchronizeDenylist];
            [self.tableView deleteSections:
                [NSIndexSet indexSetWithIndex:1]
            withRowAnimation:UITableViewRowAnimationAutomatic];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(style == UITableViewCellEditingStyleDelete);
    
    NSString *host = self.hostDenylist[indexPath.row];
    [self.hostDenylist removeObjectAtIndex:indexPath.row];
    [FLEXNetworkRecorder.defaultRecorder.hostDenylist removeObject:host];
    [FLEXNetworkRecorder.defaultRecorder synchronizeDenylist];
    
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
