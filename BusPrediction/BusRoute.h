//
//  BusRoute.h
//  BusPrediction
//
//  Created by Li Bohan on 2/10/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BusRoute : NSObject

@property (readonly) NSString *tag;
@property (readonly) NSString *title;
@property NSArray *routeAndStopInOrder; //Ordered to order of stop
@property NSDictionary *routeAndStop;	//Key = stoptag, same objects as above.


-(BusRoute*)initWithTag:(NSString *)tag
				  title:(NSString *)title;

@end
