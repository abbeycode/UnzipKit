//
//  Objective-Zip.h
//  Objective-Zip
//
//  Created by Dov Frankel on 12/10/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    #import <UIKit/UIKit.h>
#elif defined TARGET_OS_MAC
    #import <Cocoa/Cocoa.h>
#endif


//! Project version number for Objective-Zip.
FOUNDATION_EXPORT double Objective_ZipVersionNumber;

//! Project version string for Objective-Zip.
FOUNDATION_EXPORT const unsigned char Objective_ZipVersionString[];

#import <ObjectiveZip/FileInZipInfo.h>
#import <ObjectiveZip/ZipException.h>
#import <ObjectiveZip/ZipFile.h>
#import <ObjectiveZip/ZipReadStream.h>
#import <ObjectiveZip/ZipWriteStream.h>