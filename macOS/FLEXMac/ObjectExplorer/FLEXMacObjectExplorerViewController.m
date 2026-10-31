//
//  FLEXMacObjectExplorerViewController.m
//  FLEX (macOS)
//

#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacEditorViewControllers.h"
#import "FLEXMacObjectListViewController.h"
#import "FLEXMacShortcuts.h"
#import "FLEXMacUtility.h"
#import "FLEXMirror.h"
#import "FLEXProperty.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXIvar.h"
#import "FLEXMethod.h"
#import "FLEXProtocol.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXTypeEncodingParser.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import "NSString+FLEX.h"
#import <objc/runtime.h>

static NSString * const kFLEXMacExplorerIncludeInheritedKey = @"com.flex.mac.explorer.includeInherited";
static NSString * const kFLEXMacExplorerShowPreviewsKey = @"com.flex.mac.explorer.showPreviews";

@interface FLEXMacObjectExplorerViewController ()
@property (nonatomic, readwrite) id object;
@property (nonatomic) BOOL objectIsClass;
@property (nonatomic) NSArray<Class> *classHierarchy;
@property (nonatomic) NSInteger scopeIndex;
@property (nonatomic) NSPopUpButton *scopePopup;
@property (nonatomic) NSButton *inheritedCheckbox;
@property (nonatomic) NSButton *previewsCheckbox;
@end

@implementation FLEXMacObjectExplorerViewController

+ (instancetype)explorerForObject:(id)object {
    if (!object) {
        return nil;
    }

    FLEXMacObjectExplorerViewController *explorer = [self new];
    explorer.object = object;
    explorer.objectIsClass = object_isClass(object);
    explorer.classHierarchy = [FLEXRuntimeUtility classHierarchyOfObject:object];
    explorer.showsRefreshButton = YES;
    explorer.searchPlaceholder = @"Filter properties, ivars, methods…";

    NSString *className = [FLEXRuntimeUtility safeClassNameForObject:object];
    explorer.title = explorer.objectIsClass ?
        [NSString stringWithFormat:@"%@ (class)", NSStringFromClass(object)] :
        [NSString stringWithFormat:@"%@ %p", className, (__bridge void *)object];

    [NSUserDefaults.standardUserDefaults registerDefaults:@{
        kFLEXMacExplorerIncludeInheritedKey: @NO,
        kFLEXMacExplorerShowPreviewsKey: @YES,
    }];
    return explorer;
}

- (void)viewDidLoad {
    self.headerAccessoryView = [self makeScopeControls];
    [super viewDidLoad];
}

#pragma mark Scope controls

- (NSView *)makeScopeControls {
    self.scopePopup = [NSPopUpButton new];
    self.scopePopup.controlSize = NSControlSizeSmall;
    self.scopePopup.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    for (Class cls in self.classHierarchy) {
        [self.scopePopup addItemWithTitle:NSStringFromClass(cls)];
    }
    self.scopePopup.target = self;
    self.scopePopup.action = @selector(scopeChanged:);
    self.scopePopup.toolTip = @"The class whose members are listed";

    self.inheritedCheckbox = [NSButton checkboxWithTitle:@"Include superclasses" target:self action:@selector(scopeChanged:)];
    self.inheritedCheckbox.controlSize = NSControlSizeSmall;
    self.inheritedCheckbox.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    self.inheritedCheckbox.state = [NSUserDefaults.standardUserDefaults boolForKey:kFLEXMacExplorerIncludeInheritedKey];

    self.previewsCheckbox = [NSButton checkboxWithTitle:@"Value previews" target:self action:@selector(scopeChanged:)];
    self.previewsCheckbox.controlSize = NSControlSizeSmall;
    self.previewsCheckbox.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    self.previewsCheckbox.toolTip = @"Call property getters to show their values";
    self.previewsCheckbox.state = [NSUserDefaults.standardUserDefaults boolForKey:kFLEXMacExplorerShowPreviewsKey];

    NSTextField *label = [NSTextField labelWithString:@"Class:"];
    label.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];

    NSStackView *stack = [NSStackView stackViewWithViews:@[
        label, self.scopePopup, self.inheritedCheckbox, self.previewsCheckbox
    ]];
    stack.spacing = 8;
    return stack;
}

