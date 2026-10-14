//
//  FLEXSwiftUIInspector.m
//  FLEX
//
//  Created by Ethan Park on 10/13/26.
//  Copyright (c) 2026 FLEX Team. All rights reserved.
//

#import "FLEXSwiftUIInspector.h"
#import "FLEXUtility.h"
#import "FLEXMacros.h"
#import "NSUserDefaults+FLEX.h"
#import <objc/message.h>

#pragma mark - Safe access

// Everything read here comes from private API whose shape can change between iOS
// versions, so every value is checked before use.

static NSDictionary *FLEXDictionary(id value) {
    return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

static NSArray *FLEXArray(id value) {
    return [value isKindOfClass:[NSArray class]] ? value : nil;
}

static NSString *FLEXString(id value) {
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSNumber *FLEXNumber(id value) {
    return [value isKindOfClass:[NSNumber class]] ? value : nil;
}

static id FLEXSendIfResponds(id target, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) {
        return nil;
    }

    return ((id (*)(id, SEL))objc_msgSend)(target, selector);
}

#pragma mark - Type names

/// "SwiftUI.VStack<…>" → "SwiftUI"
static NSString *FLEXModuleName(NSString *type) {
    NSRange dot = [type rangeOfString:@"."];
    NSRange generic = [type rangeOfString:@"<"];
    if (dot.location == NSNotFound || (generic.location != NSNotFound && generic.location < dot.location)) {
        return nil;
    }

    return [type substringToIndex:dot.location];
}

/// \c YES for a type the app or its packages defined, as opposed to SwiftUI, the
/// standard library, or the SwiftUI overlays of Apple's frameworks.
static BOOL FLEXIsCustomType(NSString *type) {
    NSString *module = [type hasPrefix:@"("] ? nil : FLEXModuleName(type);
    if (!module || [module hasPrefix:@"_"]) {
        return NO;
    }

    static NSSet<NSString *> *appleModules = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appleModules = [NSSet setWithArray:@[
            @"SwiftUI", @"SwiftUICore", @"Swift", @"__C", @"Foundation", @"UIKit", @"CoreGraphics",
            @"Charts", @"MapKit", @"AVKit", @"PhotosUI", @"StoreKit", @"WidgetKit", @"ActivityKit",
            @"TipKit", @"WebKit", @"SafariServices", @"QuickLook", @"RealityKit", @"SceneKit",
            @"SpriteKit", @"AuthenticationServices", @"HealthKitUI", @"LinkPresentation",
            @"MessageUI", @"PassKit", @"SwiftData", @"CoreData", @"Combine", @"Observation",
        ]];
    });

    return ![appleModules containsObject:module];
}

/// "FLEXample.AView" → "AView"
static NSString *FLEXDisplayName(NSString *type) {
    NSRange dot = [type rangeOfString:@"."];
    return dot.location == NSNotFound ? type : [type substringFromIndex:dot.location + 1];
}

/// "SwiftUI.Button<SwiftUI.Text>" → "Button"
static NSString *FLEXBaseName(NSString *type) {
    NSString *name = FLEXDisplayName(type);
    NSRange generic = [name rangeOfString:@"<"];
    return generic.location == NSNotFound ? name : [name substringToIndex:generic.location];
}

/// Splits "A, B<C, D>, (E, F)" at its top-level commas.
static NSArray<NSString *> *FLEXSplitTopLevel(NSString *list) {
    NSMutableArray<NSString *> *parts = [NSMutableArray new];
    NSInteger depth = 0, start = 0;
    NSCharacterSet *space = NSCharacterSet.whitespaceCharacterSet;

    for (NSInteger i = 0; i < list.length; i++) {
        unichar c = [list characterAtIndex:i];
        if (c == '<' || c == '(') {
            depth++;
        } else if (c == '>' || c == ')') {
            depth--;
        } else if (c == ',' && depth == 0) {
            [parts addObject:[[list substringWithRange:NSMakeRange(start, i - start)] stringByTrimmingCharactersInSet:space]];
            start = i + 1;
        }
    }

    [parts addObject:[[list substringFromIndex:start] stringByTrimmingCharactersInSet:space]];
    return parts;
}

/// The generic arguments of \c type when it is an instance of \c generic, such as
/// "SwiftUI.ModifiedContent".
static NSArray<NSString *> *FLEXGenericArguments(NSString *type, NSString *generic) {
    NSString *prefix = [generic stringByAppendingString:@"<"];
    if (![type hasPrefix:prefix] || ![type hasSuffix:@">"]) {
        return nil;
    }

    return FLEXSplitTopLevel([type substringWithRange:NSMakeRange(prefix.length, type.length - prefix.length - 1)]);
}

/// The public name of a SwiftUI container such as "VStack", or nil.
static NSString *FLEXContainerName(NSString *type) {
    if (![type hasPrefix:@"SwiftUI."]) {
        return nil;
    }

    static NSSet<NSString *> *containers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        containers = [NSSet setWithArray:@[
            @"VStack", @"HStack", @"ZStack", @"LazyVStack", @"LazyHStack", @"LazyVGrid", @"LazyHGrid",
            @"Grid", @"GridRow", @"ScrollView", @"List", @"Form", @"Section", @"NavigationStack",
            @"NavigationSplitView", @"NavigationView", @"TabView", @"GeometryReader", @"ViewThatFits",
        ]];
    });

    NSString *base = FLEXBaseName(type);
    return [containers containsObject:base] ? base : nil;
}

/// The public name of a SwiftUI component such as "Text" or "Button", or nil. A shape
/// view is named for its shape.
static NSString *FLEXComponentName(NSString *type, BOOL *isControl) {
    *isControl = NO;
    if (![type hasPrefix:@"SwiftUI."]) {
        return nil;
    }

    static NSSet<NSString *> *controls = nil;
    static NSSet<NSString *> *primitives = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controls = [NSSet setWithArray:@[
            @"Button", @"Toggle", @"Link", @"NavigationLink", @"Menu", @"Picker", @"Stepper",
            @"Slider", @"TextField", @"SecureField", @"Label", @"ShareLink", @"DatePicker",
            @"ColorPicker", @"ProgressView", @"Gauge",
        ]];
        primitives = [NSSet setWithArray:@[@"Text", @"Image", @"Color", @"Divider", @"Spacer"]];
    });

    NSString *base = FLEXBaseName(type);
    if ([controls containsObject:base]) {
        *isControl = YES;
        return base;
    }

    if ([primitives containsObject:base]) {
        return base;
    }

    // "SwiftUI._ShapeView<SwiftUI.RoundedRectangle, SwiftUI.Color>" → "RoundedRectangle"
    NSString *shape = FLEXGenericArguments(type, @"SwiftUI._ShapeView").firstObject;
    return shape ? FLEXBaseName(shape) : nil;
}

#pragma mark - View debug JSON

