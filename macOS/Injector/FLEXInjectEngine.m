//
//  FLEXInjectEngine.m
//  FLEX Injector
//

#import "FLEXInjectEngine.h"
#import <AppKit/AppKit.h>

@implementation FLEXInjectInfo
- (BOOL)isInjectable {
    return self.status == FLEXInjectStatusInjectable;
}
@end

@implementation FLEXInjectEngine

#pragma mark Paths

+ (NSString *)bundledFLEXDylibPath {
    // FLEXManager lives in FLEX.framework; its executable is the binary we inject.
    Class manager = NSClassFromString(@"FLEXManager");
    NSBundle *framework = manager ? [NSBundle bundleForClass:manager] : nil;
    if (framework.executablePath) {
        return framework.executablePath;
    }
    // Fallback: look next to this tool.
    NSString *here = NSBundle.mainBundle.privateFrameworksPath;
    NSString *guess = [here stringByAppendingPathComponent:@"FLEX.framework/Versions/A/FLEX"];
    return [NSFileManager.defaultManager fileExistsAtPath:guess] ? guess : nil;
}

+ (NSString *)executablePathForAppBundle:(NSString *)appPath {
    NSBundle *bundle = [NSBundle bundleWithPath:appPath];
    if (bundle.executablePath && [NSFileManager.defaultManager isExecutableFileAtPath:bundle.executablePath]) {
        return bundle.executablePath;
    }
    return nil;
}

#pragma mark Classification

/// System locations whose binaries are SIP-protected and strip DYLD_*.
+ (BOOL)isSystemProtectedPath:(NSString *)path {
    NSArray<NSString *> *roots = @[@"/System/", @"/bin/", @"/sbin/", @"/usr/"];
    for (NSString *root in roots) {
        if ([path hasPrefix:root]) {
            // /usr/local is not SIP-protected
            if ([path hasPrefix:@"/usr/local/"]) {
                return NO;
            }
            return YES;
        }
    }
    return NO;
}

/// Runs a short-lived tool and returns its combined stdout, or nil.
+ (NSString *)runTool:(NSString *)launchPath arguments:(NSArray<NSString *> *)arguments {
    if (![NSFileManager.defaultManager isExecutableFileAtPath:launchPath]) {
        return nil;
    }
    NSTask *task = [NSTask new];
    task.executableURL = [NSURL fileURLWithPath:launchPath];
    task.arguments = arguments;
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    @try {
        NSError *error = nil;
        if (![task launchAndReturnError:&error]) {
            return nil;
        }
        NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
        [task waitUntilExit];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
        return nil;
    }
}

/// Entitlements of a Mach-O, read via codesign.
+ (NSDictionary *)entitlementsForExecutable:(NSString *)execPath {
    NSString *xml = [self runTool:@"/usr/bin/codesign" arguments:@[@"-d", @"--entitlements", @":-", @"--xml", execPath]];
    if (!xml.length) {
        // Older codesign emits a binary blob with a header; try without --xml.
        xml = [self runTool:@"/usr/bin/codesign" arguments:@[@"-d", @"--entitlements", @":-", execPath]];
    }
    if (!xml.length) {
        return @{};
    }
    NSRange start = [xml rangeOfString:@"<?xml"];
    if (start.location == NSNotFound) {
        start = [xml rangeOfString:@"<plist"];
    }
    if (start.location == NSNotFound) {
        return @{};
    }
    NSData *data = [[xml substringFromIndex:start.location] dataUsingEncoding:NSUTF8StringEncoding];
    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
    return [plist isKindOfClass:[NSDictionary class]] ? plist : @{};
}

/// Whether the executable is signed with the hardened runtime.
+ (BOOL)hasHardenedRuntime:(NSString *)execPath {
    NSString *info = [self runTool:@"/usr/bin/codesign" arguments:@[@"-dv", execPath]];
    // codesign prints e.g. "CodeDirectory v=... flags=0x10000(runtime) ..."
    return [info containsString:@"(runtime)"] || [info containsString:@"runtime"];
}