- (void)scopeChanged:(id)sender {
    self.scopeIndex = MAX(0, self.scopePopup.indexOfSelectedItem);
    [NSUserDefaults.standardUserDefaults setBool:self.includeInherited forKey:kFLEXMacExplorerIncludeInheritedKey];
    [NSUserDefaults.standardUserDefaults setBool:self.showsPreviews forKey:kFLEXMacExplorerShowPreviewsKey];
    [self reloadData];
}

- (BOOL)includeInherited {
    return self.inheritedCheckbox.state == NSControlStateValueOn;
}

- (BOOL)showsPreviews {
    return self.previewsCheckbox.state == NSControlStateValueOn;
}

/// The classes whose members are shown
- (NSArray<Class> *)scopedClasses {
    if (!self.classHierarchy.count) {
        return @[];
    }
    NSInteger index = MIN(self.scopeIndex, (NSInteger)self.classHierarchy.count - 1);
    if (self.includeInherited) {
        return [self.classHierarchy subarrayWithRange:NSMakeRange(index, self.classHierarchy.count - index)];
    }
    return @[self.classHierarchy[index]];
}

#pragma mark Sections

- (NSArray<FLEXMacSection *> *)makeSections {
    NSMutableArray<FLEXMacSection *> *sections = [NSMutableArray new];
    [sections addObject:[self descriptionSection]];

    NSArray<FLEXMacSection *> *shortcuts = [FLEXMacShortcuts sectionsForObject:self.object];
    [sections addObjectsFromArray:shortcuts];

    // Reflect each class in scope once
    NSMutableArray<FLEXMirror *> *mirrors = [NSMutableArray new];
    for (Class cls in self.scopedClasses) {
        [mirrors addObject:[FLEXMirror reflect:cls]];
    }

    NSString *suffix = self.includeInherited ? @"" : [NSString stringWithFormat:@" — %@", NSStringFromClass(self.scopedClasses.firstObject)];

    [self addSection:[@"Properties" stringByAppendingString:suffix]
                rows:[self propertyRowsFromMirrors:mirrors classProperties:NO] to:sections];
    [self addSection:[@"Class Properties" stringByAppendingString:suffix]
                rows:[self propertyRowsFromMirrors:mirrors classProperties:YES] to:sections];
    [self addSection:[@"Ivars" stringByAppendingString:suffix]
                rows:[self ivarRowsFromMirrors:mirrors] to:sections];
    [self addSection:[@"Methods" stringByAppendingString:suffix]
                rows:[self methodRowsFromMirrors:mirrors classMethods:NO] to:sections];
    [self addSection:[@"Class Methods" stringByAppendingString:suffix]
                rows:[self methodRowsFromMirrors:mirrors classMethods:YES] to:sections];
    [self addSection:@"Class Hierarchy" rows:[self hierarchyRows] to:sections];
    [self addSection:[@"Protocols" stringByAppendingString:suffix]
                rows:[self protocolRowsFromMirrors:mirrors] to:sections];
    [self addSection:@"Miscellaneous" rows:[self miscRows] to:sections];

    return sections;
}

- (void)addSection:(NSString *)title rows:(NSArray<FLEXMacRow *> *)rows to:(NSMutableArray *)sections {
    if (rows.count) {
        [sections addObject:[FLEXMacSection title:[NSString stringWithFormat:@"%@ (%lu)", title, (unsigned long)rows.count] rows:rows]];
    }
}

