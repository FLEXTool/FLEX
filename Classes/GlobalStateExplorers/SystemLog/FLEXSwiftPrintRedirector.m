//
//  FLEXSwiftPrintRedirector.m
//  FLEX
//
//  Created by 김인환 on 2025.
//  Copyright © 2025 FLEX Team. All rights reserved.
//

#import "FLEXSwiftPrintRedirector.h"
#import "FLEXSystemLogMessage.h"

@implementation FLEXSwiftPrintRedirector

static BOOL _isRedirectionEnabled = NO;
static int _originalStdout = -1;
static int _originalStderr = -1;
static NSPipe *_stdoutPipe = nil;
static NSPipe *_stderrPipe = nil;
static id _stdoutObserver = nil;
static id _stderrObserver = nil;
static dispatch_queue_t _logQueue = nil;
static void(^_messageHandler)(FLEXSystemLogMessage *) = nil;
static NSMutableString *_stdoutBuffer = nil;
static NSMutableString *_stderrBuffer = nil;

+ (void)enableSwiftPrintRedirection {
    @synchronized(self) {
        if (_isRedirectionEnabled) {
            return;
        }

        _isRedirectionEnabled = YES;
        _logQueue = dispatch_queue_create("com.flex.swiftprint", DISPATCH_QUEUE_SERIAL);
        _stdoutBuffer = [NSMutableString string];
        _stderrBuffer = [NSMutableString string];

        // Save original stdout and stderr
        _originalStdout = dup(STDOUT_FILENO);
        _originalStderr = dup(STDERR_FILENO);

        // Create pipes
        _stdoutPipe = [NSPipe pipe];
        _stderrPipe = [NSPipe pipe];

        // Redirect stdout
        dup2(_stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO);

        // Redirect stderr
        dup2(_stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO);

        // Start reading from stdout pipe
        NSFileHandle *stdoutReadHandle = _stdoutPipe.fileHandleForReading;
        _stdoutObserver = [[NSNotificationCenter defaultCenter]
            addObserverForName:NSFileHandleReadCompletionNotification
            object:stdoutReadHandle
            queue:nil
            usingBlock:^(NSNotification *note) {
                NSData *data = note.userInfo[NSFileHandleNotificationDataItem];
                if (data.length > 0) {
                    [self processOutputData:data isError:NO buffer:_stdoutBuffer];
                    [stdoutReadHandle readInBackgroundAndNotify];
                }
            }];
        [stdoutReadHandle readInBackgroundAndNotify];

        // Start reading from stderr pipe
        NSFileHandle *stderrReadHandle = _stderrPipe.fileHandleForReading;
        _stderrObserver = [[NSNotificationCenter defaultCenter]
            addObserverForName:NSFileHandleReadCompletionNotification
            object:stderrReadHandle
            queue:nil
            usingBlock:^(NSNotification *note) {
                NSData *data = note.userInfo[NSFileHandleNotificationDataItem];
                if (data.length > 0) {
                    [self processOutputData:data isError:YES buffer:_stderrBuffer];
                    [stderrReadHandle readInBackgroundAndNotify];
                }
            }];
        [stderrReadHandle readInBackgroundAndNotify];
    }
}

+ (void)disableSwiftPrintRedirection {
    @synchronized(self) {
        if (!_isRedirectionEnabled) {
            return;
        }

        _isRedirectionEnabled = NO;

        // Remove observers
        if (_stdoutObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:_stdoutObserver];
            _stdoutObserver = nil;
        }
        if (_stderrObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:_stderrObserver];
            _stderrObserver = nil;
        }

        // Restore original stdout and stderr
        if (_originalStdout != -1) {
            dup2(_originalStdout, STDOUT_FILENO);
            close(_originalStdout);
            _originalStdout = -1;
        }
        if (_originalStderr != -1) {
            dup2(_originalStderr, STDERR_FILENO);
            close(_originalStderr);
            _originalStderr = -1;
        }

        // Clean up pipes
        _stdoutPipe = nil;
        _stderrPipe = nil;
    }
}

+ (BOOL)isRedirectionEnabled {
    @synchronized(self) {
        return _isRedirectionEnabled;
    }
}

+ (void)setMessageHandler:(void(^)(FLEXSystemLogMessage *message))handler {
    @synchronized(self) {
        _messageHandler = [handler copy];
    }
}

+ (void)processOutputData:(NSData *)data isError:(BOOL)isError buffer:(NSMutableString *)buffer {
    // Write to original file descriptor first to preserve console output
    int originalFd = isError ? _originalStderr : _originalStdout;
    if (originalFd != -1) {
        write(originalFd, data.bytes, data.length);
    }

    // Process on background queue to avoid blocking
    dispatch_async(_logQueue, ^{
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!output) {
            output = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        }

        if (output && _messageHandler) {
            // Append to buffer to handle partial lines
            @synchronized(buffer) {
                [buffer appendString:output];

                // Process complete lines (ending with newline)
                while (YES) {
                    NSRange newlineRange = [buffer rangeOfString:@"\n"];
                    if (newlineRange.location == NSNotFound) {
                        break;
                    }

                    // Extract complete line
                    NSString *line = [buffer substringToIndex:newlineRange.location];
                    [buffer deleteCharactersInRange:NSMakeRange(0, newlineRange.location + 1)];

                    NSString *trimmedLine = [line stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]];
                    if (trimmedLine.length > 0) {
                        // Create FLEX message directly without going through NSLog/os_log
                        NSString *formattedMessage = [NSString stringWithFormat:@"[SwiftPrint] %@", trimmedLine];
                        FLEXSystemLogMessage *message = [FLEXSystemLogMessage
                            logMessageFromDate:[NSDate date]
                            text:formattedMessage];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            _messageHandler(message);
                        });
                    }
                }
            }
        }
    });
}

@end