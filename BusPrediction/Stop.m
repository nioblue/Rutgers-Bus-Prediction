//
//  Stop.m
//  BusPrediction
//
//  Created by Li Bohan on 2/11/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "Stop.h"

@implementation Stop

- (Stop *)initWithTag: (NSString *) tag
				title: (NSString *) title
			   stopID: (unsigned short) stopId
{
	self = [super init];
	if (self) {
		// Any custom setup work goes here
		_tag = tag;
		_title = title;
		_stopId = stopId;
		_routeAndStop = [NSMutableArray new];
	}
	return self;
}

-(NSComparisonResult) compare: (Stop *) stop
{
	return [_title caseInsensitiveCompare:[stop title]];
}

- (NSString *)description {
	return [NSString stringWithFormat: @"tag=\"%@\" title=\"%@\" stopID=\"%du\"", _tag, _title, _stopId];
}

@end
