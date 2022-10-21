//
//  FLEXWindowManagerController.m
//  FLEX
//
//  Created by Tanner on 2/6/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXWindowManagerController.h"
#import "FLEXManager+Private.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXWindowManagerController ()
@property (nonatomic) UIWindow *keyWindow;
@property (nonatomic, copy) NSString *keyWindowSubtitle;
@property (nonatomic, copy) NSArray<UIWindow *> *windows;
@property (nonatomic, copy) NSArray<NSString *> *windowSubtitles;
@property (nonatomic, copy) NSArray<UIScene *> *scenes API_AVAILABLE(ios(13));
@property (nonatomic, copy) NSArray<NSString *> *sceneSubtitles;
@property (nonatomic, copy) NSArray<NSArray *> *sections;
@end

@implementation FLEXWindowManagerController

#pragma mark - Initialization

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Windows";
    if (@available(iOS 13, *)) {
        self.title = @"Windows and Scenes";
    }
    
    [self disableToolbar];
    [self reloadData];
}


#pragma mark - Private

- (void)reloadData {
    self.keyWindow = UIApplication.sharedApplication.keyWindow;
    self.windows = UIApplication.sharedApplication.windows;
    self.keyWindowSubtitle = self.windowSubtitles[[self.windows indexOfObject:self.keyWindow]];
    self.windowSubtitles = [self.windows flex_mapped:^id(UIWindow *window, NSUInteger idx) {
        return [NSString stringWithFormat:@"Level: %@ — Root: %@",
            @(window.windowLevel), window.rootViewController
        ];
    }];
    
    if (@available(iOS 13, *)) {
        self.scenes = UIApplication.sharedApplication.connectedScenes.allObjects;
        self.sceneSubtitles = [self.scenes flex_mapped:^id(UIScene *scene, NSUInteger idx) {
            return [self sceneDescription:scene];
        }];
        
        self.sections = @[@[self.keyWindow], self.windows, self.scenes];
    } else {
        self.sections = @[@[self.keyWindow], self.windows];
    }
    
    [self.tableView reloadData];
}

- (void)dismissAnimated {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showRevertOrDismissAlert:(void(^)(void))revertBlock {
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self reloadData];
    [self.tableView reloadData];
    
    UIWindow *highestWindow = UIApplication.sharedApplication.keyWindow;
    UIWindowLevel maxLevel = 0;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.windowLevel > maxLevel) {
            maxLevel = window.windowLevel;
            highestWindow = window;
        }
    }
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Keep Changes?");
        make.message(@"If you do not wish to keep these settings, choose 'Revert Changes' below.");
        
        make.button(@"Keep Changes").destructiveStyle();
        make.button(@"Keep Changes and Dismiss").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            [self dismissAnimated];
        });
        make.button(@"Revert Changes").cancelStyle().handler(^(NSArray<NSString *> *strings) {
            revertBlock();
            [self reloadData];
            [self.tableView reloadData];
        });
    } showFrom:[FLEXUtility topViewControllerInWindow:highestWindow]];
}

- (NSString *)sceneDescription:(UIScene *)scene API_AVAILABLE(ios(13)) {
    NSString *state = [self stringFromSceneState:scene.activationState];
    NSString *title = scene.title.length ? scene.title : nil;
    NSString *suffix = nil;
    
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (id)scene;
        suffix = FLEXPluralString(windowScene.windows.count, @"windows", @"window");
    }
    
    NSMutableString *description = state.mutableCopy;
    if (title) {
        [description appendFormat:@" — %@", title];
    }
    if (suffix) {
        [description appendFormat:@" — %@", suffix];
    }
    
    return description.copy;
}

