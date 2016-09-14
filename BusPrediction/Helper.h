//
//  Helper.h
//  BusPrediction
//
//  Created by Li Bohan on 2/12/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject

+ (NSString *) getDataFrom:(NSString *)url;
+ (NSString *) substring: (NSString*)str
			  fromString: (NSString*)from
				toString: (NSString*)to;
+ (unsigned int) convertToLocalDateFrom: (NSDate*) date;
+ (BOOL) isAtRSCWithLat: (double)lat Lon: (double)lon;
+ (BOOL) isAtBCCWithRouteTag: (NSString*) route
			   NextStopTitle: (NSString*) stop;
+ (BOOL) isAtBCCWithLat: (double)lat Lon: (double)lon;
+ (BOOL) isAtLSCWithRouteTag: (NSString*) route
			   NextStopTitle: (NSString*) stop;
+ (BOOL) isAtLSCWithLat: (double)lat Lon: (double)lon;
+ (BOOL) isAtRedOakWithLat: (double)lat Lon: (double)lon;

@end
