@interface HSWeakPointer : NSObject

/*! 
 * Holds weak reference to an object
 */
@property (nonatomic, weak) id object;

/*!
 * Returns YES if object is not nil
 */
- (BOOL)isValid;

/*!
 * Returns weak pointer object with object
 */
+ (instancetype)weakPointerWithObject:(id)object;

@end
