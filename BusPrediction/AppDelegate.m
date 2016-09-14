//
//  AppDelegate.m
//  BusPrediction
//
//  Created by Li Bohan on 2/10/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "AppDelegate.h"
#import "Helper.h"
#import "BusRoute.h"
#import "Stop.h"
#import "RouteConfig.h"
#import "RouteAndStop.h"
#import "Prediction.h"
#import "BusStat.h"
#import "Schedule.h"

#define GLOBAL_DEFAULT dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@implementation AppDelegate {
	RouteConfig* routeConfig;
	NSArray* activeRoutes;	//BusRoute objects of active routes
	NSArray* activeStops;	//Stop objects of active stops
	NSMutableDictionary* messages; //key = object = (string) message
	NSMutableDictionary* allSchedule; //key = (string) block, object = schedule; see Schedule.h
	BOOL isUpdating, occluded;
	NSString* noPrediction;
	BusStat* currentBusStat;
	long long epochDiff;	//Server time - my time = epochDiff in seconds
	char segCellIndex;	//Previous segCell index ie. before action
	NSTimer *myTimer;
}

- (AppDelegate *)init{
	self = [super init];
	if (self) {
		// Any custom setup work goes here
		routeConfig = nil;
		_agency = @"rutgers";
		isUpdating = occluded = NO;
		noPrediction = @"No predictions";
		currentBusStat = nil;
		allSchedule = [NSMutableDictionary new];
		epochDiff = LONG_LONG_MAX;
		segCellIndex = 0;
		myTimer = nil;
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	[_browser setDelegate:self];
	[_table setDataSource:self];
	[_busStatWindow setDelegate:self];
	[_browser setDoubleAction:@selector(browserDoubleClicked)];
	[self refreshRoute];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void)applicationDidChangeOcclusionState:(NSNotification *)notification
{
	if ([NSApp occlusionState] & NSApplicationOcclusionStateVisible)
		if (occluded)
		{
			NSLog(@"Unoccluded!");
			occluded = NO;
			[self timerTick];
		}
}

- (void)windowWillClose:(NSNotification *)notification
{
	if ([notification object] == _busStatWindow)
	{
		[myTimer invalidate];
		NSLog(@"Timer invalidated");
	}
}

- (IBAction)refreshRouteAction:(id)sender
{
	[self refreshRoute];
}

-(void) updating: (BOOL)updating
{
	isUpdating = updating;
	dispatch_async(dispatch_get_main_queue(), ^{
		if(updating)
			[_progress startAnimation:nil];
		else
			[_progress stopAnimation:nil];
	});
}

- (IBAction)refreshPredictAction:(id)sender {
	
	if (isUpdating)
		return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self updating:YES];
	[self refreshPredict];
}

- (IBAction)browserAction:(NSBrowser *)sender {
	//Potential Bug!!! If a route prediction fetching is going on while this is called, new prediction will not be loaded.
	//Possible fix: throw refreshPredict into GCD serial queue.
	if (!isUpdating && [sender selectedColumn] == 0 &&
		[sender selectedRowInColumn:0] < [activeRoutes count])
	{
		NSLog(@"Browser column 0 selection");
		[self updating:YES];
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self refreshPredict];
	}
}

- (IBAction)segCellAction:(id)sender {
	NSLog(@"Selected index: %d", (int)[sender selectedSegment]);
	if ([sender selectedSegment] != segCellIndex)
	{
		segCellIndex = [sender selectedSegment];
		//Refresh prediction based on selected option
	}
}

