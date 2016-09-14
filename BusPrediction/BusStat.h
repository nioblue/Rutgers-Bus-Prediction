//
//  BusStat.h
//  BusPrediction
//
//  Created by Li Bohan on 2/15/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BusRoute.h"

@interface BusStat : NSObject

@property (readonly) BusRoute *busRoute;
@property (readonly) unsigned short vehicleID;
@property (readonly) NSString *block;
@property double lat;
@property double lon;
@property unsigned short secsSinceReport;

-(BusStat *)initWithBusRoute: (BusRoute*) busRoute
				   vehicleId: (unsigned short) vehicleID
					   block: (NSString*) block;

@end
