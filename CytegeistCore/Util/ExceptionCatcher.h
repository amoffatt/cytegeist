//
//  ExceptionCatcher.h
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

#ifndef ExceptionCatcher_h
#define ExceptionCatcher_h

#import <Foundation/Foundation.h>

@interface ExceptionCatcher : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end


#endif /* ExceptionCatcher_h */