//Has to be called from main thread
- (void) browserDoubleClicked {
	if ([_browser selectedColumn] == 2 &&
		![((NSCell*)[_browser selectedCell]).title isEqualToString: noPrediction])
	{
		BusRoute* route = [activeRoutes objectAtIndex:[_browser selectedRowInColumn:0]];
		RouteAndStop* stop = [route.routeAndStopInOrder objectAtIndex:[_browser selectedRowInColumn:1]];
		Prediction* p = [stop.predictions objectAtIndex:[_browser selectedRowInColumn:2]];
		currentBusStat = [[BusStat alloc] initWithBusRoute:route vehicleId:p.vehicleID block: p.block];
		[_busStatWindow setTitle:[NSString stringWithFormat:@"%@ Bus, ID: %d, Block: %@", route.title,  p.vehicleID, p.block]];
		//Todo: Remove block from title, put it in seperate UI, labeled under advanced.
		_image.image = nil;
		[_statusLabel setStringValue:@"Status: updating..."];
		[_label setStringValue:@""];
		currentBusStat.secsSinceReport = USHRT_MAX;
		[_busStatWindow makeKeyAndOrderFront:self];
		[self refreshBusStatWindow];
		[_table reloadData];
	}
}

//Does not have to be called from main thread, but is
- (void) timerTick
{
	if (!([NSApp occlusionState] & NSApplicationOcclusionStateVisible))
	{
		NSLog(@"Occluded!");
		[myTimer invalidate];
		occluded = YES;
		return;
	}
	NSLog(@"Timer tick");
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self updating:YES];
	[self refreshPredict];
}

//Has to be called from main thread, timer runs on main thread
- (void) updateSecsSinceReport
{
	[_label setStringValue:
	 [NSString stringWithFormat:@"Bus location reported %d seconds ago:",
	  currentBusStat.secsSinceReport++]];
}

//This method runs on another thread, does not have to be called from main thread
- (void) refreshRoute
{
	if (isUpdating)
		return;
	[self updating:YES];
	dispatch_group_t myGroup = dispatch_group_create();
	if (!routeConfig)
	{
		dispatch_group_async(myGroup, GLOBAL_DEFAULT, ^{
			routeConfig = [[RouteConfig alloc] initWithAgency:_agency];
		});
	}
	
	dispatch_async(GLOBAL_DEFAULT, ^{
		NSMutableSet* set = [NSMutableSet new];
		
		NSArray *allLines =
		[[Helper getDataFrom:
		  [NSString stringWithFormat:@"http://webservices.nextbus.com/service/publicXMLFeed?command=vehicleLocations&a=%@&t=0", _agency]]
							 componentsSeparatedByString:@"\n"];
		for (NSString* line in allLines)
			if ([line hasPrefix:@"<vehicle id="])
				[set addObject: [Helper substring:line fromString:@"routeTag=\"" toString:@"\""]];
		
		allLines = nil; //Signal ARC to release
		dispatch_group_wait(myGroup, DISPATCH_TIME_FOREVER);
		if (routeConfig == nil)
		{
			// connection error do something
			return;
		}
		NSMutableArray* mutableActiveRoutes = [routeConfig.allRoutesInOrder mutableCopy];
		for (int i = 0; i < [mutableActiveRoutes count]; i++)
			if (![set containsObject:((BusRoute*)[mutableActiveRoutes objectAtIndex:i]).tag])
				[mutableActiveRoutes removeObjectAtIndex: i--];
		activeRoutes = [mutableActiveRoutes copy];
		
		set = [NSMutableSet new]; //Set of stop titles
		for (BusRoute* bus in activeRoutes)
			for (RouteAndStop* rs in bus.routeAndStopInOrder)
				[set addObject:rs.stop.title];
		
		NSMutableArray* mutableActiveStops = [routeConfig.uniqueStopsInOrder mutableCopy];
		for (int i = 0; i < [mutableActiveStops count]; i++)
		{
			NSArray* stop = [mutableActiveStops objectAtIndex:i];
			if (![set containsObject:((Stop*)[stop objectAtIndex:0]).title])
				[mutableActiveStops removeObjectAtIndex: i--];
		}	//TODO: Test this at night
		activeStops = [mutableActiveStops copy];
		
		[self updating:NO];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_browser reloadColumn:0];
			[_browser reloadColumn:1];
		});
	});
}

