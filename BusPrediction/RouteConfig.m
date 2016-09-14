//
//  RouteConfig.m
//  BusPrediction
//
//  Created by Li Bohan on 2/12/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "RouteConfig.h"
#import "Helper.h"
#import "BusRoute.h"
#import "Stop.h"
#import "RouteAndStop.h"

@implementation RouteConfig

//This method should run on another thread because it has a blocking method
- (RouteConfig *)initWithAgency:(NSString *)agency {
	self = [super init];
	if (self) {
		// Any custom setup work goes here
		NSMutableArray *mutableAllRoutesInOrder = [NSMutableArray new];
		NSMutableDictionary *mutableAllRoutes = [NSMutableDictionary new];
		NSMutableDictionary *mutableAllStops = [NSMutableDictionary new];
		NSMutableArray *stopsForRoute = [NSMutableArray new];
		NSMutableDictionary *stopsForRouteDict = [NSMutableDictionary new];
		
		NSArray *allLines = [[Helper getDataFrom:[NSString stringWithFormat:@"http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=%@", agency]] componentsSeparatedByString:@"\n"];
		if (allLines == nil)
			return nil;
		for (NSString* line in allLines)
		{
			if ([line hasPrefix:@"<route"])
			{
				NSString* tag = [Helper substring:line fromString:@"tag=\"" toString:@"\""];
				NSString* title = [Helper substring:line fromString:@"title=\"" toString:@"\""];
				BusRoute* route = [[BusRoute alloc] initWithTag:tag
													title: title];
				[mutableAllRoutesInOrder addObject:route];
				[mutableAllRoutes setObject:route forKey:tag];
			} else if ([line hasPrefix:@"<stop"])
			{
				NSString* tag = [Helper substring:line fromString:@"tag=\"" toString:@"\""];
				NSString* title = [Helper substring:line fromString:@"title=\"" toString:@"\""];
				unsigned short stopId = (unsigned short)[[Helper substring:line fromString:@"stopId=\"" toString:@"\""] intValue];
				
				Stop* stop = [mutableAllStops objectForKey:tag];
				if(!stop)
				{
					stop = [[Stop alloc] initWithTag:tag title:title stopID:stopId];
					[mutableAllStops setObject:stop forKey:tag];
				}
				RouteAndStop* sp = [[RouteAndStop  alloc] initWithRoute:
										 [mutableAllRoutesInOrder lastObject] stop:stop];
				[stopsForRoute addObject:sp];
				[stopsForRouteDict setObject:sp forKey:tag];
			} else if ([line isEqualToString:@"</route>"])
			{
				BusRoute* route = [mutableAllRoutesInOrder lastObject];
				route.routeAndStopInOrder = [stopsForRoute copy];
				route.routeAndStop = [stopsForRouteDict copy];
				[stopsForRoute removeAllObjects];
				[stopsForRouteDict removeAllObjects];
			}
		}
		allLines = nil; //Signal ARC to release
		_allRoutesInOrder = [mutableAllRoutesInOrder copy];
		_allRoutes = [mutableAllRoutes copy];
		_allStops = [mutableAllStops copy];
		_allStopsInOrder = [[_allStops allValues]
								 sortedArrayUsingSelector: @selector(compare:)];
		NSMutableDictionary* mutableUniqueStops = [NSMutableDictionary new];
		for (Stop* stop in _allStopsInOrder)
		{
			NSMutableArray* stops = [mutableUniqueStops objectForKey:stop.title];
			if (!stops)
			{
				stops = [NSMutableArray new];
				[mutableUniqueStops setObject:stops forKey: stop.title];
			}
			[stops addObject:stop];
		}
		_uniqueStops = [mutableUniqueStops copy];
		_uniqueStopsInOrder = [[_uniqueStops allValues]
							   sortedArrayUsingFunction:stopSort context: NULL];
		
		/** Linking stopAndPrediction for all bus stops **/
		for (BusRoute* route in _allRoutesInOrder)
			for (RouteAndStop* sp in route.routeAndStopInOrder)
				[((Stop*)[_allStops objectForKey:sp.stop.tag]).routeAndStop addObject: sp];
	}
	return self;
}

/** Sorting uniqueStops array, all should have same title **/
NSInteger stopSort (id obj1, id obj2, void* context)
{
	Stop* s1 = [((NSArray*) obj1) objectAtIndex:0];
	Stop* s2 = [((NSArray*) obj2) objectAtIndex:0];
	return [s1.title caseInsensitiveCompare:s2.title];
}

@end