// Each node lists properties by the raw value of SwiftUI's public _ViewDebug.Property:
// 0 is the view's type, 3 its position and 4 its size. Positions are in the coordinate
// space of the node's layout container rather than the hosting view.

static NSDictionary *FLEXJSONProperty(NSDictionary *node, NSInteger identifier) {
    for (id property in FLEXArray(node[@"properties"])) {
        NSNumber *propertyID = FLEXNumber(FLEXDictionary(property)[@"id"]);
        if (propertyID && propertyID.integerValue == identifier) {
            return FLEXDictionary(FLEXDictionary(property)[@"attribute"]);
        }
    }

    return nil;
}

static NSString *FLEXJSONType(NSDictionary *node) {
    return FLEXString(FLEXJSONProperty(node, 0)[@"type"]);
}

static NSArray<NSDictionary *> *FLEXJSONChildren(NSDictionary *node) {
    NSMutableArray<NSDictionary *> *children = [NSMutableArray new];
    for (id child in FLEXArray(node[@"children"])) {
        if (FLEXDictionary(child)) {
            [children addObject:child];
        }
    }

    return children;
}

static BOOL FLEXJSONFrame(NSDictionary *node, CGRect *frame) {
    NSArray *position = FLEXArray(FLEXJSONProperty(node, 3)[@"value"]);
    NSArray *size = FLEXArray(FLEXJSONProperty(node, 4)[@"value"]);
    if (position.count != 2 || size.count != 2) {
        return NO;
    }

    NSNumber *x = FLEXNumber(position[0]), *y = FLEXNumber(position[1]);
    NSNumber *width = FLEXNumber(size[0]), *height = FLEXNumber(size[1]);
    if (!x || !y || !width || !height) {
        return NO;
    }

    *frame = CGRectMake(x.doubleValue, y.doubleValue, width.doubleValue, height.doubleValue);
    return YES;
}

/// The string a JSON \c Text node shows: the verbatim string or localization key in
/// its storage, wherever it is nested.
static NSString *FLEXJSONTextString(id value) {
    NSDictionary *dictionary = FLEXDictionary(value);
    NSString *name = FLEXString(dictionary[@"name"]);
    if (([name isEqualToString:@"verbatim"] || [name isEqualToString:@"key"]) && FLEXString(dictionary[@"value"])) {
        return dictionary[@"value"];
    }

    for (id child in dictionary ? dictionary.allValues : FLEXArray(value)) {
        NSString *found = FLEXJSONTextString(child);
        if (found) {
            return found;
        }
    }

    return nil;
}

#pragma mark - Geometry

static BOOL FLEXSizesMatch(CGSize a, CGSize b) {
    return fabs(a.width - b.width) <= 1 && fabs(a.height - b.height) <= 1;
}

static BOOL FLEXPointsMatch(CGPoint a, CGPoint b) {
    return fabs(a.x - b.x) <= 1.5 && fabs(a.y - b.y) <= 1.5;
}

static BOOL FLEXRectContainsRect(CGRect outer, CGRect inner) {
    return CGRectContainsRect(CGRectInset(outer, -1.5, -1.5), inner);
}

#pragma mark - FLEXSwiftUIViewNode

@interface FLEXSwiftUIViewNode ()
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *typeName;
@property (nonatomic, readwrite) FLEXSwiftUIViewKind kind;
@property (nonatomic, readwrite, nullable) NSString *enclosingName;
@property (nonatomic, readwrite, weak) UIView *hostingView;
@property (nonatomic, readwrite, weak, nullable) FLEXSwiftUIViewNode *parent;
@property (nonatomic) NSMutableArray<FLEXSwiftUIViewNode *> *mutableChildren;
@property (nonatomic, readwrite) CGRect frameInHostingView;
@property (nonatomic) BOOL isControl;
@end

@implementation FLEXSwiftUIViewNode

- (NSArray<FLEXSwiftUIViewNode *> *)children {
    return self.mutableChildren;
}

- (CGRect)frameInWindow {
    if (CGRectIsNull(self.frameInHostingView) || !self.hostingView.window) {
        return CGRectNull;
    }

    return [self.hostingView convertRect:self.frameInHostingView toView:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@ %@>", NSStringFromClass(self.class), self.typeName,
        NSStringFromCGRect(self.frameInHostingView)];
}

@end

#pragma mark - Snapshot

// SwiftUI exposes its view tree for debugging in two forms:
//
// - The view debug JSON has every laid-out node, with its frame, nested the way it is
//   drawn: a background or padding wraps the view it applies to. But it leaves out custom
//   views and controls such as Button, and gives internal types in their place.
// - The accessibility debug tree names every view, including custom views and controls,
//   and lists what each contains. It lists a node twice, by its graph attribute: where it
//   is laid out, and under the view that declared it. It has no geometry, and it puts a
//   background beside the view rather than around it.
//
// Matching the two by type joins names to JSON nodes. The tree is then the JSON nesting,
// with each named view that has no JSON node of its own placed around what it contains.

/// Everything read from one hosting view, read once and reused until invalidated.
@interface FLEXSwiftUISnapshot : NSObject
/// @param outer The snapshot of the hosting view this one is inside, if any.
- (instancetype)initWithHostingView:(UIView *)hostingView
                      previousNodes:(NSDictionary *)previousNodes
                              outer:(FLEXSwiftUISnapshot *)outer;
@property (nonatomic, readonly) NSArray<FLEXSwiftUIViewNode *> *roots;
@property (nonatomic, readonly) NSDictionary<NSString *, FLEXSwiftUIViewNode *> *nodesByKey;
- (FLEXSwiftUIViewNode *)nodeForLayerFrame:(CGRect)frame;
@end

@implementation FLEXSwiftUISnapshot {
    __weak UIView *_hostingView;
    CGPoint _hostOriginOnScreen;
    NSDictionary<NSString *, FLEXSwiftUIViewNode *> *_previousNodes;

    // Accessibility tree, by node key
    NSMutableDictionary<NSString *, NSMutableOrderedSet<NSString *> *> *_parents;
    NSMutableDictionary<NSString *, NSMutableOrderedSet<NSString *> *> *_children;
    NSMutableDictionary<NSString *, NSString *> *_types;
    NSMutableArray<NSDictionary *> *_elements;
    // Screen frames of the accessibility elements in each node's subtree
    NSMutableDictionary<NSString *, NSValue *> *_elementFrames;

    // View debug JSON
    NSMapTable<NSDictionary *, NSValue *> *_offsets;
    NSMutableDictionary<NSString *, NSDictionary *> *_jsonNodes;
    NSHashTable<NSDictionary *> *_matchedJSONNodes;
    NSMutableArray<NSDictionary *> *_framed;
    NSMapTable<NSDictionary *, NSDictionary *> *_jsonParents;
    NSMapTable<NSDictionary *, NSValue *> *_hostFrames;
    NSMapTable<NSDictionary *, NSString *> *_jsonTypes;
    NSMapTable<NSDictionary *, NSNumber *> *_jsonRoles;
    NSMapTable<NSDictionary *, NSSet<NSString *> *> *_jsonTexts;
    NSMapTable<FLEXSwiftUIViewNode *, NSValue *> *_elementFramesOfNodes;

    // The tree of public and custom views
    NSMutableDictionary<NSString *, FLEXSwiftUIViewNode *> *_nodes;
    NSMapTable<NSDictionary *, FLEXSwiftUIViewNode *> *_nodesForAnchors;
    NSMutableArray<FLEXSwiftUIViewNode *> *_roots;
}

