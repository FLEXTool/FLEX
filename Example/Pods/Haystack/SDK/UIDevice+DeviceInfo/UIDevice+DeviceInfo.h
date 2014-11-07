//
//  UIDevice+DeviceInfo.h
//

#import <UIKit/UIKit.h>

#define isWideScreen ([[UIDevice currentDevice] isWidescreen])

/*!
 * Device family enum
 */
typedef NS_ENUM(NSUInteger, UIDeviceFamily)
{
    UIDeviceFamilyiPhone,
    UIDeviceFamilyiPod,
    UIDeviceFamilyiPad,
    UIDeviceFamilyAppleTV,
    UIDeviceFamilyUnknown,
};

/*!
 * Category displays detailed information about current device
 */
@interface UIDevice (DeviceInfo)

/*!
 * Returns YES if device is iPhone.
 */
- (BOOL)isiPhone;

/*!
 * Returns YES if device is iPod.
 */
- (BOOL)isiPod;

/*!
 * Returns YES if device is iPad.
 */
- (BOOL)isiPad;

/*!
 * Returns YES if device has retina display.
 */
- (BOOL)isRetina;

/*!
 * Returns if the device is iPhone 5 or iPod touch that has widescreen display of 16:9 ratio.
 */
- (BOOL)isWidescreen;

/*!
 * Returns formatted consumer name of Apple device
 */
- (NSString *)modelIdentifier;

/*!
 * Returns model name.
 */
- (NSString *)modelName;

/*!
 * Returns device family of the device
 */
- (UIDeviceFamily)deviceFamily;

/*!
 * Returns YES if device supports Touch ID sensor
 */
- (BOOL)hasTouchID;

@end
