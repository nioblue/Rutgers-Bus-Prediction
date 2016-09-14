//
//  BusRoute.m
//  BusPrediction
//
//  Created by Li Bohan on 2/10/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "BusRoute.h"

@implementation BusRoute

- (BusRoute *)initWithTag:(NSString *)tag
					title:(NSString *)title
{
	self = [super init];
	if (self) {
		// Any custom setup work goes here
		_tag = tag;
		_title = title;
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat: @"tag=\"%@\" title=\"%@\"", _tag, _title];
}

@end