- (instancetype)initWithHostingView:(UIView *)hostingView
                      previousNodes:(NSDictionary *)previousNodes
                              outer:(FLEXSwiftUISnapshot *)outer {
    self = [super init];
    if (self) {
        _hostingView = hostingView;
        _hostOriginOnScreen = UIAccessibilityConvertFrameToScreenCoordinates(hostingView.bounds, hostingView).origin;
        _previousNodes = previousNodes ?: @{};
        _parents = [NSMutableDictionary new];
        _children = [NSMutableDictionary new];
        _types = [NSMutableDictionary new];
        _elements = [NSMutableArray new];
        _elementFrames = [NSMutableDictionary new];
        _offsets = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                         valueOptions:NSPointerFunctionsStrongMemory];
        _jsonNodes = [NSMutableDictionary new];
        _matchedJSONNodes = [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
        _framed = [NSMutableArray new];
        _jsonParents = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                             valueOptions:NSPointerFunctionsObjectPointerPersonality];
        _hostFrames = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                            valueOptions:NSPointerFunctionsStrongMemory];
        _jsonTypes = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                           valueOptions:NSPointerFunctionsStrongMemory];
        _jsonRoles = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                           valueOptions:NSPointerFunctionsStrongMemory];
        _jsonTexts = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                           valueOptions:NSPointerFunctionsStrongMemory];
        _elementFramesOfNodes = [NSMapTable strongToStrongObjectsMapTable];
        _roots = [NSMutableArray new];

        // Accessibility fills in its tree while the first read of a screen walks it, so
        // that read is repeated
        NSArray *accessibilityRoots = nil;
        NSInteger reads = _previousNodes.count ? 1 : 2;
        for (NSInteger read = 0; read < reads || (read < 2 && !_elements.count); read++) {
            [_parents removeAllObjects];
            [_children removeAllObjects];
            [_types removeAllObjects];
            [_elements removeAllObjects];
            [_elementFrames removeAllObjects];
            accessibilityRoots = FLEXArray(FLEXSendIfResponds(hostingView, @"_accessibilitySwiftUIDebugData"));
            for (id root in accessibilityRoots) {
                [self indexAccessibilityNode:root parent:nil];
            }
        }

        NSData *json = FLEXSendIfResponds(hostingView, @"makeViewDebugData");
        NSArray *jsonRoots = [json isKindOfClass:[NSData class]]
            ? FLEXArray([NSJSONSerialization JSONObjectWithData:json options:0 error:nil]) : nil;
        NSMutableArray<NSDictionary *> *jsonNodes = [NSMutableArray new];
        for (id root in jsonRoots) {
            if (FLEXDictionary(root)) {
                [jsonNodes addObject:root];
                [self assignOffsetsFrom:root outerFrame:NULL];
                [self collectFramesFrom:root offset:CGPointZero depth:0];
            }
        }

        [self matchAccessibilityChildren:accessibilityRoots toJSONChildren:jsonNodes intoContainers:NO];

        [self buildTree];
        if (outer) {
            [self adoptCustomViewsFrom:outer];
        }
    }

    return self;
}

#pragma mark Accessibility tree

/// "attribute|type", since a container and its first child can share an attribute.
static NSString *FLEXAccessibilityKey(NSDictionary *node) {
    id attribute = node[@"attribute"];
    return attribute ? [NSString stringWithFormat:@"%@|%@", attribute, node[@"type"]] : nil;
}

static NSString *FLEXAccessibilityType(NSDictionary *node) {
    return node[@"type"] ? [NSString stringWithFormat:@"%@", node[@"type"]] : nil;
}

/// @return The union of the screen frames of the elements in \c value's subtree.
- (CGRect)indexAccessibilityNode:(id)value parent:(NSString *)parent {
    NSDictionary *node = FLEXDictionary(value);
    NSString *key = node ? FLEXAccessibilityKey(node) : nil;
    CGRect elementFrames = CGRectNull;
    if (key) {
        NSMutableOrderedSet *parents = _parents[key] ?: (_parents[key] = [NSMutableOrderedSet new]);
        if (parent && ![parent isEqualToString:key]) {
            [parents addObject:parent];
            NSMutableOrderedSet *children = _children[parent] ?: (_children[parent] = [NSMutableOrderedSet new]);
            [children addObject:key];
        }
        _types[key] = FLEXAccessibilityType(node);

        NSObject *element = node[@"element"];
        if ([element isKindOfClass:[NSObject class]] && [element respondsToSelector:@selector(accessibilityFrame)]) {
            NSString *label = FLEXString(element.accessibilityLabel);
            if (label.length) {
                [_elements addObject:@{ @"label": label, @"frame": [NSValue valueWithCGRect:element.accessibilityFrame] }];
            }
            elementFrames = element.accessibilityFrame;
        }
    }

    for (id child in FLEXArray(node[@"children"])) {
        elementFrames = CGRectUnion(elementFrames, [self indexAccessibilityNode:child parent:key ?: parent]);
    }

    if (key && !CGRectIsNull(elementFrames)) {
        NSValue *existing = _elementFrames[key];
        _elementFrames[key] = [NSValue valueWithCGRect:existing ? CGRectUnion(elementFrames, existing.CGRectValue) : elementFrames];
    }

    return elementFrames;
}

#pragma mark Coordinate spaces

/// Records the shift from each JSON node's layout container into the hosting view. A
/// Text node anchors its container when an accessibility element shows the same string
/// at the same size. A parent takes its children's shift when they agree and sit inside
/// its frame; a child outside its parent's frame is in another container, such as a
/// scroll view's content, whose positions restart at zero.
///
/// @param outerFrame Receives the frame of \c node, or of its outermost laid-out
/// descendants when it has none, in its own container's coordinates.
/// @return The shift for \c node's container, if known.
- (NSValue *)assignOffsetsFrom:(NSDictionary *)node outerFrame:(CGRect *)outerFrame {
    CGRect frame;
    BOOL hasFrame = FLEXJSONFrame(node, &frame);
    NSValue *own = hasFrame ? [self anchorOffsetForNode:node frame:frame] : nil;

    NSValue *shared = nil;
    BOOL mixed = NO;
    CGRect childFrames = CGRectNull;
    for (NSDictionary *child in FLEXJSONChildren(node)) {
        CGRect childFrame = CGRectNull;
        NSValue *offset = [self assignOffsetsFrom:child outerFrame:&childFrame];
        childFrames = CGRectUnion(childFrames, childFrame);

        BOOL sameContainer = !hasFrame || CGRectIsNull(childFrame) || FLEXRectContainsRect(frame, childFrame);
        if (!offset || !sameContainer) {
            continue;
        }

        mixed = mixed || (shared && !FLEXPointsMatch(offset.CGPointValue, shared.CGPointValue));
        shared = shared ?: offset;
    }

    if (outerFrame) {
        *outerFrame = hasFrame ? frame : childFrames;
    }

    NSValue *result = own ?: (mixed ? nil : shared);
    if (result) {
        [_offsets setObject:result forKey:node];
    }

    return result;
}

