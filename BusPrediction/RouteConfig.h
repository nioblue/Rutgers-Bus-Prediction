//
//  RouteConfig.h
//  BusPrediction
//
//  Created by Li Bohan on 2/12/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RouteConfig : NSObject

/**
 * allRoutesInOrder and allRoutes hold the same pointers to routes. The NSDictionary
 * just provides an easier way to access the BusRoutes
 */
@property (readonly) NSArray *allRoutesInOrder;
// TODO: determine if allStopsInAlphaOrder is needed. Remove if not
@property (readonly) NSArray *allStopsInOrder;
/** There maybe stops of the same name using different tags, next structure accomdates that **/
@property (readonly) NSArray *uniqueStopsInOrder;
@property (readonly) NSDictionary *allRoutes;	//Key = tag, object = BusRoute
@property (readonly) NSDictionary *allStops;	//Key = tag, object = Stop
@property (readonly) NSDictionary *uniqueStops;	//Key = title, object = Stop mutable array

- (RouteConfig *)initWithAgency:(NSString *)agency;

@end
