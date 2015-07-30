//
//  TCPClient.m
//  MCU Gateway
//
//  Created by Abel Duarte on 6/4/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import "PPDebugger.h"
#import "RemoteLogger.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

@interface PPDebugger()
void InstallUncaughtExceptionHandler();
- (void)handleException:(NSException *)exception;
@property (nonatomic, assign) BOOL installed;
@property (nonatomic, assign) BOOL dismissed;
@end;

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation PPDebugger

#pragma mark - Singleton

static id sharedDebugger = nil;

+ (PPDebugger *)sharedDebugger
{
    if(!sharedDebugger)
        sharedDebugger = [[PPDebugger alloc] init];

    return sharedDebugger;
}

#pragma mark - Init and dealloc

- (id)init
{
    self = [super init];
    if(self)
    {
        self.installed = NO;
        [self install];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - Install

- (void)install
{
    if(!self.installed)
    {
        self.installed = YES;
        InstallUncaughtExceptionHandler();
        [RemoteLogger sharedLogger];
    }
}

#pragma mark - Backtrace

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);

    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (
         i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount +
         UncaughtExceptionHandlerReportAddressCount;
         i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);

    return backtrace;
}

#pragma mark - Exception handler

- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex
{
    if (anIndex == 0)
    {
        self.dismissed = YES;
    }
}

- (void)handleException:(NSException *)exception
{
    //NLog(@"Exception Reason: %@", [exception reason]);
    //NSLog(@"Exception userInfo: %@", [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]);

    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    UIAlertView *alert =
    [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"Unhandled exception", nil)
      message:[NSString stringWithFormat:NSLocalizedString(
                                                           @"You can try to continue but the application may be unstable.\n"
                                                           @"%@\n%@", nil),
               [exception reason],
               [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]]
      delegate:self
      cancelButtonTitle:NSLocalizedString(@"Quit", nil)
      otherButtonTitles:NSLocalizedString(@"Continue", nil), nil]
     autorelease];
    [alert show];

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);

    while (!self.dismissed)
    {
        for (NSString *mode in (NSArray *)allModes)
        {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    
    CFRelease(allModes);

    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
    {
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }
    else
    {
        [exception raise];
    }
}

#pragma mark - Exception Handler

void HandleException(NSException *exception)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
    {
        return;
    }

    NSArray *callStack = [PPDebugger backtrace];
    NSMutableDictionary *userInfo =
    [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo
     setObject:callStack
     forKey:UncaughtExceptionHandlerAddressesKey];

    NSException *handledException = [NSException exceptionWithName:[exception name]
                                                     reason:[exception reason]
                                                   userInfo:userInfo];

    [[PPDebugger sharedDebugger] performSelectorOnMainThread:@selector(handleException:)
                                                  withObject:handledException
                                               waitUntilDone:YES];
}

#pragma mark - Signal Handler

void SignalHandler(int signal)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
    {
        return;
    }

    NSMutableDictionary *userInfo =
    [NSMutableDictionary
     dictionaryWithObject:[NSNumber numberWithInt:signal]
     forKey:UncaughtExceptionHandlerSignalKey];

    NSArray *callStack = [PPDebugger backtrace];
    [userInfo
     setObject:callStack
     forKey:UncaughtExceptionHandlerAddressesKey];

    NSException *exception = [NSException
                              exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                              reason:
                              [NSString stringWithFormat:
                               NSLocalizedString(@"Signal %d was raised.", nil),
                               signal]
                              userInfo:
                              [NSDictionary
                               dictionaryWithObject:[NSNumber numberWithInt:signal]
                               forKey:UncaughtExceptionHandlerSignalKey]];

    [[PPDebugger sharedDebugger] performSelectorOnMainThread:@selector(handleException:)
                                                  withObject:exception
                                               waitUntilDone:YES];
}

#pragma mark - Install Debugger

void InstallUncaughtExceptionHandler()
{
    NSSetUncaughtExceptionHandler(&HandleException);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
}

@end
