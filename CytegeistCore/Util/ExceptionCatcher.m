//
//  ExceptionCatcher.m
//  CytegeistLibrary
//
//  Created by Aaron Moffatt on 7/27/24.
//

#import <Foundation/Foundation.h>

@interface ExceptionCatcher : NSObject
+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;
@end

@implementation ExceptionCatcher
+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.example" code:1 userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return NO;
    }
}
@end
