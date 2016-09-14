//
//  BusStat.m
//  BusPrediction
//
//  Created by Li Bohan on 2/15/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "BusStat.h"
#import "BusRoute.h"

@implementation BusStat

-(BusStat *)initWithBusRoute: (BusRoute*) busRoute
				   vehicleId: (unsigned short) vehicleID
					   block: (NSString*) block
{
	self = [super init];
	if (self) {
		// Any custom setup work goes here
		_busRoute = busRoute;
		_vehicleID = vehicleID;
		_block = block;
		_lat = 0;
		_lon = 0;
		_secsSinceReport = USHRT_MAX;
	}
	return self;
}

@end