//This method runs on another thread, does not have to be called from main thread.
-(void) refreshPredict
{
	dispatch_async(GLOBAL_DEFAULT, ^{
		unsigned long selectedRouteIndex = [_browser selectedRowInColumn:0];
		if (selectedRouteIndex == -1 || selectedRouteIndex >= [activeRoutes count])
		{
			[self updating:NO];
			return;
		}
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		
		//TODO: Implement Bus Stop view (contrast to route view)
		NSMutableString* query = [NSMutableString stringWithCapacity:500];
		[query appendString:@"http://webservices.nextbus.com/service/publicXMLFeed?command=predictionsForMultiStops&a="];
		[query appendString:_agency];
		BusRoute* route = [activeRoutes objectAtIndex:selectedRouteIndex];
		for (RouteAndStop* stop in route.routeAndStopInOrder)
			[query appendString:[NSString stringWithFormat:@"&stops=%@%%7C%@", route.tag, stop.stop.tag]];

		/** if currentBusStat is showing a different route than our main window, we also fetch prediction for Busstat **/
		if (currentBusStat && route != currentBusStat.busRoute)
			for (RouteAndStop* stop in currentBusStat.busRoute.routeAndStopInOrder)
				[query appendString:[NSString stringWithFormat:@"&stops=%@%%7C%@", currentBusStat.busRoute.tag, stop.stop.tag]];
		
		NSArray *allLines = [[Helper getDataFrom:query] componentsSeparatedByString:@"\n"];
		RouteAndStop* currStop = nil;
		NSMutableArray* predictions = [NSMutableArray new];
		messages = [NSMutableDictionary new];
		for (NSString* l in allLines)
		{
			NSString* line = [l stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if ([line hasPrefix:@"<predictions"])
			{
				NSString* routeTag = [Helper substring:line
											fromString:@"routeTag=\"" toString:@"\""];
				NSString* stopTag = [Helper substring:line
										   fromString:@"stopTag=\"" toString:@"\""];
				//predictions = [NSMutableArray new];
				currStop = [((BusRoute*)[routeConfig.allRoutes objectForKey:routeTag]).routeAndStop objectForKey:stopTag];
			} else if ([line hasPrefix:@"<direction"])
			{
				currStop.direction = [Helper substring:line
											fromString:@"title=\"" toString:@"\""];
				//Todo: Remove directions if we don't need it
				/**
				 * TODO: Student Activities Center direction for wknd1 and s:
				 * stuactcntr = Student Activities Center (To Busch)
				 * stuactcntrs = Student Activities Center (To Cook/Doug)
				 * stuactcntrn_2 = Student Activities Center (To RSC)
				 */
			} else if ([line hasPrefix:@"<prediction "])
			{
				unsigned long long epoch = [[Helper substring:line
											  fromString:@"epochTime=\""
												toString:@"\""] longLongValue];
				unsigned short seconds = [[Helper substring:line
												 fromString:@"seconds=\""
												   toString:@"\""] intValue];
				unsigned short vehicleId = [[Helper substring:line
												   fromString:@"vehicle=\""
													 toString:@"\""] intValue];
				NSString* block = [Helper substring:line
										 fromString:@"block=\"" toString:@"\""];
				[predictions addObject:[[Prediction alloc]
										initWithEpoch: epoch
										seconds: seconds
										vehicleID: vehicleId
										block: block]];
				//Update our time difference with server on first run
				if (epochDiff == LONG_LONG_MAX)
				{
					epoch = epoch / 1000;	//Seconds epoch
					epoch -= seconds;		//Server time
					/** Server time minus local machine time **/
					epochDiff = epoch - [[NSDate date] timeIntervalSince1970];
					NSLog(@"epochDiff: %lld", epochDiff);
				}
			} else if ([line hasPrefix:@"<message "])
			{
				NSString* message = [Helper substring:line fromString:@"text=\"" toString:@"\""];
				NSString* tmp;
				if ((tmp = [messages objectForKey:message]) == nil)
				{
					[messages setObject:message forKey:message];
					tmp = message;
				}
				currStop.message = tmp;
			} else if ([line isEqualToString:@"</predictions>"])
			{
				currStop.predictions = [predictions copy];
				[predictions removeAllObjects];
			}
		}
		[self refreshBusStatWindow];
		[self updating:NO];
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([messages count] == 1)
				[_browser reloadColumn:0];
			[_browser reloadColumn:2];
			[_table reloadDataForRowIndexes:
			 [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, [currentBusStat.busRoute.routeAndStopInOrder count])]
							  columnIndexes: [NSIndexSet indexSetWithIndex: 1]];
			[self performSelector:@selector(timerTick)
					   withObject:nil afterDelay:10];
		});
		
	});
}

