//
//  FLEXMacObjectListViewController.m
//  FLEX (macOS)
//

#import "FLEXMacObjectListViewController.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacUtility.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import "FLEXRuntimeUtility.h"

@interface FLEXMacObjectListViewController ()
@property (nonatomic) NSArray<FLEXObjectRef *> *references;
@end

@implementation FLEXMacObjectListViewController

+ (instancetype)listWithTitle:(NSString *)title references:(NSArray<FLEXObjectRef *> *)references {
    FLEXMacObjectListViewController *list = [self new];
    list.title = title;
    list.references = references ?: @[];
    list.emptyText = @"No objects";
    return list;
}

+ (instancetype)listWithTitle:(NSString *)title objects:(NSArray *)objects {
    return [self listWithTitle:title references:[FLEXObjectRef referencingAll:objects retained:YES]];
}

+ (instancetype)instancesOfClassWithName:(NSString *)className {
    NSArray *references = [FLEXHeapEnumerator instancesOfClassWithName:className retained:YES];
    NSString *title = [NSString stringWithFormat:@"%@ (%lu)", className, (unsigned long)references.count];
    FLEXMacObjectListViewController *list = [self listWithTitle:title references:references];
    list.emptyText = [NSString stringWithFormat:@"No live instances of %@", className];
    return list;
}

+ (instancetype)subclassesOfClassWithName:(NSString *)className {
    NSArray *references = [FLEXRuntimeUtility subclassesOfClassWithName:className];
    references = [references sortedArrayUsingComparator:^NSComparisonResult(FLEXObjectRef *a, FLEXObjectRef *b) {
        return [a.reference caseInsensitiveCompare:b.reference];
    }];
    NSString *title = [NSString stringWithFormat:@"Subclasses of %@ (%lu)", className, (unsigned long)references.count];
    FLEXMacObjectListViewController *list = [self listWithTitle:title references:references];
    list.emptyText = @"No subclasses";
    return list;
}

+ (instancetype)objectsWithReferencesToObject:(id)object {
    NSArray *references = [FLEXHeapEnumerator objectsWithReferencesToObject:object retained:YES];
    NSString *title = [NSString stringWithFormat:@"References to %@ %p",
        [FLEXRuntimeUtility safeClassNameForObject:object], (__bridge void *)object
    ];
    FLEXMacObjectListViewController *list = [self listWithTitle:title references:references];
    list.emptyText = @"No objects reference this object";
    return list;
}

- (NSArray<FLEXMacSection *> *)makeSections {
    NSMutableArray *rows = [NSMutableArray new];
    for (FLEXObjectRef *ref in self.references) {
        FLEXMacRow *row = [FLEXMacRow title:ref.reference subtitle:ref.summary exploring:ref.object];
        row.subtitleMaxLines = 2;
        [rows addObject:row];
    }
    return @[[FLEXMacSection title:nil rows:rows]];
}

@end
