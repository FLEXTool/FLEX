//
//  FLEXInjectEngine.h
//  FLEX Injector
//
//  Pure logic for DYLD_INSERT_LIBRARIES injection into local, debuggable apps.
//  No UI, so it can be unit tested.
//
//  This is a developer tool: it launches your own apps with an extra dylib
//  inserted, the same way Xcode and `DYLD_INSERT_LIBRARIES=… ./app` do. It
//  cannot inject into already-running processes, into other users' apps, or
//  into anything macOS protects (SIP system binaries, hardened apps that opt
//  out of dyld environment variables).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FLEXInjectStatus) {
    /// DYLD_INSERT_LIBRARIES will be honored and an ad-hoc signed dylib will load.
    FLEXInjectStatusInjectable,
    /// Hardened runtime with library validation: dyld vars are honored but the
    /// inserted dylib must be signed by the same team (or the app re-signed with
    /// com.apple.security.cs.disable-library-validation).
    FLEXInjectStatusNeedsLibraryValidationDisabled,
    /// Hardened runtime without the allow-dyld-environment-variables entitlement:
    /// dyld strips DYLD_* entirely, so injection at launch is not possible.
    FLEXInjectStatusRestricted,
    /// A SIP-protected system/platform binary: dyld strips DYLD_* entirely.
    FLEXInjectStatusSIPProtected,
    /// Not a readable .app bundle with an executable.
    FLEXInjectStatusNotAnApp,
};

@interface FLEXInjectInfo : NSObject
@property (nonatomic, copy) NSString *appPath;
@property (nonatomic, copy, nullable) NSString *executablePath;
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;
@property (nonatomic, copy, nullable) NSImage *icon;
@property (nonatomic) FLEXInjectStatus status;
/// Human-readable explanation of the status.
@property (nonatomic, copy) NSString *statusDescription;
/// Whether -launch… is expected to work as-is.
@property (nonatomic, readonly) BOOL isInjectable;
@end

@interface FLEXInjectEngine : NSObject

/// The FLEX framework binary that ships with this tool; the default dylib to inject.
+ (nullable NSString *)bundledFLEXDylibPath;

/// The path to the Mach-O executable inside an .app bundle, or nil.
+ (nullable NSString *)executablePathForAppBundle:(NSString *)appPath;

/// Inspects an .app bundle and classifies whether launch-time injection will work.
+ (FLEXInjectInfo *)inspectAppBundle:(NSString *)appPath;

/// The environment to launch with, derived from the current environment.
+ (NSDictionary<NSString *, NSString *> *)launchEnvironmentWithDylib:(NSString *)dylibPath
                                                           autoShow:(BOOL)autoShow;

/// Launches the app's executable directly (bypassing Launch Services, which may
/// strip DYLD_*) with the dylib inserted. Output from the child is streamed to
/// @c outputHandler on an arbitrary queue. Returns the running task, or nil on error.
+ (nullable NSTask *)launchApp:(FLEXInjectInfo *)info
                         dylib:(NSString *)dylibPath
                      autoShow:(BOOL)autoShow
                         error:(NSError **)error
                 outputHandler:(nullable void (^)(NSString *chunk))outputHandler;

@end

NS_ASSUME_NONNULL_END