//This method runs on another thread, does not have to be called from main thread.
- (void) refreshBusStatWindow
{
	if (!currentBusStat || ![_busStatWindow isVisible])
		return;
	/** lets first thread signal second thread that veh location has been updated **/
	__block NSCondition* cond = [NSCondition new];
	__block double lat = 200, lon = 200;
	//__block unsigned char speed = UCHAR_MAX;
	/** first thread, handles vehicle location and map **/
	dispatch_async(GLOBAL_DEFAULT, ^{
		NSArray *allLines =
		[[Helper getDataFrom: [NSString stringWithFormat:@"http://webservices.nextbus.com/service/publicXMLFeed?command=vehicleLocations&a=%@&t=0", _agency]] componentsSeparatedByString:@"\n"];
		//NSLog(@"Done fetching vehicle locations");
		for (NSString* line in allLines)
		{
			if ([line hasPrefix:[NSString stringWithFormat:@"<vehicle id=\"%d\"", currentBusStat.vehicleID]])
			{
				[cond lock];
				lat = [[Helper substring:line fromString:@"lat=\"" toString:@"\""] doubleValue];
				lon = [[Helper substring:line fromString:@"lon=\"" toString:@"\""] doubleValue];
				[cond signal];
				[cond unlock];
				unsigned short secsSinceReport =
				[[Helper substring:line
						fromString:@"secsSinceReport=\""
						  toString:@"\""] intValue];
				if (abs(secsSinceReport - currentBusStat.secsSinceReport) > 1)
				{
					NSLog(@"Not equal");
					currentBusStat.secsSinceReport = secsSinceReport;
					if (![myTimer isValid])
					{
						dispatch_async(dispatch_get_main_queue(), ^{
							myTimer =
							[NSTimer scheduledTimerWithTimeInterval:1.0
															 target:self
											selector:@selector(updateSecsSinceReport)
														   userInfo:nil
															repeats:YES];
							[myTimer setTolerance:0.1];
							[myTimer fire];
						});
					}
				}
				//speed = [[Helper substring:line fromString:@"speedKmHr=\"" toString:@"\""] intValue];
				/** Signal second thread that veh location has been updated **/
				if (fabs(currentBusStat.lat - lat) > 0.0001 ||
					fabs(currentBusStat.lon - lon) > 0.0001)
				{
					NSLog(@"Fetching new map");
					currentBusStat.lat = lat;
					currentBusStat.lon = lon;
					NSSize size =  _image.frame.size;
					NSString* url =
					[NSString stringWithFormat:
					 @"http://maps.googleapis.com/maps/api/staticmap?center=%f,%f%@%d%c%d%@%f%c%f&sensor=false&key=AIzaSyAlhVL3OkbdTQn7KiqqcpS9jnEeIOSncoY",
					 lat, lon, @"&zoom=15&scale=2&size=",
					 (int) size.width, 'x', (int) size.height,
					 @"&style=feature:poi%7Celement:labels%7Cvisibility:off&markers=icon:http://chart.apis.google.com/chart?chst=d_map_pin_icon%26chld=bus%257CFF3333%7C",
									lat,',',lon];
					//NSLog(url);
					NSURL *imageURL = [NSURL URLWithString: url];
					NSData *imageData = [imageURL resourceDataUsingCache:NO];
					NSImage *imageFromBundle = [[NSImage alloc] initWithData:imageData];
					dispatch_async(dispatch_get_main_queue(), ^{
						_image.image = imageFromBundle;
					});
				}
				break;
			}
			//Todo: make a vehicleLocations class
		}
	});
	
	/** second thread, handles status **/
	dispatch_async(GLOBAL_DEFAULT, ^{
		
		Schedule* schedule = [allSchedule objectForKey:currentBusStat.block];
		if (!schedule) //no such schedule in cache, gotta retrieve
		{
			NSLog(@"Fetching schedule");
			NSArray *allLines =
			[[Helper getDataFrom: [NSString stringWithFormat:@"http://webservices.nextbus.com/service/publicXMLFeed?command=schedule&a=%@&r=%@",
								   _agency, currentBusStat.busRoute.tag]] componentsSeparatedByString:@"\n"];
			/** 
			 * Setting up an NSDictionary for conversion of stoptag and stop title
			 * Using title because RSC somehow has 2 different tags,
			 * rutgerss_a and rutgerss
			 * Key = stopTag, Object = stopTitle
			 */
			NSMutableDictionary* stopTitles = [NSMutableDictionary new];
			/** Key = stopTitle, Object = epochs array **/
			NSMutableDictionary* stop = [NSMutableDictionary new];
			BOOL inBlock = NO, inHeader = NO;
			for (NSString* l in allLines)
			{
				NSString* line = [l stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				if (!inHeader && [line isEqualToString:@"<header>"])
					inHeader = YES;
				else if (inHeader && [line hasPrefix:@"<stop"])
				{
					NSString* stopTag = [Helper substring:line fromString:@"tag=\"" toString:@"\""];
					NSString* stopTitle = [Helper substring:line fromString:@"\">" toString:@"</stop>"];
					/** Used to identify bus schedule by title **/
					/** Some buses have schedules for bus stops with same name but different tags, this implementation happens to fix that **/
					[stopTitles setObject:stopTitle forKey:stopTag];
				}
				else if (inHeader && [line isEqualToString:@"</header>"])
					inHeader = NO;
				else if (!inBlock && [line isEqualToString:[NSString stringWithFormat:@"<tr blockID=\"%@\">", currentBusStat.block]])
					inBlock = YES;
				else if (inBlock && [line hasPrefix:@"<stop"])
				{
					NSString* stopTitle = [stopTitles objectForKey: [Helper substring:line fromString:@"tag=\"" toString:@"\""]];
					/*if ([routeConfig.allStops objectForKey:stopTag] != nil)
						stopTag = ((Stop*)[routeConfig.allStops objectForKey:stopTag]).tag;*/
					//^^Used so that schedule uses same string, reducing memory usage
					int epoch = [[Helper substring:line fromString:@"epochTime=\"" toString:@"\""] intValue];
					epoch = epoch == -1 ? -1 : epoch / 1000%(60*60*24);
					NSMutableArray* epochs = [stop objectForKey:stopTitle];
					if (!epochs)
					{
						epochs = [NSMutableArray new];
						[stop setObject:epochs forKey:stopTitle];
					}
					[epochs addObject:[NSNumber numberWithInt:epoch]];
				} else if (inBlock && [line isEqualToString:@"</tr>"])
					inBlock = NO;
			}
			schedule = [[Schedule alloc] initWithBlock:currentBusStat.block scheduleOfStop:[stop copy]];
			[allSchedule setObject:schedule forKey:currentBusStat.block];
			//Todo: cache all running blocks, not just the active block.
			//Option 1: save the entire url as file
			//Option 2: use set to store all running blocks, store all running blocks to cache
		}
		
		RouteAndStop* nextStop = nil;
		unsigned int epoch = UINT_MAX;
		unsigned short seconds = USHRT_MAX;
		//Looping to find the next scheduled stop the bus will be approaching
		for (RouteAndStop* stop in currentBusStat.busRoute.routeAndStopInOrder)
		{
			Prediction* p = [stop predictionWithVehicleID:currentBusStat.vehicleID];
			/** If there is no prediction or no schedule for this bus at this stop, we go to next stop **/
			if (!p || ![schedule.scheduleOfStop objectForKey:stop.stop.title])
				continue;
			
			/** Finding a scheduled bus stop where the current bus has a prediction for so we can compare against other stops **/
			/** Or if we found a bus stop already but this new one we found has shorter prediction **/
			if (!nextStop || p.seconds < seconds)
			{
				nextStop = stop;
				epoch = p.epoch;
				seconds = p.seconds;
			}
		}
		//If nextStop is still nil after the above loop, then don't put status on statusLabel. There are schedule for this bus
		if (!nextStop)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[_statusLabel setStringValue:@"Schedule unavailable. Prediction may be inaccurate."];
			});
			return;
		}
		NSLog(@"Next stop: %@", nextStop.stop.title);
		
		/** status will not be nil if bus is at a control point **/
		NSString* status = nil;
		/** Checking if bus is at a control point **/
		/** 
		 * If a bus at RSC, we use schedule to determine when the bus will be
		 * leaving this stop. Also checking if "Rutgers Student Center" exists in
		 * case that bus route changes in the future
		 */
		NSString* controlPoint;
		BOOL atControlPoint = NO;
		NSArray* schedules;
		if (([nextStop.stop.title isEqualToString:@"Scott Hall"] ||
			 [nextStop.stop.title isEqualToString:@"Rutgers Student Center"]) &&
			(schedules = [schedule.scheduleOfStop objectForKey:@"Rutgers Student Center"]) != nil)
		{
			[cond lock];
			while (lat == 200 || lon == 200)
				[cond wait];
			[cond unlock];
			atControlPoint = [Helper isAtRSCWithLat:lat Lon:lon];
			controlPoint = @"RSC";
		} else if ([Helper isAtBCCWithRouteTag:currentBusStat.busRoute.tag
								 NextStopTitle:nextStop.stop.title] &&
				 (schedules = [schedule.scheduleOfStop objectForKey:@"Busch Campus Center"]) != nil)
		{
			[cond lock];
			while (lat == 200 || lon == 200)
				[cond wait];
			[cond unlock];
			atControlPoint = [Helper isAtBCCWithLat:lat Lon:lon];
			controlPoint = @"BCC";
		} else if ([Helper isAtLSCWithRouteTag:currentBusStat.busRoute.tag
								 NextStopTitle:nextStop.stop.title] &&
				   (schedules = [schedule.scheduleOfStop objectForKey:@"Livingston Student Center"]) != nil)
		{
			[cond lock];
			while (lat == 200 || lon == 200)
				[cond wait];
			[cond unlock];
			atControlPoint = [Helper isAtLSCWithLat:lat Lon:lon];
			controlPoint = @"LSC";
		} else if (([nextStop.stop.title isEqualToString:@"Lipman Hall"] ||
			[nextStop.stop.title isEqualToString:@"Red Oak Lane"]) &&
			(schedules = [schedule.scheduleOfStop objectForKey:@"Red Oak Lane"]) != nil)
		{
			[cond lock];
			while (lat == 200 || lon == 200)
				[cond wait];
			[cond unlock];
			atControlPoint = [Helper isAtRedOakWithLat:lat Lon:lon];
			controlPoint = @"Red Oak Lane";
		}
		if (atControlPoint)
		{
			unsigned int epoch = [Helper convertToLocalDateFrom:[NSDate date]];
			int atStationDiff = INT_MAX;
			for (NSNumber* num in schedules)
			{
				if ([num intValue] < 0)
					continue;
				int diff = [num intValue] - epoch;
				if (diff > 0 && diff < atStationDiff)
					atStationDiff = diff;
			}
			if (atStationDiff < 60)
				status = [NSString stringWithFormat:@"Status: Departing %@ soon",
						  controlPoint];
			else if (atStationDiff > 60 * 10)
				status = [NSString stringWithFormat:@"Status: Departing %@ now",
						  controlPoint];
			else //Within 10 minutes
			{
				int minutes = atStationDiff/60;
				status = [NSString stringWithFormat: @"Status: Departing %@ in %d minute%c",
						  controlPoint, minutes, minutes == 1 ? ' ' : 's'];
			}
		}

		int scheduleDiff = INT_MAX;
		//finding the closest difference between scheduled time and predicted arrival time
		for (NSNumber* num in [schedule.scheduleOfStop objectForKey:nextStop.stop.title])
		{
			if ([num intValue] < 0)
				continue;
			if (abs(epoch - [num intValue]) < abs(scheduleDiff))
				scheduleDiff = epoch - [num intValue];
			//Todo: Prefer behind schedule epochs
		}
		
		if (status && scheduleDiff > 60)
		{
			int minutes = scheduleDiff/60;
			status = [NSString stringWithFormat: @"%@, %d minute%@ behind schedule",
					  status, minutes, minutes == 1 ? @"" : @"s"];
		}
		else if (!status)
		{
			if (scheduleDiff > 60)
			{
				int minutes = scheduleDiff/60;
				status = [NSString stringWithFormat: @"Status: %d minute%@ behind schedule",
						  minutes, minutes == 1 ? @"" : @"s"];
			}
			else if (scheduleDiff < -60)
			{
				int minutes = scheduleDiff/-60;
				status = [NSString stringWithFormat: @"Status: %d minute%@ ahead of schedule",
						  minutes, minutes == 1 ? @"" : @"s"];
			}
			else
				status = @"Status: On time";
		}
		//Todo: if difference is greater than 30 minutes, say it is unavailable
		//Todo: in iOS, put a question mark button next to it, informing user status could be used to know when the bus will be leaving
		dispatch_async(dispatch_get_main_queue(), ^{
			[_statusLabel setStringValue: status];
		});
	});
}

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
{
	unsigned long routeCount = [activeRoutes count];
	if (column == 0)
		return (routeCount == 0 && !isUpdating) ? 1 : routeCount + ([messages count] == 1 ? 1 : 0);
		//If there is only one message, then display it. To display it we need an extra row.
	else if (column == 1)
	{
		if ([sender selectedRowInColumn:0] > routeCount)
			return 0;
		BusRoute* route = [activeRoutes objectAtIndex:[sender selectedRowInColumn:0]];
		return [route.routeAndStopInOrder count];
	} else if (column == 2)
	{
		BusRoute* route = [activeRoutes objectAtIndex:[sender selectedRowInColumn:0]];
		RouteAndStop* stop = [route.routeAndStopInOrder objectAtIndex:[sender selectedRowInColumn:1]];
		long count = [stop.predictions count];
		return count == 0 ? 1: count;
		//If there are no predictions, then we need a row to display the message "No predictions".
	}
	return 0;
}

