//
//  NSURL+UnzipKitExtensions.m
//  UnzipKit
//
//  Created by Dov Frankel on 6/29/16.
//  Copyright © 2016 Abbey Code. All rights reserved.
//

#import "NSURL+UnzipKitExtensions.h"

@implementation NSURL (UnzipKitExtensions)

- (NSString *)volumeName {
    
    if (!self.isFileURL) {
        return nil;
    }
    
    NSError *error = nil;
    NSString *result = nil;
    
    [self getResourceValue:&result forKey:NSURLVolumeNameKey error:&error];
    
    if (!result && error) {
        NSLog(@"Error retrieving volume name of %@: %@", self.path, error);
    }
    
    return result;
}

@end
