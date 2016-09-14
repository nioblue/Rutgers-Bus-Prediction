//
//  Prediction.h
//  BusPrediction
//
//  Created by Li Bohan on 2/13/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Prediction : NSObject

@property (readonly) unsigned int epoch; //time of day, for comparing with schedule
@property (readonly) NSString *time;
@property (readonly) NSString *block;
@property (readonly) unsigned short seconds;
@property (readonly) unsigned short vehicleID;

- (Prediction *)initWithEpoch: (unsigned long long) epoch
					  seconds: (unsigned short) seconds
					vehicleID: (unsigned short) vehicleID
						block: (NSString*) block;
- (NSString *)prediction;

@end