- (NSString *)stringFromSceneState:(UISceneActivationState)state API_AVAILABLE(ios(13)) {
    switch (state) {
        case UISceneActivationStateUnattached:
            return @"Unattached";
        case UISceneActivationStateForegroundActive:
            return @"Active";
        case UISceneActivationStateForegroundInactive:
            return @"Inactive";
        case UISceneActivationStateBackground:
            return @"Backgrounded";
    }
    
    return [NSString stringWithFormat:@"Unknown state: %@", @(state)];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Key Window";
        case 1: return @"Windows";
        case 2: return @"Connected Scenes";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXDetailCell forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    UIWindow *window = nil;
    NSString *subtitle = nil;
    
    switch (indexPath.section) {
        case 0:
            window = self.keyWindow;
            subtitle = self.keyWindowSubtitle;
            break;
        case 1:
            window = self.windows[indexPath.row];
            subtitle = self.windowSubtitles[indexPath.row];
            break;
        case 2:
            if (@available(iOS 13, *)) {
                UIScene *scene = self.scenes[indexPath.row];
                cell.textLabel.text = scene.description;
                cell.detailTextLabel.text = self.sceneSubtitles[indexPath.row];
                return cell;
            }
    }
    
    cell.textLabel.text = window.description;
    cell.detailTextLabel.text = [NSString
        stringWithFormat:@"Level: %@ — Root: %@",
        @((NSInteger)window.windowLevel), window.rootViewController.class
    ];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIWindow *window = nil;
    NSString *subtitle = nil;
    FLEXWindow *flex = FLEXManager.sharedManager.explorerWindow;
    
    id cancelHandler = ^{
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    };
    
    switch (indexPath.section) {
        case 0:
            window = self.keyWindow;
            subtitle = self.keyWindowSubtitle;
            break;
        case 1:
            window = self.windows[indexPath.row];
            subtitle = self.windowSubtitles[indexPath.row];
            break;
        case 2:
            if (@available(iOS 13, *)) {
                UIScene *scene = self.scenes[indexPath.row];
                UIWindowScene *oldScene = flex.windowScene;
                BOOL isWindowScene = [scene isKindOfClass:[UIWindowScene class]];
                BOOL isFLEXScene = isWindowScene ? flex.windowScene == scene : NO;
                
                [FLEXAlert makeAlert:^(FLEXAlert *make) {
                    make.title(NSStringFromClass(scene.class));
                    
                    if (isWindowScene) {
                        if (isFLEXScene) {
                            make.message(@"Already the FLEX window scene");
                        }
                        
                        make.button(@"Set as FLEX Window Scene")
                        .handler(^(NSArray<NSString *> *strings) {
                            flex.windowScene = (id)scene;
                            [self showRevertOrDismissAlert:^{
                                flex.windowScene = oldScene;
                            }];
                        }).enabled(!isFLEXScene);
                        make.button(@"Cancel").cancelStyle();
                    } else {
                        make.message(@"Not a UIWindowScene");
                        make.button(@"Dismiss").cancelStyle().handler(cancelHandler);
                    }
                } showFrom:self];
            }
    }

    __block UIWindow *targetWindow = nil, *oldKeyWindow = nil;
    __block UIWindowLevel oldLevel;
    __block BOOL wasVisible;
    
    subtitle = [subtitle stringByAppendingString:
        @"\n\n1) Adjust the FLEX window level relative to this window,\n"
        "2) adjust this window's level relative to the FLEX window,\n"
        "3) set this window's level to a specific value, or\n"
        "4) make this window the key window if it isn't already."
    ];
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(NSStringFromClass(window.class)).message(subtitle);
        make.button(@"Adjust FLEX Window Level").handler(^(NSArray<NSString *> *strings) {
            targetWindow = flex; oldLevel = flex.windowLevel;
            flex.windowLevel = window.windowLevel + strings.firstObject.integerValue;
            
            [self showRevertOrDismissAlert:^{ targetWindow.windowLevel = oldLevel; }];
        });
        make.button(@"Adjust This Window's Level").handler(^(NSArray<NSString *> *strings) {
            targetWindow = window; oldLevel = window.windowLevel;
            window.windowLevel = flex.windowLevel + strings.firstObject.integerValue;
            
            [self showRevertOrDismissAlert:^{ targetWindow.windowLevel = oldLevel; }];
        });
        make.button(@"Set This Window's Level").handler(^(NSArray<NSString *> *strings) {
            targetWindow = window; oldLevel = window.windowLevel;
            window.windowLevel = strings.firstObject.integerValue;
            
            [self showRevertOrDismissAlert:^{ targetWindow.windowLevel = oldLevel; }];
        });
        make.button(@"Make Key And Visible").handler(^(NSArray<NSString *> *strings) {
            oldKeyWindow = UIApplication.sharedApplication.keyWindow;
            wasVisible = window.hidden;
            [window makeKeyAndVisible];
            
            [self showRevertOrDismissAlert:^{
                window.hidden = wasVisible;
                [oldKeyWindow makeKeyWindow];
            }];
        }).enabled(!window.isKeyWindow && !window.hidden);
        make.button(@"Cancel").cancelStyle().handler(cancelHandler);
        
        make.textField(@"+/- window level, i.e. 5 or -10");
    } showFrom:self];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)ip {
    [self.navigationController pushViewController:
        [FLEXObjectExplorerFactory explorerViewControllerForObject:self.sections[ip.section][ip.row]]
    animated:YES];
}

@end