- (FLEXMacSection *)descriptionSection {
    id object = self.object;
    NSString *description = [FLEXRuntimeUtility safeDescriptionForObject:object] ?: @"nil";
    FLEXMacRow *descriptionRow = [FLEXMacRow title:@"Description" subtitle:description];
    descriptionRow.subtitleMaxLines = 12;
    descriptionRow.copyString = description;

    NSMutableArray *rows = [NSMutableArray arrayWithObject:descriptionRow];

    if (!self.objectIsClass) {
        Class cls = object_getClass(object);
        [rows addObject:[FLEXMacRow title:@"Class" subtitle:NSStringFromClass(cls) exploring:cls]];
    }

    FLEXMacRow *address = [FLEXMacRow title:@"Address" subtitle:[NSString stringWithFormat:@"%p", (__bridge void *)object]];
    address.copyString = address.subtitle;
    [rows addObject:address];

    return [FLEXMacSection title:@"Object" rows:rows];
}

#pragma mark Properties

- (id)targetForProperty:(FLEXProperty *)property {
    if (property.isClassProperty) {
        return self.objectIsClass ? self.object : [self.object class];
    }
    return self.objectIsClass ? nil : self.object;
}

- (NSArray<FLEXMacRow *> *)propertyRowsFromMirrors:(NSArray<FLEXMirror *> *)mirrors classProperties:(BOOL)classProperties {
    NSMutableArray *rows = [NSMutableArray new];
    NSMutableSet *seen = [NSMutableSet new];
    BOOL previews = self.showsPreviews;

    for (FLEXMirror *mirror in mirrors) {
        NSArray<FLEXProperty *> *properties = classProperties ? mirror.classProperties : mirror.properties;
        properties = [properties sortedArrayUsingComparator:^NSComparisonResult(FLEXProperty *a, FLEXProperty *b) {
            return [a.name caseInsensitiveCompare:b.name];
        }];

        for (FLEXProperty *property in properties) {
            // Subclasses often redeclare properties; show the most specific one
            if ([seen containsObject:property.name]) {
                continue;
            }
            [seen addObject:property.name];
            [rows addObject:[self rowForProperty:property previews:previews]];
        }
    }
    return rows;
}

- (FLEXMacRow *)rowForProperty:(FLEXProperty *)property previews:(BOOL)previews {
    id target = [self targetForProperty:property];
    NSString *typeEncoding = property.attributes.typeEncoding;
    NSString *type = [FLEXRuntimeUtility readableTypeForEncoding:typeEncoding] ?: typeEncoding;
    BOOL returnsObject = typeEncoding.flex_typeIsObjectOrClass;

    FLEXMacRow *row = [FLEXMacRow title:property.name];
    row.copyString = property.fullDescription;

    __block id value = nil;
    __block BOOL valueLoaded = NO;
    id (^currentValue)(void) = ^id {
        if (!valueLoaded) {
            value = [property getPotentiallyUnboxedValue:target];
            valueLoaded = YES;
        }
        return value;
    };

    if (!target) {
        row.subtitle = property.fullDescription;
    } else if (previews) {
        row.subtitle = [NSString stringWithFormat:@"%@ = %@", type,
            [FLEXMacUtility summaryForObject:currentValue() type:typeEncoding maxLength:400]
        ];
    } else {
        row.subtitle = type;
    }

    BOOL editable = target && [FLEXMacFieldEditorViewController canEditProperty:property target:target];
    __weak typeof(self) weakSelf = self;

    if (target) {
        row.viewControllerProvider = ^NSViewController *{
            id current = [property getPotentiallyUnboxedValue:target];
            if (returnsObject && current) {
                return [FLEXMacObjectExplorerViewController explorerForObject:current];
            }
            if (editable) {
                return [FLEXMacFieldEditorViewController editorForProperty:property target:target commit:^{
                    [weakSelf reloadData];
                }];
            }
            // Explore boxed primitives too, such as structs
            return [FLEXMacObjectExplorerViewController explorerForObject:current];
        };
    }

    row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
        NSMutableArray *items = [NSMutableArray new];
        if (editable) {
            [items addObject:FLEXMacMenuItem(@"Edit Value…", ^{
                [host flex_push:[FLEXMacFieldEditorViewController editorForProperty:property target:target commit:^{
                    [weakSelf reloadData];
                }]];
            })];
        }
        if (target) {
            [items addObject:FLEXMacMenuItem(@"Copy Value", ^{
                [FLEXMacUtility copyToPasteboard:[FLEXRuntimeUtility safeDescriptionForObject:
                    [property getPotentiallyUnboxedValue:target]
                ]];
            })];
            if (returnsObject) {
                [items addObject:FLEXMacMenuItem(@"Copy Value Address", ^{
                    id current = [property getValue:target];
                    [FLEXMacUtility copyToPasteboard:[NSString stringWithFormat:@"%p", (__bridge void *)current]];
                })];
                [items addObject:FLEXMacMenuItem(@"List All References to Value", ^{
                    id current = [property getValue:target];
                    if (current) {
                        [host flex_push:[FLEXMacObjectListViewController objectsWithReferencesToObject:current]];
                    }
                })];
            }
        }
        Class propertyClass = returnsObject ? typeEncoding.flex_typeClass : nil;
        if (propertyClass) {
            [items addObject:FLEXMacMenuItem([NSString stringWithFormat:@"Explore %@", NSStringFromClass(propertyClass)], ^{
                [host flex_push:[FLEXMacObjectExplorerViewController explorerForObject:propertyClass]];
            })];
        }
        [items addObject:FLEXMacMenuItem(@"Copy Declaration", ^{
            [FLEXMacUtility copyToPasteboard:property.fullDescription];
        })];
        [items addObject:FLEXMacMenuItem(@"Copy Name", ^{
            [FLEXMacUtility copyToPasteboard:property.name];
        })];
        return items;
    };

    return row;
}

