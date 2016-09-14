//
//  PredictionAtStop.h
//  BusPrediction
//
//  Created by Li Bohan on 2/13/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BusRoute.h"
#import "Stop.h"
#import "Prediction.h"

@interface RouteAndStop : NSObject

@property (readonly, weak) Stop *stop;	//TODO: make sure 'weak' here is correct
@property (readonly, weak) BusRoute *route;
@property NSString *direction;
@property NSArray *predictions; //Has to be ordered by ascending time to arrive
@property NSString *message;

-(RouteAndStop *)initWithRoute: (BusRoute*) route
							   stop: (Stop*) stop;
-(Prediction *)predictionWithVehicleID: (unsigned short) vehicleID;

@end