- (NSValue *)anchorOffsetForNode:(NSDictionary *)node frame:(CGRect)frame {
    if (![FLEXJSONType(node) isEqualToString:@"SwiftUI.Text"]) {
        return nil;
    }

    NSString *text = FLEXJSONTextString(node[@"properties"]);
    if (!text.length) {
        return nil;
    }

    // Only a string shown once on screen says which element this is
    NSValue *offset = nil;
    for (NSDictionary *element in _elements) {
        CGRect elementFrame = [element[@"frame"] CGRectValue];
        if ([element[@"label"] isEqualToString:text] && FLEXSizesMatch(elementFrame.size, frame.size)) {
            if (offset) {
                return nil;
            }
            offset = [NSValue valueWithCGPoint:CGPointMake(
                elementFrame.origin.x - _hostOriginOnScreen.x - frame.origin.x,
                elementFrame.origin.y - _hostOriginOnScreen.y - frame.origin.y
            )];
        }
    }

    return offset;
}

#pragma mark Joining the trees

/// What the search for a matching JSON node does at a node of each type.
typedef NS_ENUM(NSUInteger, FLEXJSONNodeRole) {
    /// A custom view or a component, whose insides belong to it
    FLEXJSONNodeRoleOpaque,
    FLEXJSONNodeRoleContainer,
    /// One of SwiftUI's internal wrappers, such as the one a modifier adds
    FLEXJSONNodeRoleWrapper,
};

static FLEXJSONNodeRole FLEXJSONRoleOfType(NSString *type) {
    BOOL isControl = NO;
    if (FLEXIsCustomType(type) || FLEXComponentName(type, &isControl)) {
        return FLEXJSONNodeRoleOpaque;
    }

    return FLEXContainerName(type) ? FLEXJSONNodeRoleContainer : FLEXJSONNodeRoleWrapper;
}

/// Nodes of \c type at or below \c node, nearest first, as { node, depth }. The search
/// passes through SwiftUI's internal wrappers, which the accessibility tree often leaves
/// out: each modifier, such as padding, a frame or an overlay, adds one around the view.
/// It doesn't enter public views, whose insides belong to them, except containers when
/// \c intoContainers is set: a control such as Toggle lays out its label in its own.
- (NSArray<NSArray *> *)JSONNodesOfType:(NSString *)type at:(NSDictionary *)node intoContainers:(BOOL)intoContainers {
    static const NSInteger kMaxWrappers = 16;
    NSMutableArray<NSArray *> *found = [NSMutableArray new];
    NSArray<NSDictionary *> *level = @[node];
    for (NSInteger depth = 0; depth < kMaxWrappers && level.count; depth++) {
        NSMutableArray<NSDictionary *> *next = [NSMutableArray new];
        for (NSDictionary *candidate in level) {
            FLEXJSONNodeRole role = [[_jsonRoles objectForKey:candidate] unsignedIntegerValue];
            if ([[_jsonTypes objectForKey:candidate] isEqualToString:type]) {
                [found addObject:@[candidate, @(depth)]];
            } else if (role == FLEXJSONNodeRoleWrapper || (intoContainers && role == FLEXJSONNodeRoleContainer)) {
                [next addObjectsFromArray:FLEXJSONChildren(candidate)];
            }
        }
        level = next;
    }

    return found;
}

/// The strings shown by Text nodes in \c node's subtree.
- (NSSet<NSString *> *)textsIn:(NSDictionary *)node {
    NSSet<NSString *> *cached = [_jsonTexts objectForKey:node];
    if (cached) {
        return cached;
    }

    NSMutableSet<NSString *> *texts = [NSMutableSet new];
    if ([[_jsonTypes objectForKey:node] isEqualToString:@"SwiftUI.Text"]) {
        NSString *text = FLEXJSONTextString(node[@"properties"]);
        if (text.length) {
            [texts addObject:text];
        }
    }
    for (NSDictionary *child in FLEXJSONChildren(node)) {
        [texts unionSet:[self textsIn:child]];
    }

    [_jsonTexts setObject:texts forKey:node];
    return texts;
}

/// The labels of accessibility elements in \c node's subtree.
static void FLEXCollectLabels(NSDictionary *node, NSMutableSet<NSString *> *labels) {
    NSObject *element = node[@"element"];
    if ([element isKindOfClass:[NSObject class]] && [element respondsToSelector:@selector(accessibilityLabel)]) {
        NSString *label = FLEXString(element.accessibilityLabel);
        if (label.length) {
            [labels addObject:label];
        }
    }

    for (id child in FLEXArray(node[@"children"])) {
        if (FLEXDictionary(child)) {
            FLEXCollectLabels(child, labels);
        }
    }
}

- (NSUInteger)countOfTextsIn:(NSDictionary *)node shownIn:(NSSet<NSString *> *)labels {
    NSMutableSet<NSString *> *texts = [[self textsIn:node] mutableCopy];
    [texts intersectSet:labels];
    return texts.count;
}

/// Matches accessibility children to unused JSON children of the same type. The two
/// trees don't always list siblings in the same order, so siblings of one type are told
/// apart by the text they show. A child without a JSON counterpart, such as a Button the
/// JSON leaves out, is passed through so its own children can match, searching into the
/// containers it laid them out in.
- (void)matchAccessibilityChildren:(NSArray *)children
                    toJSONChildren:(NSArray<NSDictionary *> *)jsonChildren
                    intoContainers:(BOOL)intoContainers {
    // Children with a counterpart claim theirs before those passed through search
    // deeper, so a Text inside an Optional can't take its sibling Text's node
    NSMutableArray<NSDictionary *> *passedThrough = [NSMutableArray new];
    for (id value in children) {
        NSDictionary *child = FLEXDictionary(value);
        if (!child) {
            continue;
        }

        NSString *key = FLEXAccessibilityKey(child);

        // A node is listed twice, but only one listing has children; match those against
        // the JSON node the node matched, whichever listing came first
        if (key && _jsonNodes[key]) {
            [self matchAccessibilityChildren:FLEXArray(child[@"children"])
                              toJSONChildren:FLEXJSONChildren(_jsonNodes[key]) intoContainers:NO];
            continue;
        }

        NSDictionary *match = key ? [self JSONNodeMatching:child among:jsonChildren intoContainers:intoContainers] : nil;
        if (match) {
            [self matchAccessibilityNode:child toJSONNode:match];
        } else {
            [passedThrough addObject:child];
        }
    }

    for (NSDictionary *child in passedThrough) {
        [self matchAccessibilityChildren:FLEXArray(child[@"children"]) toJSONChildren:jsonChildren intoContainers:YES];
    }
}