#pragma mark Ivars

- (NSArray<FLEXMacRow *> *)ivarRowsFromMirrors:(NSArray<FLEXMirror *> *)mirrors {
    NSMutableArray *rows = [NSMutableArray new];
    id target = self.objectIsClass ? nil : self.object;

    for (FLEXMirror *mirror in mirrors) {
        for (FLEXIvar *ivar in mirror.ivars) {
            [rows addObject:[self rowForIvar:ivar target:target]];
        }
    }
    return rows;
}

- (FLEXMacRow *)rowForIvar:(FLEXIvar *)ivar target:(id)target {
    NSString *type = [FLEXRuntimeUtility readableTypeForEncoding:ivar.typeEncoding] ?: ivar.typeEncoding;
    BOOL isObject = ivar.type == FLEXTypeEncodingObjcObject || ivar.type == FLEXTypeEncodingObjcClass;

    FLEXMacRow *row = [FLEXMacRow title:ivar.name];
    row.copyString = ivar.description;

    if (target) {
        id value = [ivar getPotentiallyUnboxedValue:target];
        row.subtitle = [NSString stringWithFormat:@"%@ = %@", type, [FLEXMacUtility summaryForObject:value type:ivar.typeEncoding maxLength:400]];
    } else {
        row.subtitle = [NSString stringWithFormat:@"%@  (offset %ld)", type, (long)ivar.offset];
    }

    BOOL editable = [FLEXMacFieldEditorViewController canEditIvar:ivar target:target];
    __weak typeof(self) weakSelf = self;

    if (target) {
        row.viewControllerProvider = ^NSViewController *{
            id current = [ivar getPotentiallyUnboxedValue:target];
            if (isObject && current) {
                return [FLEXMacObjectExplorerViewController explorerForObject:current];
            }
            if (editable) {
                return [FLEXMacFieldEditorViewController editorForIvar:ivar target:target commit:^{
                    [weakSelf reloadData];
                }];
            }
            return [FLEXMacObjectExplorerViewController explorerForObject:current];
        };
    }

    row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
        NSMutableArray *items = [NSMutableArray new];
        if (editable) {
            [items addObject:FLEXMacMenuItem(@"Edit Value…", ^{
                [host flex_push:[FLEXMacFieldEditorViewController editorForIvar:ivar target:target commit:^{
                    [weakSelf reloadData];
                }]];
            })];
        }
        if (target) {
            [items addObject:FLEXMacMenuItem(@"Copy Value", ^{
                [FLEXMacUtility copyToPasteboard:[FLEXRuntimeUtility safeDescriptionForObject:
                    [ivar getPotentiallyUnboxedValue:target]
                ]];
            })];
        }
        [items addObject:FLEXMacMenuItem(@"Copy Declaration", ^{
            [FLEXMacUtility copyToPasteboard:ivar.description];
        })];
        return items;
    };

    return row;
}

