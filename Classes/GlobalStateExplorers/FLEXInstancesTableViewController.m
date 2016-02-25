//
//  FLEXInstancesTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXInstancesTableViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"
#import "FLEXHeapEnumerator.h"
#import <malloc/malloc.h>


@interface FLEXInstancesTableViewController ()

@property (nonatomic, strong) NSArray *instances;
@property (nonatomic, strong) NSArray *fieldNames;

@end

@implementation FLEXInstancesTableViewController

+ (instancetype)instancesTableViewControllerForClassName:(NSString *)className
{
    const char *classNameCString = [className UTF8String];
    NSMutableArray *instances = [NSMutableArray array];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
        if (strcmp(classNameCString, class_getName(actualClass)) == 0) {
            // Note: objects of certain classes crash when retain is called. It is up to the user to avoid tapping into instance lists for these classes.
            // Ex. OS_dispatch_queue_specific_queue
            // In the future, we could provide some kind of warning for classes that are known to be problematic.
            if (malloc_size((__bridge const void *)(object)) > 0) {
                [instances addObject:object];
            }
        }
    }];
    FLEXInstancesTableViewController *instancesViewController = [[self alloc] init];
    instancesViewController.instances = instances;
    instancesViewController.title = [NSString stringWithFormat:@"%@ (%lu)", className, (unsigned long)[instances count]];
    return instancesViewController;
}

+ (instancetype)instancesTableViewControllerForInstancesReferencingObject:(id)object
{
    NSMutableArray *instances = [NSMutableArray array];
    NSMutableArray *fieldNames = [NSMutableArray array];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id tryObject, __unsafe_unretained Class actualClass) {
        // Get all the ivars on the object. Start with the class and and travel up the inheritance chain.
        // Once we find a match, record it and move on to the next object. There's no reason to find multiple matches within the same object.
        Class tryClass = actualClass;
        while (tryClass) {
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(tryClass, &ivarCount);
            for (unsigned int ivarIndex = 0; ivarIndex < ivarCount; ivarIndex++) {
                Ivar ivar = ivars[ivarIndex];
                const char *typeEncoding = ivar_getTypeEncoding(ivar);
                if (typeEncoding[0] == @encode(id)[0] || typeEncoding[0] == @encode(Class)[0]) {
                    ptrdiff_t offset = ivar_getOffset(ivar);
                    uintptr_t *fieldPointer = (__bridge void *)tryObject + offset;
                    if (*fieldPointer == (uintptr_t)(__bridge void *)object) {
                        [instances addObject:tryObject];
                        [fieldNames addObject:@(ivar_getName(ivar))];
                        return;
                    }
                }
            }
            tryClass = class_getSuperclass(tryClass);
        }
    }];
    FLEXInstancesTableViewController *instancesViewController = [[self alloc] init];
    instancesViewController.instances = instances;
    instancesViewController.fieldNames = fieldNames;
    instancesViewController.title = [NSString stringWithFormat:@"Referencing %@ %p", NSStringFromClass(object_getClass(object)), object];
    return instancesViewController;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.instances count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
        cell.textLabel.font = cellFont;
        cell.detailTextLabel.font = cellFont;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    id instance = self.instances[indexPath.row];
    NSString *title = nil;
    if ((NSInteger)[self.fieldNames count] > indexPath.row) {
        title = [NSString stringWithFormat:@"%@ %@", NSStringFromClass(object_getClass(instance)), self.fieldNames[indexPath.row]];
    } else {
        title = [NSString stringWithFormat:@"%@ %p", NSStringFromClass(object_getClass(instance)), instance];
    }
    cell.textLabel.text = title;
    cell.detailTextLabel.text = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:instance];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id instance = self.instances[indexPath.row];
    FLEXObjectExplorerViewController *drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:instance];
    [self.navigationController pushViewController:drillInViewController animated:YES];
}

@end