/// The unused JSON node of \c node's type that best agrees with it: laid out where its
/// accessibility elements are, then showing the most of the same text, then the
/// shallowest. Siblings of one type, like two Images in a row, differ in where they are.
- (NSDictionary *)JSONNodeMatching:(NSDictionary *)node
                             among:(NSArray<NSDictionary *> *)jsonNodes
                    intoContainers:(BOOL)intoContainers {
    NSString *key = FLEXAccessibilityKey(node);
    CGRect elements = [self hostFrameOfElementsIn:key];
    CGPoint center = CGPointMake(CGRectGetMidX(elements), CGRectGetMidY(elements));
    NSMutableSet<NSString *> *labels = nil;

    NSDictionary *match = nil;
    NSInteger bestPlace = -1, bestScore = 0, bestDepth = NSIntegerMax;
    for (NSDictionary *sibling in jsonNodes) {
        for (NSArray *found in [self JSONNodesOfType:FLEXAccessibilityType(node) at:sibling intoContainers:intoContainers]) {
            NSDictionary *candidate = found[0];
            NSInteger depth = [found[1] integerValue];
            if ([_matchedJSONNodes containsObject:candidate]) {
                continue;
            }

            NSDictionary *framed = candidate;
            while (framed && ![_hostFrames objectForKey:framed]) {
                framed = [_jsonParents objectForKey:framed];
            }
            CGRect frame = framed ? [[_hostFrames objectForKey:framed] CGRectValue] : CGRectNull;
            NSInteger place = !CGRectIsNull(elements) && CGRectContainsPoint(CGRectInset(frame, -1, -1), center);

            // Text only decides between candidates in the same place
            NSInteger score = 0;
            if (match && place == bestPlace) {
                if (!labels) {
                    labels = [NSMutableSet new];
                    FLEXCollectLabels(node, labels);
                }
                score = [self countOfTextsIn:candidate shownIn:labels];
                bestScore = [self countOfTextsIn:match shownIn:labels];
            }

            BOOL better = place != bestPlace ? place > bestPlace
                : score != bestScore ? score > bestScore
                : depth < bestDepth;
            if (better) {
                bestPlace = place;
                bestScore = score;
                bestDepth = depth;
                match = candidate;
            }
        }
    }

    return match;
}

- (void)matchAccessibilityNode:(NSDictionary *)node toJSONNode:(NSDictionary *)jsonNode {
    NSString *key = FLEXAccessibilityKey(node);
    [_matchedJSONNodes addObject:jsonNode];
    _jsonNodes[key] = jsonNode;

    [self matchAccessibilityChildren:FLEXArray(node[@"children"])
                      toJSONChildren:FLEXJSONChildren(jsonNode) intoContainers:NO];
}

/// Records each JSON node's type, parent and frame in the hosting view.
- (void)collectFramesFrom:(NSDictionary *)node offset:(CGPoint)offset depth:(NSUInteger)depth {
    // An off-screen copy, such as a control's label rendered for accessibility, has no size
    CGRect frame;
    BOOL hasFrame = FLEXJSONFrame(node, &frame);
    if (hasFrame && CGSizeEqualToSize(frame.size, CGSizeZero)) {
        return;
    }

    NSString *type = FLEXJSONType(node) ?: @"";
    [_jsonTypes setObject:type forKey:node];
    [_jsonRoles setObject:@(FLEXJSONRoleOfType(type)) forKey:node];

    NSValue *ownOffset = [_offsets objectForKey:node];
    offset = ownOffset ? ownOffset.CGPointValue : offset;

    if (hasFrame) {
        frame = CGRectOffset(frame, offset.x, offset.y);
        [_hostFrames setObject:[NSValue valueWithCGRect:frame] forKey:node];
        [_framed addObject:@{ @"frame": [NSValue valueWithCGRect:frame], @"depth": @(depth), @"node": node }];
    }

    for (NSDictionary *child in FLEXJSONChildren(node)) {
        [_jsonParents setObject:node forKey:child];
        [self collectFramesFrom:child offset:offset depth:depth + 1];
    }
}

#pragma mark Tree

/// \c name is nil for a type the tree leaves out, such as a modifier.
static FLEXSwiftUIViewKind FLEXKindOfType(NSString *type, NSString **name, BOOL *isControl) {
    *isControl = NO;
    if (FLEXIsCustomType(type)) {
        // "App.Section<SwiftUI.TupleView<…>>" → "Section"
        *name = FLEXBaseName(type);
        return FLEXSwiftUIViewKindCustom;
    }

    if ((*name = FLEXContainerName(type))) {
        return FLEXSwiftUIViewKindContainer;
    }

    *name = FLEXComponentName(type, isControl);
    return FLEXSwiftUIViewKindComponent;
}

/// The JSON node a named view goes on. That is its own match, or else the outermost node
/// around everything it contains below what its ancestors matched: modifiers applied to
/// a view, such as its padding or background, wrap it there. A match SwiftUI recorded no
/// geometry for, such as a Text shown conditionally, widens to the wrapper laid out
/// around it.
- (NSDictionary *)anchorForKey:(NSString *)key {
    NSDictionary *own = _jsonNodes[key];
    if (own) {
        NSHashTable<NSDictionary *> *keptAbove = [self JSONNodesAbove:key keptOnly:YES];
        NSDictionary *anchor = own;
        while (![_hostFrames objectForKey:anchor]) {
            NSDictionary *parent = [_jsonParents objectForKey:anchor];
            if (!parent || [keptAbove containsObject:parent]) {
                break;
            }
            anchor = parent;
        }

        return [_hostFrames objectForKey:anchor] ? anchor : own;
    }

    // The JSON nodes matched to what the view contains
    NSMutableArray<NSDictionary *> *contained = [NSMutableArray new];
    NSMutableOrderedSet<NSString *> *pending = [_children[key] mutableCopy] ?: [NSMutableOrderedSet new];
    NSMutableSet<NSString *> *seen = [NSMutableSet setWithObject:key];
    while (pending.count) {
        NSString *next = pending.firstObject;
        [pending removeObjectAtIndex:0];
        if ([seen containsObject:next]) {
            continue;
        }
        [seen addObject:next];

        if (_jsonNodes[next]) {
            [contained addObject:_jsonNodes[next]];
        } else {
            [pending unionOrderedSet:_children[next] ?: [NSOrderedSet new]];
        }
    }

    NSHashTable<NSDictionary *> *above = [self JSONNodesAbove:key keptOnly:NO];
    NSDictionary *common = [self commonAncestorOf:contained], *anchor = common;
    NSDictionary *parent = [_jsonParents objectForKey:anchor];
    for (; parent && ![above containsObject:parent]; parent = [_jsonParents objectForKey:parent]) {
        anchor = parent;
    }

    return parent ? anchor : common;
}

