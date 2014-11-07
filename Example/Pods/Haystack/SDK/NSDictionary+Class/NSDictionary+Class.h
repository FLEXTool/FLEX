//
//  NSDictionary+Class.h
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Class)

/*!
 * Returns YES, if at least one object in array is member of provided class.
 *
 * @param Class class of object
 * @return YES if array contains an object of same class.
 */
- (BOOL)containsObjectOfClass:(Class)objectClass;

/*!
 * Returns YES, if at least one object in array is of provided class or
 * has inherited from provided class.
 *
 * @param Class class of object
 * @return YES if array contains an object of same or inherited class.
 */
- (BOOL)containsObjectOfInheritedClass:(Class)objectClass;

/*!
 * Returns YES, if at all objects in array are members of provided class.
 *
 * @param Class class of object
 * @return YES if array contains only objects of same class.
 */
- (BOOL)containsAllObjectsOfClass:(Class)objectClass;

/*!
 * Returns YES, if at all objects in array are of provided class or
 * have inherited from provided class.
 *
 * @param Class class of object
 * @return YES if array contains only objects of same or inherited class.
 */
- (BOOL)containsAllObjectsOfInheritedClass:(Class)objectClass;

@end
