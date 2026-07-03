//
//  FLEXRecommendationEngine.m
//  FLEX
//
//  Created by [Your Team] on 2025-06-26.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXRecommendationEngine.h"
#import "FLEXRecommendation.h"
#import "FLEXObjectExplorer.h"
#import "FLEXUtility.h"
#import "FLEXSingleRowSection.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXTableView.h"
#import "FLEXManager.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FLEXRecommendationEngine

- (NSArray<FLEXRecommendation *> *)suggestionsForObject:(id)object context:(nullable id)context {
    NSString *objectType = [FLEXRuntimeUtility safeClassNameForObject:object];
    NSUInteger maxCount = 3;

    if ([objectType isEqualToString:@"UIButton"]) {
        return [self generateUIButtonRecommendations:object type:objectType];
    } else if ([objectType isEqualToString:@"UIView"]) {
        return [self generateUIViewRecommendations:object type:objectType];
    } else if ([objectType isEqualToString:@"UIViewController"]) {
        return [self generateUIViewControllerRecommendations:object type:objectType];
    } else {
        return [self generateGenericRecommendations:object type:objectType count:maxCount];
    }
}

- (NSArray<FLEXRecommendation *> *)generateUIButtonRecommendations:(id)object type:(NSString *)type {
    NSMutableArray<FLEXRecommendation *> *recommendations = [NSMutableArray array];

    FLEXRecommendation *size = [FLEXRecommendation createWithTitle:@"Constrained Size"
                                                        subtitle:@"Add Auto‑Layout constraints to define the button size"
                                                 relevantObject:object
                                                            action:@"SIZE_SETUP"];
    FLEXRecommendation *handler = [FLEXRecommendation createWithTitle:@"Touch Handler"
                                                              subtitle:@"Add target‑action for user interaction"
                                                       relevantObject:object
                                                            action:@"HANDLER_SETUP"];
    FLEXRecommendation *state = [FLEXRecommendation createWithTitle:@"Button State"
                                                            subtitle:@"Configure normal / highlighted / disabled states"
                                                     relevantObject:object
                                                            action:@"STATE_SETUP"];

    [recommendations addObjectsFromArray:@[size, handler, state]];
    return recommendations;
}

- (NSArray<FLEXRecommendation *> *)generateUIViewRecommendations:(id)object type:(NSString *)type {
    NSMutableArray<FLEXRecommendation *> *recommendations = [NSMutableArray array];

    FLEXRecommendation *autoLayout = [FLEXRecommendation createWithTitle:@"Auto Layout"
                                                                 subtitle:@"Add constraints or adjust frames"
                                                            relevantObject:object
                                                                 action:@"AUTOLAYOUT_SETUP"];
    FLEXRecommendation *background = [FLEXRecommendation createWithTitle:@"Background"
                                                                   subtitle:@"Set background colour / image / alpha"
                                                            relevantObject:object
                                                                 action:@"BACKGROUND_SETUP"];
    FLEXRecommendation *corners = [FLEXRecommendation createWithTitle:@"Corners"
                                                                subtitle:@"Add corner radius / border styling"
                                                         relevantObject:object
                                                                action:@"CORNER_SETUP"];

    [recommendations addObjectsFromArray:@[autoLayout, background, corners]];
    return recommendations;
}

- (NSArray<FLEXRecommendation *> *)generateUIViewControllerRecommendations:(id)object type:(NSString *)type {
    NSMutableArray<FLEXRecommendation *> *recommendations = [NSMutableArray array];

    FLEXRecommendation *navigation = [FLEXRecommendation createWithTitle:@"Navigation"
                                                                   subtitle:@"Configure navigation bar items / hierarchy"
                                                            relevantObject:object
                                                                 action:@"NAVIGATION_SETUP"];
    FLEXRecommendation *outlets = [FLEXRecommendation createWithTitle:@"Outlets"
                                                                subtitle:@"Connect IBOutlets for easier inspection"
                                                         relevantObject:object
                                                                action:@"OUTLETS_SETUP"];
    FLEXRecommendation *lifecycle = [FLEXRecommendation createWithTitle:@"Lifecycle"
                                                                  subtitle:@"Add viewDidLoad / viewWillAppear hooks"
                                                               relevantObject:object
                                                                    action:@"LIFECYCLE_SETUP"];

    [recommendations addObjectsFromArray:@[navigation, outlets, lifecycle]];
    return recommendations;
}

- (NSArray<FLEXRecommendation *> *)generateGenericRecommendations:(id)object type:(NSString *)type count:(NSUInteger)maxCount {
    NSMutableArray<FLEXRecommendation *> *recommendations = [NSMutableArray array];

    FLEXRecommendation *methods = [FLEXRecommendation createWithTitle:@"Methods"
                                                              subtitle:@"Inspect / invoke instance & class methods"
                                                       relevantObject:object
                                                            action:@"METHODS_INSPECT"];
    FLEXRecommendation *properties = [FLEXRecommendation createWithTitle:@"Properties"
                                                                 subtitle:@"View / edit ivars & properties"
                                                              relevantObject:object
                                                                 action:@"PROPERTIES_EDIT"];
    FLEXRecommendation *references = [FLEXRecommendation createWithTitle:@"References"
                                                                   subtitle:@"Find live objects referencing this instance"
                                                              relevantObject:object
                                                                 action:@"REFERENCES_FIND"];

    [recommendations addObjectsFromArray:@[methods, properties, references]];

    if (recommendations.count > maxCount) {
        return [recommendations subarrayWithRange:NSMakeRange(0, maxCount)];
    }
    return recommendations;
}

+ (void)addRecommendationsToSections:(NSMutableArray<FLEXTableViewSection *> *)customSections forObject:(id)object {
    FLEXRecommendationEngine *engine = [[FLEXRecommendationEngine alloc] init];
    NSArray<FLEXRecommendation *> *recs = [engine suggestionsForObject:object context:nil];

    for (FLEXRecommendation *rec in recs) {
        FLEXSingleRowSection *section = [[FLEXSingleRowSection alloc] initWithTitle:rec.title
                                                                           reuseIdentifier:kFLEXDefaultCell
                                                                          cellConfiguration:^ (FLEXTableViewCell *cell) {
            cell.titleLabel.text = rec.title;
            cell.titleLabel.font = UIFont.flex_defaultTableCellFont;
        }];
        section.selectionAction = ^(__kindof UIViewController *host) {
            [[FLEXManager sharedManager] showExplorerForObject:rec.relevantObject];
        };
        [customSections addObject:section];
    }
}

@end

NS_ASSUME_NONNULL_END