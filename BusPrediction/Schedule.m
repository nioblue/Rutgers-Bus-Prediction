//
//  Schedule.m
//  BusPrediction
//
//  Created by Li Bohan on 2/16/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "Schedule.h"

@implementation Schedule

-(Schedule *)initWithBlock: (NSString*) block
			scheduleOfStop: (NSDictionary*) scheduleOfStop
{
	self = [super init];
	if (self) {
		// Any custom setup work goes here
		_block = block;
		_scheduleOfStop = scheduleOfStop;
	}
	return self;
}


@end