/// The keys reachable from \c key along \c edges, such as \c _parents, not counting
/// \c key itself.
- (NSSet<NSString *> *)keysFrom:(NSString *)key along:(NSDictionary<NSString *, NSMutableOrderedSet<NSString *> *> *)edges {
    NSMutableSet<NSString *> *reached = [NSMutableSet new];
    NSMutableArray<NSString *> *pending = [edges[key].array mutableCopy] ?: [NSMutableArray new];
    while (pending.count) {
        NSString *next = pending.lastObject;
        [pending removeLastObject];
        if (![reached containsObject:next]) {
            [reached addObject:next];
            [pending addObjectsFromArray:edges[next].array ?: @[]];
        }
    }

    [reached removeObject:key];
    return reached;
}

/// The JSON nodes matched to the accessibility nodes that list \c key, at any distance,
/// or only to those of them that are kept in the tree.
- (NSHashTable<NSDictionary *> *)JSONNodesAbove:(NSString *)key keptOnly:(BOOL)keptOnly {
    NSHashTable<NSDictionary *> *nodes = [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
    for (NSString *above in [self keysFrom:key along:_parents]) {
        NSString *name = nil;
        BOOL isControl = NO;
        FLEXKindOfType(_types[above], &name, &isControl);
        if (_jsonNodes[above] && (name || !keptOnly)) {
            [nodes addObject:_jsonNodes[above]];
        }
    }

    return nodes;
}

- (NSDictionary *)commonAncestorOf:(NSArray<NSDictionary *> *)nodes {
    NSDictionary *common = nodes.firstObject;
    for (NSDictionary *node in nodes) {
        NSHashTable *ancestors = [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
        for (NSDictionary *a = node; a; a = [_jsonParents objectForKey:a]) {
            [ancestors addObject:a];
        }
        while (common && ![ancestors containsObject:common]) {
            common = [_jsonParents objectForKey:common];
        }
    }

    return common;
}

/// Keeps the custom views, containers and components, nested the way the JSON nests
/// their nodes.
- (void)buildTree {
    NSMutableDictionary<NSString *, FLEXSwiftUIViewNode *> *kept = [NSMutableDictionary new];
    NSMapTable<NSDictionary *, NSMutableArray<NSString *> *> *keysByAnchor = [NSMapTable
        mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsStrongMemory
    ];

    for (NSString *key in _types) {
        NSString *name = nil;
        BOOL isControl = NO;
        FLEXSwiftUIViewKind kind = FLEXKindOfType(_types[key], &name, &isControl);
        NSDictionary *anchor = name ? [self anchorForKey:key] : nil;
        if (!anchor) {
            continue;
        }

        FLEXSwiftUIViewNode *node = _previousNodes[key] ?: [FLEXSwiftUIViewNode new];
        node.name = name;
        node.typeName = _types[key];
        node.kind = kind;
        node.isControl = isControl;
        node.hostingView = _hostingView;
        NSValue *frame = [_hostFrames objectForKey:anchor];
        node.frameInHostingView = frame ? frame.CGRectValue : CGRectNull;
        if (!frame) {
            [_elementFramesOfNodes setObject:[NSValue valueWithCGRect:[self hostFrameOfElementsIn:key]] forKey:node];
        }
        node.mutableChildren = [NSMutableArray new];
        node.parent = nil;
        kept[key] = node;

        NSMutableArray *sharing = [keysByAnchor objectForKey:anchor] ?: [NSMutableArray new];
        [sharing addObject:key];
        [keysByAnchor setObject:sharing forKey:anchor];
    }

    // Views on one JSON node nest the way the accessibility tree lists them, or else with
    // a custom view around its body, or by how much they contain; the rest nest under the
    // innermost view on their nearest ancestor that has any
    NSMutableDictionary<NSString *, NSString *> *keptParents = [NSMutableDictionary new];
    for (NSDictionary *anchor in keysByAnchor) {
        NSMutableArray<NSString *> *sharing = [keysByAnchor objectForKey:anchor];
        NSMutableDictionary<NSString *, NSSet<NSString *> *> *listedUnder = [NSMutableDictionary new];
        NSMutableDictionary<NSString *, NSNumber *> *contained = [NSMutableDictionary new];
        for (NSString *key in sharing) {
            listedUnder[key] = [self keysFrom:key along:_parents];
            contained[key] = @([self keysFrom:key along:_children].count);
        }
        [sharing sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
            BOOL aAboveB = [listedUnder[b] containsObject:a], bAboveA = [listedUnder[a] containsObject:b];
            if (aAboveB != bAboveA) {
                return aAboveB ? NSOrderedAscending : NSOrderedDescending;
            }
            BOOL customA = FLEXIsCustomType(self->_types[a]), customB = FLEXIsCustomType(self->_types[b]);
            if (customA != customB) {
                return customA ? NSOrderedAscending : NSOrderedDescending;
            }
            NSComparisonResult bySize = [contained[b] compare:contained[a]];
            return bySize != NSOrderedSame ? bySize : [a compare:b];
        }];
    }

    for (NSDictionary *anchor in keysByAnchor) {
        NSString *above = nil;
        for (NSDictionary *ancestor = [_jsonParents objectForKey:anchor]; ancestor && !above;
             ancestor = [_jsonParents objectForKey:ancestor]) {
            above = [[keysByAnchor objectForKey:ancestor] lastObject];
        }

        for (NSString *key in [keysByAnchor objectForKey:anchor]) {
            keptParents[key] = above;
            above = key;
        }
    }

    // A node folds into its parent when it repeats it, like the several wrappers SwiftUI
    // lists for one Button, or when it is a control's own internals. A background applied
    // to a control is drawn around it but is not part of it.
    NSMutableDictionary<NSString *, NSString *> *foldedInto = [NSMutableDictionary new];
    for (NSString *key in kept) {
        NSSet<NSString *> *listedUnder = [self keysFrom:key along:_parents];
        for (NSString *ancestor = keptParents[key]; ancestor; ancestor = keptParents[ancestor]) {
            FLEXSwiftUIViewNode *node = kept[key], *above = kept[ancestor];
            if (above.kind == FLEXSwiftUIViewKindCustom) {
                break;
            }

            BOOL repeats = [ancestor isEqualToString:keptParents[key]] && [above.name isEqualToString:node.name]
                && CGRectEqualToRect(CGRectIntegral(above.frameInHostingView), CGRectIntegral(node.frameInHostingView));
            BOOL insideControl = above.isControl && [listedUnder containsObject:ancestor];
            if (repeats || insideControl) {
                foldedInto[key] = ancestor;
            }
        }
    }

    for (NSString *key in kept) {
        if (foldedInto[key]) {
            continue;
        }

        NSString *parentKey = keptParents[key];
        while (parentKey && foldedInto[parentKey]) {
            parentKey = keptParents[parentKey];
        }

        FLEXSwiftUIViewNode *parent = kept[parentKey];
        kept[key].parent = parent;
        [(parent ? parent.mutableChildren : _roots) addObject:kept[key]];
    }

    for (FLEXSwiftUIViewNode *root in _roots) {
        [self finishNode:root enclosing:nil];
    }
    [self sortNodes:_roots];

    // A layer drawn by a folded node belongs to the node it folded into
    _nodesForAnchors = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                             valueOptions:NSPointerFunctionsStrongMemory];
    for (NSDictionary *anchor in keysByAnchor) {
        NSString *key = [keysByAnchor objectForKey:anchor].lastObject;
        while (foldedInto[key]) {
            key = foldedInto[key];
        }
        [_nodesForAnchors setObject:kept[key] forKey:anchor];
    }

    [kept removeObjectsForKeys:foldedInto.allKeys];
    _nodes = kept;
}

