//
//  UnzipKitMacros.h
//  UnzipKit
//
//  Created by Dov Frankel on 7/10/17.
//  Copyright © 2017 Abbey Code. All rights reserved.
//

#ifndef UnzipKitMacros_h
#define UnzipKitMacros_h

//#import "Availability.h"
//#import "AvailabilityInternal.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#pragma clang diagnostic ignored "-Wgnu-zero-variadic-macro-arguments"


// iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0
#define UNIFIED_LOGGING_SUPPORTED \
    __IPHONE_OS_VERSION_MIN_REQUIRED >= 100000 \
    || __MAC_OS_X_VERSION_MIN_REQUIRED >= 101200 \
    || __TV_OS_VERSION_MIN_REQUIRED >= 100000 \
    || __WATCH_OS_VERSION_MIN_REQUIRED >= 30000

#if UNIFIED_LOGGING_SUPPORTED
@import os.log;

// Called from +[UnzipKit initialize] and +[UZKArchiveTestCase setUp]
extern os_log_t unzipkit_log; // Declared in UZKArchive.m
#define UZKLogInit() unzipkit_log = os_log_create("com.abbey-code.UnzipKit", "General");

#define UZKLog(format, ...)      os_log(unzipkit_log, format, ##__VA_ARGS__);
#define UZKLogInfo(format, ...)  os_log_info(unzipkit_log, format, ##__VA_ARGS__);
#define UZKLogDebug(format, ...) os_log_debug(unzipkit_log, format, ##__VA_ARGS__);

#define UZKLogError(format, ...) os_log_error(unzipkit_log, format, ##__VA_ARGS__);
#define UZKLogFault(format, ...) os_log_fault(unzipkit_log, format, ##__VA_ARGS__);

#else // Fall back to regular NSLog

// No-op, as nothing needs to be initialized
#define UZKLogInit() (void)0

// All levels do the same thing
#define UZKLog(format, ...) NSLog(@format, ##__VA_ARGS__);
#define UZKLogInfo(format, ...) NSLog(@format, ##__VA_ARGS__);
#define UZKLogDebug(format, ...) NSLog(@format, ##__VA_ARGS__);
#define UZKLogError(format, ...) NSLog(@format, ##__VA_ARGS__);
#define UZKLogFault(format, ...) NSLog(@format, ##__VA_ARGS__);
#endif


#pragma clang diagnostic pop

#endif /* UnzipKitMacros_h */
