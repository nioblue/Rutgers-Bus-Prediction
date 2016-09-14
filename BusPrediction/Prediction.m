//
//  Prediction.m
//  BusPrediction
//
//  Created by Li Bohan on 2/13/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "Prediction.h"
#import "Helper.h"

@implementation Prediction

- (Prediction *)initWithEpoch: (unsigned long long) epoch
					  seconds: (unsigned short) seconds
					vehicleID: (unsigned short) vehicleID
						block: (NSString*) block
{
	self = [super init];
	if (self) {
		_epoch = [Helper convertToLocalDateFrom:[NSDate dateWithTimeIntervalSince1970:epoch/1000]];  //time of day
		NSDateFormatter* dateFormatter = [NSDateFormatter new];
		[dateFormatter setDateFormat:@"hh:mm a"];
		_time = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
		_seconds = seconds;
		_vehicleID = vehicleID;
		_block = block;
	}
	return self;
}

- (NSString *)description
{
	unsigned short minutes = _seconds / 60;
	if (minutes > 0)
		return [NSString stringWithFormat:@"%d min at %@, Bus ID: %d", minutes, _time, _vehicleID];
	else
		return [NSString stringWithFormat:@"%d sec at %@, Bus ID: %d", _seconds, _time, _vehicleID];
}

- (NSString *)prediction
{
	unsigned short minutes = _seconds / 60;
	if (minutes > 0)
		return [NSString stringWithFormat:@"%d minute%@ at %@",
				minutes, minutes == 1 ? @"" : @"s", _time];
	else
		return [NSString stringWithFormat:@"%d second%@ at %@",
				_seconds, _seconds == 1 ? @"" : @"s", _time];
}

@end