- (void)browser:(NSBrowser *)browser willDisplayCell:(NSBrowserCell *)cell atRow:(NSInteger)row column:(NSInteger)column
{
	if (column == 0)
	{
		if ([messages count] == 1 && row == [activeRoutes count])
		{
			cell.title = [[messages allKeys] objectAtIndex:0];
			[cell setLeaf:YES];
			return;
		} else if ([activeRoutes count] == 0 && row == 0)
		{
			cell.title = @"No active routes";
			[cell setLeaf:YES];
			return;
		}
		cell.title = ((BusRoute *)[activeRoutes objectAtIndex:row]).title;
	}
	else if (column == 1)
	{
		BusRoute* route = [activeRoutes objectAtIndex:[browser selectedRowInColumn:0]];
		cell.title = ((RouteAndStop*)[route.routeAndStopInOrder objectAtIndex:row]).stop.title;
	} else if (column == 2)
	{
		[cell setLeaf:YES];
		BusRoute* route = [activeRoutes objectAtIndex:[browser selectedRowInColumn:0]];
		RouteAndStop* stop = [route.routeAndStopInOrder objectAtIndex:[browser selectedRowInColumn:1]];
		if ([stop.predictions count] == 0)
		{
			cell.title = noPrediction;
			return;
		}
		cell.title = [((Prediction*)[stop.predictions objectAtIndex:row]) description];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (currentBusStat && [_busStatWindow isVisible])
		return [currentBusStat.busRoute.routeAndStopInOrder count];
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row {
	int column = aTableColumn == _stopColumn ? 0 : 1;
	if (row >= [currentBusStat.busRoute.routeAndStopInOrder count])
		return @"";
	
	RouteAndStop* stop = [currentBusStat.busRoute.routeAndStopInOrder objectAtIndex:row];
	if (column == 0)
		return stop.stop.title;
	else
	{
		Prediction* p = [stop predictionWithVehicleID:currentBusStat.vehicleID];
		return p ? [p prediction] : noPrediction;
	}
}

@end
