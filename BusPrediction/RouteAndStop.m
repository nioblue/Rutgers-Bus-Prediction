//
//  PredictionAtStop.m
//  BusPrediction
//
//  Created by Li Bohan on 2/13/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "RouteAndStop.h"
#import "BusRoute.h"
#import "Stop.h"
#import "Prediction.h"

@implementation RouteAndStop

-(RouteAndStop *)initWithRoute: (BusRoute*) route
							   stop: (Stop*) stop
{
	self = [super init];
	if (self) {
		// Any custom setup work goes here
		_route = route;
		_stop = stop;
	}
	return self;
}

/**
 * Finds the appropriate prediction with the given vehicleID.
 * If the given vehicleID is not found, then nil is returned
 */
-(Prediction *)predictionWithVehicleID: (unsigned short) vehicleID
{
	for (Prediction* p in self.predictions)
		if (p.vehicleID == vehicleID)
			return p;
	return nil;
}

@end