/// The custom views that declared \c key, innermost first, up to the first view this
/// snapshot shows or one in \c stop.
- (NSArray<NSString *> *)customKeysDeclaring:(NSString *)key stoppingAt:(NSSet<NSString *> *)stop {
    NSMutableArray<NSString *> *found = [NSMutableArray new];
    NSMutableSet<NSString *> *seen = [NSMutableSet setWithObject:key];
    for (NSString *parent = _parents[key].firstObject; parent && ![seen containsObject:parent];
         parent = _parents[parent].firstObject) {
        [seen addObject:parent];
        if (_nodes[parent] || [stop containsObject:parent]) {
            break;
        }
        if (FLEXIsCustomType(_types[parent])) {
            [found addObject:parent];
        }
    }

    return found;
}

/// A hosting view inside another, such as a List cell's, draws views from the outer one's
/// view graph, and only the outer accessibility tree lists the custom views they were
/// declared in, such as a row. Puts those custom views back around what they declared.
- (void)adoptCustomViewsFrom:(FLEXSwiftUISnapshot *)outer {
    NSSet<NSString *> *ownKeys = [NSSet setWithArray:_nodes.allKeys];
    NSMutableDictionary<NSString *, FLEXSwiftUIViewNode *> *wrappers = [NSMutableDictionary new];
    for (NSString *key in ownKeys) {
        FLEXSwiftUIViewNode *node = _nodes[key], *parent = node.parent;
        FLEXSwiftUIViewNode *child = node;
        for (NSString *customKey in [outer customKeysDeclaring:key stoppingAt:ownKeys]) {
            FLEXSwiftUIViewNode *wrapper = wrappers[customKey];
            BOOL placed = wrapper != nil;
            if (!wrapper) {
                wrapper = _previousNodes[customKey] ?: [FLEXSwiftUIViewNode new];
                wrapper.name = FLEXBaseName(outer->_types[customKey]);
                wrapper.typeName = outer->_types[customKey];
                wrapper.kind = FLEXSwiftUIViewKindCustom;
                wrapper.isControl = NO;
                wrapper.hostingView = _hostingView;
                wrapper.frameInHostingView = CGRectNull;
                wrapper.mutableChildren = [NSMutableArray new];
                wrapper.parent = nil;
                wrappers[customKey] = wrapper;
            }

            // A view the wrapper is already inside stays where it is
            BOOL around = NO;
            for (FLEXSwiftUIViewNode *above = wrapper.parent; above && !around; above = above.parent) {
                around = above == child;
            }
            if (around) {
                child = nil;
                break;
            }

            [(child.parent ? child.parent.mutableChildren : _roots) removeObjectIdenticalTo:child];
            child.parent = wrapper;
            [wrapper.mutableChildren addObject:child];
            child = placed ? nil : wrapper;
            if (!child) {
                break;
            }
        }

        if (child && child != node) {
            child.parent = parent;
            [(parent ? parent.mutableChildren : _roots) addObject:child];
        }
    }

    [_nodes addEntriesFromDictionary:wrappers];
    for (FLEXSwiftUIViewNode *root in _roots) {
        [self finishNode:root enclosing:nil];
    }
    [self sortNodes:_roots];
}

/// Where SwiftUI recorded no geometry for a node, the accessibility elements inside it
/// still have screen frames.
- (CGRect)hostFrameOfElementsIn:(NSString *)key {
    NSValue *onScreen = _elementFrames[key];
    if (!onScreen) {
        return CGRectNull;
    }

    return CGRectOffset(onScreen.CGRectValue, -_hostOriginOnScreen.x, -_hostOriginOnScreen.y);
}

/// Fills in what depends on the finished tree: the enclosing custom view, frames for
/// views SwiftUI recorded no geometry for, and the order children are listed in. Such a
/// view spans its children, or else its accessibility elements.
- (void)finishNode:(FLEXSwiftUIViewNode *)node enclosing:(NSString *)enclosing {
    node.enclosingName = enclosing;
    NSString *childEnclosing = node.kind == FLEXSwiftUIViewKindCustom ? node.name : enclosing;
    BOOL spansChildren = CGRectIsNull(node.frameInHostingView);
    for (FLEXSwiftUIViewNode *child in node.children) {
        [self finishNode:child enclosing:childEnclosing];
        if (spansChildren) {
            node.frameInHostingView = CGRectUnion(node.frameInHostingView, child.frameInHostingView);
        }
    }
    if (CGRectIsNull(node.frameInHostingView)) {
        NSValue *elements = [_elementFramesOfNodes objectForKey:node];
        node.frameInHostingView = elements ? elements.CGRectValue : CGRectNull;
    }

    [self sortNodes:node.mutableChildren];
}

