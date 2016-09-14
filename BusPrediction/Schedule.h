//
//  Schedule.h
//  BusPrediction
//
//  Created by Li Bohan on 2/16/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Schedule : NSObject

@property (readonly) NSString *block;
@property (readonly) NSDictionary *scheduleOfStop; // key = stop title, Object = NSArray of NSinteger (int) epoch, -1 = no prediction

-(Schedule *)initWithBlock: (NSString*) block
			scheduleOfStop: (NSDictionary*) scheduleOfStop;

@end