#pragma mark Methods

- (NSArray<FLEXMacRow *> *)methodRowsFromMirrors:(NSArray<FLEXMirror *> *)mirrors classMethods:(BOOL)classMethods {
    NSMutableArray *rows = [NSMutableArray new];
    NSMutableSet *seen = [NSMutableSet new];

    // Instance methods can only be called on instances
    id target = classMethods ? (self.objectIsClass ? self.object : [self.object class]) :
        (self.objectIsClass ? nil : self.object);

    for (FLEXMirror *mirror in mirrors) {
        NSArray<FLEXMethod *> *methods = classMethods ? mirror.classMethods : mirror.methods;
        methods = [methods sortedArrayUsingComparator:^NSComparisonResult(FLEXMethod *a, FLEXMethod *b) {
            return [a.selectorString caseInsensitiveCompare:b.selectorString];
        }];

        for (FLEXMethod *method in methods) {
            if ([seen containsObject:method.selectorString]) {
                continue;
            }
            [seen addObject:method.selectorString];

            FLEXMacRow *row = [FLEXMacRow title:method.selectorString subtitle:method.description];
            row.monospaced = YES;
            row.copyString = method.description;
            if (target) {
                row.viewControllerProvider = ^NSViewController *{
                    return [FLEXMacMethodCallViewController callerForMethod:method target:target];
                };
            }
            row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
                return @[
                    FLEXMacMenuItem(@"Copy Selector", ^{
                        [FLEXMacUtility copyToPasteboard:method.selectorString];
                    }),
                    FLEXMacMenuItem(@"Copy Signature", ^{
                        [FLEXMacUtility copyToPasteboard:method.signatureString];
                    }),
                    FLEXMacMenuItem(@"Copy Implementation Address", ^{
                        [FLEXMacUtility copyToPasteboard:[NSString stringWithFormat:@"%p", (void *)method.implementation]];
                    }),
                    FLEXMacMenuItem(@"Copy Image Path", ^{
                        [FLEXMacUtility copyToPasteboard:method.imagePath];
                    }),
                ];
            };
            [rows addObject:row];
        }
    }
    return rows;
}

#pragma mark Hierarchy & Protocols

- (NSArray<FLEXMacRow *> *)hierarchyRows {
    NSMutableArray *rows = [NSMutableArray new];
    NSUInteger depth = 0;
    for (Class cls in self.classHierarchy) {
        NSString *indent = [@"" stringByPaddingToLength:depth * 2 withString:@" " startingAtIndex:0];
        NSString *image = @(class_getImageName(cls) ?: "").lastPathComponent;
        FLEXMacRow *row = [FLEXMacRow
            title:[indent stringByAppendingString:NSStringFromClass(cls)]
            subtitle:image.length ? image : nil
            exploring:cls
        ];
        row.monospaced = YES;
        [rows addObject:row];
        depth++;
    }
    return rows;
}

- (NSArray<FLEXMacRow *> *)protocolRowsFromMirrors:(NSArray<FLEXMirror *> *)mirrors {
    NSMutableArray *rows = [NSMutableArray new];
    NSMutableSet *seen = [NSMutableSet new];
    for (FLEXMirror *mirror in mirrors) {
        for (FLEXProtocol *protocol in mirror.protocols) {
            if ([seen containsObject:protocol.name]) {
                continue;
            }
            [seen addObject:protocol.name];
            [rows addObject:[FLEXMacRow title:protocol.name subtitle:protocol.imagePath.lastPathComponent pushing:^NSViewController *{
                return [FLEXMacObjectExplorerViewController protocolViewerFor:protocol];
            }]];
        }
    }
    return rows;
}