/// Reading order: top to bottom, then left to right. SwiftUI's own order isn't the
/// order views were declared in.
- (void)sortNodes:(NSMutableArray<FLEXSwiftUIViewNode *> *)nodes {
    [nodes sortUsingComparator:^NSComparisonResult(FLEXSwiftUIViewNode *a, FLEXSwiftUIViewNode *b) {
        CGRect left = a.frameInHostingView, right = b.frameInHostingView;
        if (CGRectIsNull(left) || CGRectIsNull(right)) {
            return CGRectIsNull(left) == CGRectIsNull(right) ? NSOrderedSame : (CGRectIsNull(left) ? NSOrderedDescending : NSOrderedAscending);
        }
        if (fabs(CGRectGetMinY(left) - CGRectGetMinY(right)) > 1) {
            return CGRectGetMinY(left) < CGRectGetMinY(right) ? NSOrderedAscending : NSOrderedDescending;
        }
        return CGRectGetMinX(left) < CGRectGetMinX(right) ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray<FLEXSwiftUIViewNode *> *)roots {
    return _roots;
}

- (NSDictionary<NSString *, FLEXSwiftUIViewNode *> *)nodesByKey {
    return _nodes;
}

/// The node a layer was drawn for: the tightest laid-out frame containing the layer,
/// preferring the deeper node between equal frames, then the nearest node on it or
/// above it.
- (FLEXSwiftUIViewNode *)nodeForLayerFrame:(CGRect)frame {
    NSDictionary *best = nil;
    CGFloat bestArea = CGFLOAT_MAX;
    for (NSDictionary *entry in _framed) {
        CGRect candidate = [entry[@"frame"] CGRectValue];
        if (!FLEXRectContainsRect(candidate, frame)) {
            continue;
        }

        CGFloat area = candidate.size.width * candidate.size.height;
        BOOL tighter = area < bestArea - 1;
        BOOL deeperTie = fabs(area - bestArea) <= 1 && [entry[@"depth"] unsignedIntegerValue] > [best[@"depth"] unsignedIntegerValue];
        if (tighter || deeperTie) {
            best = entry;
            bestArea = area;
        }
    }

    for (NSDictionary *node = best[@"node"]; node; node = [_jsonParents objectForKey:node]) {
        FLEXSwiftUIViewNode *found = [_nodesForAnchors objectForKey:node];
        if (found) {
            return found;
        }
    }

    return nil;
}

@end

#pragma mark - FLEXSwiftUIInspector

/// Hosting view → snapshot. Cleared by +invalidate.
static NSMapTable<UIView *, FLEXSwiftUISnapshot *> *FLEXSnapshots(void) {
    static NSMapTable *snapshots = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        snapshots = [NSMapTable weakToStrongObjectsMapTable];
    });

    return snapshots;
}

/// Hosting view → the nodes of its last snapshot, kept across +invalidate for reuse.
static NSMapTable<UIView *, NSDictionary *> *FLEXPreviousNodes(void) {
    static NSMapTable *previous = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        previous = [NSMapTable weakToStrongObjectsMapTable];
    });

    return previous;
}

/// Whether SwiftUI records its view tree in this launch; nothing is read otherwise.
static BOOL FLEXRecording = NO;

@implementation FLEXSwiftUIInspector

+ (BOOL)isRecording {
    return FLEXRecording;
}

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    // SwiftUI reads this once, when it builds its first view graph. The bits are those
    // of _ViewDebug.Properties: type, position and size, which is all FLEX reads.
    static const unsigned long required = 1 << 0 | 1 << 3 | 1 << 4;
    const char *existing = getenv("SWIFTUI_VIEW_DEBUG");
    if (!existing) {
        if (NSUserDefaults.standardUserDefaults.flex_recordSwiftUIViews) {
            setenv("SWIFTUI_VIEW_DEBUG", [NSString stringWithFormat:@"%lu", required].UTF8String, 0);
            FLEXRecording = YES;
        }
    } else if ((strtoul(existing, NULL, 10) & required) == required) {
        FLEXRecording = YES;
    } else {
        NSLog(@"FLEX: SWIFTUI_VIEW_DEBUG=%s leaves out type, position or size; "
              "SwiftUI views won't be named or selectable.", existing);
    }
}

+ (BOOL)isHostingView:(UIView *)view {
    return [view respondsToSelector:NSSelectorFromString(@"makeViewDebugData")];
}

+ (UIView *)hostingViewForLayer:(CALayer *)layer {
    for (UIView *view = [FLEXUtility viewForLayer:layer]; view; view = view.superview) {
        if ([self isHostingView:view]) {
            return view;
        }
    }

    return nil;
}

+ (void)invalidate {
    [FLEXSnapshots() removeAllObjects];
}

+ (FLEXSwiftUISnapshot *)snapshotForHostingView:(UIView *)hostingView {
    if (!hostingView || !FLEXRecording) {
        return nil;
    }

    FLEXSwiftUISnapshot *snapshot = [FLEXSnapshots() objectForKey:hostingView];
    if (!snapshot) {
        // A List's cells each have a hosting view of their own, drawing from the List's
        // view graph; an unrelated hosting view inside another doesn't share it
        UIView *outer = hostingView.superview;
        BOOL inCell = NO;
        while (outer && ![self isHostingView:outer]) {
            inCell = inCell || [outer isKindOfClass:[UICollectionViewCell class]] || [outer isKindOfClass:[UITableViewCell class]];
            outer = outer.superview;
        }
        outer = inCell ? outer : nil;

        snapshot = [[FLEXSwiftUISnapshot alloc] initWithHostingView:hostingView
            previousNodes:[FLEXPreviousNodes() objectForKey:hostingView]
                    outer:[self snapshotForHostingView:outer]];
        [FLEXSnapshots() setObject:snapshot forKey:hostingView];
        [FLEXPreviousNodes() setObject:snapshot.nodesByKey forKey:hostingView];
    }

    return snapshot;
}

+ (NSArray<FLEXSwiftUIViewNode *> *)rootNodesInHostingView:(UIView *)hostingView {
    return [self snapshotForHostingView:hostingView].roots;
}

+ (NSArray<FLEXSwiftUIViewNode *> *)customViewNodesInHostingView:(UIView *)hostingView
                                                  containingPoint:(CGPoint)pointInWindow {
    NSMutableArray<FLEXSwiftUIViewNode *> *found = [NSMutableArray new];
    NSMutableArray<FLEXSwiftUIViewNode *> *queue = [[self snapshotForHostingView:hostingView].roots mutableCopy];
    // Breadth-first puts outer views first
    while (queue.count) {
        FLEXSwiftUIViewNode *node = queue.firstObject;
        [queue removeObjectAtIndex:0];

        if (node.kind == FLEXSwiftUIViewKindCustom && CGRectContainsPoint(node.frameInWindow, pointInWindow)) {
            [found addObject:node];
        }
        [queue addObjectsFromArray:node.children];
    }

    return found;
}

+ (FLEXSwiftUIViewNode *)nodeForLayer:(CALayer *)layer {
    UIView *hostingView = [self hostingViewForLayer:layer];
    if (!hostingView) {
        return nil;
    }

    CGRect frame = [layer convertRect:layer.bounds toLayer:hostingView.layer];
    return [[self snapshotForHostingView:hostingView] nodeForLayerFrame:frame];
}

+ (void)describeLayer:(CALayer *)layer component:(NSString **)component owner:(NSString **)owner {
    *component = nil;
    *owner = nil;

    // The nearest control above the node, or else the nearest component, stopping at the
    // custom view that contains them
    FLEXSwiftUIViewNode *node = [self nodeForLayer:layer];
    NSString *primitive = nil;
    for (; node && node.kind != FLEXSwiftUIViewKindCustom; node = node.parent) {
        if (node.kind == FLEXSwiftUIViewKindComponent) {
            if (node.isControl) {
                *component = node.name;
                break;
            }
            primitive = primitive ?: node.name;
        }
    }

    *component = *component ?: primitive;
    while (node && node.kind != FLEXSwiftUIViewKindCustom) {
        node = node.parent;
    }
    *owner = node.name;
}

@end
