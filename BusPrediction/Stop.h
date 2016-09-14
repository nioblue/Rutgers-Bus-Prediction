//
//  Stop.h
//  BusPrediction
//
//  Created by Li Bohan on 2/11/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Stop : NSObject

@property (readonly) NSString *tag;
@property (readonly) NSString *title;
@property (readonly) unsigned short stopId;
@property NSMutableArray *routeAndStop; //Ordered to order of busroute

-(Stop *)initWithTag: (NSString *) tag
			   title: (NSString *) title
			  stopID: (unsigned short) stopId;
-(NSComparisonResult) compare: (Stop *) stop;

@end