+ (FLEXInjectInfo *)inspectAppBundle:(NSString *)appPath {
    FLEXInjectInfo *info = [FLEXInjectInfo new];
    info.appPath = appPath;

    NSBundle *bundle = [NSBundle bundleWithPath:appPath];
    info.bundleIdentifier = bundle.bundleIdentifier;
    info.icon = [NSWorkspace.sharedWorkspace iconForFile:appPath];

    NSString *exec = [self executablePathForAppBundle:appPath];
    info.executablePath = exec;
    if (!exec) {
        info.status = FLEXInjectStatusNotAnApp;
        info.statusDescription = @"No readable executable in this bundle.";
        return info;
    }

    if ([self isSystemProtectedPath:exec]) {
        info.status = FLEXInjectStatusSIPProtected;
        info.statusDescription = @"SIP-protected system app — dyld strips DYLD_* here.";
        return info;
    }

    BOOL hardened = [self hasHardenedRuntime:exec];
    NSDictionary *entitlements = [self entitlementsForExecutable:exec];
    BOOL allowDyldEnv = [entitlements[@"com.apple.security.cs.allow-dyld-environment-variables"] boolValue];
    BOOL disableLV = [entitlements[@"com.apple.security.cs.disable-library-validation"] boolValue];
    BOOL getTaskAllow = [entitlements[@"com.apple.security.get-task-allow"] boolValue];

    if (!hardened) {
        // No hardened runtime: dyld honors DYLD_* and library validation is not
        // enforced, so an ad-hoc signed dylib loads. This is the usual debug build.
        info.status = FLEXInjectStatusInjectable;
        info.statusDescription = getTaskAllow
            ? @"Debuggable build — ready to inject."
            : @"No hardened runtime — ready to inject.";
        return info;
    }

    if (!allowDyldEnv) {
        info.status = FLEXInjectStatusRestricted;
        info.statusDescription = @"Hardened runtime without allow-dyld-environment-variables — DYLD_* is stripped.";
        return info;
    }

    if (!disableLV) {
        info.status = FLEXInjectStatusNeedsLibraryValidationDisabled;
        info.statusDescription = @"Hardened runtime: inserted dylib must be same-team signed, or re-sign the app with library validation disabled.";
        return info;
    }

    info.status = FLEXInjectStatusInjectable;
    info.statusDescription = @"Hardened runtime with library validation disabled — ready to inject.";
    return info;
}

#pragma mark Launching

+ (NSDictionary<NSString *, NSString *> *)launchEnvironmentWithDylib:(NSString *)dylibPath autoShow:(BOOL)autoShow {
    NSMutableDictionary *env = [NSProcessInfo.processInfo.environment mutableCopy];

    // Preserve any existing insertions.
    NSString *existing = env[@"DYLD_INSERT_LIBRARIES"];
    env[@"DYLD_INSERT_LIBRARIES"] = existing.length
        ? [existing stringByAppendingFormat:@":%@", dylibPath]
        : dylibPath;
    env[@"FLEX_AUTO_SHOW"] = autoShow ? @"1" : @"0";
    return env;
}

+ (NSTask *)launchApp:(FLEXInjectInfo *)info
                dylib:(NSString *)dylibPath
             autoShow:(BOOL)autoShow
                error:(NSError **)error
        outputHandler:(void (^)(NSString *))outputHandler {
    NSString *exec = info.executablePath;
    if (!exec) {
        if (error) {
            *error = [NSError errorWithDomain:@"FLEXInjector" code:1
                userInfo:@{ NSLocalizedDescriptionKey: @"No executable to launch." }];
        }
        return nil;
    }
    if (![NSFileManager.defaultManager fileExistsAtPath:dylibPath]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FLEXInjector" code:2
                userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Dylib not found: %@", dylibPath] }];
        }
        return nil;
    }

    NSTask *task = [NSTask new];
    task.executableURL = [NSURL fileURLWithPath:exec];
    task.environment = [self launchEnvironmentWithDylib:dylibPath autoShow:autoShow];
    // Launch from inside the bundle so relative resource lookups behave.
    task.currentDirectoryURL = [NSURL fileURLWithPath:info.appPath];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    if (outputHandler) {
        pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
            NSData *data = handle.availableData;
            if (data.length) {
                NSString *chunk = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (chunk.length) {
                    outputHandler(chunk);
                }
            }
        };
    }

    __weak NSPipe *weakPipe = pipe;
    task.terminationHandler = ^(NSTask *finished) {
        weakPipe.fileHandleForReading.readabilityHandler = nil;
    };

    if (![task launchAndReturnError:error]) {
        return nil;
    }
    return task;
}

@end