+ (NSViewController *)protocolViewerFor:(FLEXProtocol *)protocol {
    FLEXMacTableViewController *viewer = [FLEXMacTableViewController new];
    viewer.title = [NSString stringWithFormat:@"@protocol %@", protocol.name];

    NSArray<FLEXMacRow *> *(^methodRows)(NSArray<FLEXMethodDescription *> *) = ^(NSArray<FLEXMethodDescription *> *methods) {
        NSMutableArray *rows = [NSMutableArray new];
        for (FLEXMethodDescription *method in methods) {
            NSString *prefix = method.instance.boolValue ? @"-" : @"+";
            FLEXMacRow *row = [FLEXMacRow
                title:[NSString stringWithFormat:@"%@ %@", prefix, NSStringFromSelector(method.selector)]
                subtitle:method.typeEncoding
            ];
            row.monospaced = YES;
            [rows addObject:row];
        }
        return rows;
    };

    NSArray<FLEXMacRow *> *(^propertyRows)(NSArray<FLEXProperty *> *) = ^(NSArray<FLEXProperty *> *properties) {
        NSMutableArray *rows = [NSMutableArray new];
        for (FLEXProperty *property in properties) {
            [rows addObject:[FLEXMacRow title:property.name subtitle:property.fullDescription]];
        }
        return rows;
    };

    NSMutableArray *conformances = [NSMutableArray new];
    for (FLEXProtocol *parent in protocol.protocols) {
        FLEXMacRow *row = [FLEXMacRow title:parent.name subtitle:nil pushing:^NSViewController *{
            return [self protocolViewerFor:parent];
        }];
        [conformances addObject:row];
    }

    NSMutableArray *sections = [NSMutableArray new];
    for (FLEXMacSection *section in @[
        [FLEXMacSection title:@"Required Methods" rows:methodRows(protocol.requiredMethods)],
        [FLEXMacSection title:@"Optional Methods" rows:methodRows(protocol.optionalMethods)],
        [FLEXMacSection title:@"Required Properties" rows:propertyRows(protocol.requiredProperties)],
        [FLEXMacSection title:@"Optional Properties" rows:propertyRows(protocol.optionalProperties)],
        [FLEXMacSection title:@"Conforms To" rows:conformances],
        [FLEXMacSection title:@"Image" rows:@[[FLEXMacRow title:protocol.imagePath ?: @"Unknown"]]],
    ]) {
        if (section.rows.count) {
            [sections addObject:section];
        }
    }
    viewer.sections = sections;
    return viewer;
}

#pragma mark Misc

- (NSArray<FLEXMacRow *> *)miscRows {
    NSMutableArray *rows = [NSMutableArray new];
    id object = self.object;
    Class cls = self.objectIsClass ? object : object_getClass(object);
    NSString *className = NSStringFromClass(cls);

    [rows addObject:[FLEXMacRow title:@"Instance Size" subtitle:[NSString stringWithFormat:@"%zu bytes", class_getInstanceSize(cls)]]];
    NSString *image = @(class_getImageName(cls) ?: "Unknown");
    FLEXMacRow *imageRow = [FLEXMacRow title:@"Image" subtitle:image];
    imageRow.copyString = image;
    [rows addObject:imageRow];

    if (self.objectIsClass) {
        [rows addObject:[FLEXMacRow title:@"Live Instances" subtitle:@"Scan the heap for instances of this class" pushing:^NSViewController *{
            return [FLEXMacObjectListViewController instancesOfClassWithName:className];
        }]];
        [rows addObject:[FLEXMacRow title:@"Subclasses" subtitle:@"All loaded subclasses of this class" pushing:^NSViewController *{
            return [FLEXMacObjectListViewController subclassesOfClassWithName:className];
        }]];
        [rows addObject:[FLEXMacRow title:@"Metaclass" subtitle:nil exploring:object_getClass(cls)]];
    } else {
        [rows addObject:[FLEXMacRow title:@"Other Objects Referencing This Object" subtitle:@"Scan the heap for references" pushing:^NSViewController *{
            return [FLEXMacObjectListViewController objectsWithReferencesToObject:object];
        }]];
    }

    return rows;
}

@end
