//
//  Helper.m
//  BusPrediction
//
//  Created by Li Bohan on 2/12/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import "Helper.h"

@implementation Helper

+ (NSString *)getDataFrom:(NSString *)url
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
	[request setTimeoutInterval:10];
	
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
	
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
	
	
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %li", url, (long)[responseCode statusCode]);
		NSLog(@"Error: %@", [error localizedDescription]);
		NSAlert* alert = [NSAlert alertWithError:error];
		dispatch_async(dispatch_get_main_queue(), ^{
			[alert runModal];
		});
        return nil;
    }
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
	
}

/**
 * Substrings the given string from the first occurence of "from" to first occurence of "to" after "from"
 * Todo: add another method in which you can start searching from an index given by the caller
 */
+ (NSString *) substring: (NSString*)str
			  fromString: (NSString*)from
				toString: (NSString*)to
{
	NSRange tmpRange = [str rangeOfString:from];
	if(tmpRange.location == NSNotFound)
		return nil;
	unsigned long start = tmpRange.location + [from length];
	NSRange range = NSMakeRange(start + 1, [str length] - start - 1);
	tmpRange = [str rangeOfString: to options:0 range:range];
	if(tmpRange.location == NSNotFound)
		return nil;
	unsigned long length = tmpRange.location - start;
	return [str substringWithRange:NSMakeRange(start, length)];
}

+ (unsigned int) convertToLocalDateFrom: (NSDate*) date
{
	long diff = [[NSTimeZone localTimeZone] secondsFromGMTForDate:[NSDate date]];
	return ((long)[[date dateByAddingTimeInterval:diff] timeIntervalSince1970]) % (60*60*24);
}

+ (BOOL) isAtRSCWithLat: (double)lat Lon: (double)lon
{
	return lat > 40.5032 && lat < 40.504 && lon > -74.4527 && lon < -74.4518;
}

+ (BOOL) isAtBCCWithRouteTag: (NSString*) route NextStopTitle: (NSString*) stop
{
	/**
	 *  NextStop is BCC OR
	 * [NextStop is Buell AND route is 'a'] OR
	 * [NextStop is Plaza AND (route is 'b' OR route is 'wknd1' OR route is 's')] OR
	 *  NextStop is Davidson
	 */
	return [stop isEqualToString:@"Busch Campus Center"] ||
	([stop isEqualToString:@"Buell Apartments"] && [route isEqualToString:@"a"]) ||
	([stop isEqualToString:@"Livingston Plaza"] && ([route isEqualToString:@"b"] || [route isEqualToString:@"wknd1"] || [route isEqualToString:@"s"])) ||
	[stop isEqualToString:@"Davidson Hall"];
}

+ (BOOL) isAtBCCWithLat: (double)lat Lon: (double)lon
{
	//maps.googleapis.com/maps/api/staticmap?zoom=19&size=800x800&maptype=satellite&path=color:0x0000ff|weight:4|40.5234,-74.45785|40.52388,-74.45815|40.52437,-74.4589|40.5234,-74.4589|40.5234,-74.45785&sensor=false
	
	//Point falls in area: http://mathforum.org/library/drmath/view/54386.html
	//lat - y1-(y2-y1)/(x2-x1)*(lon - x1)
	//lat - 40.5234-(40.52388-40.5234)/(-74.45815+74.45785)*(lon + 74.45785)
	//lat - 40.5234 + 1.6*(lon + 74.45785)
	double a = lat + 78.60916 + 1.6*lon;
	
	//lat - 40.52388-(40.5243-40.52388)/(-74.4588+74.45815)*(lon + 74.45815)
	//lat - 40.52388 + .64615*(lon + 74.45815)
	double b = lat + 7.58725 + .64615*lon;
	
	return lat > 40.52345 && lon > -74.4589 && a < 0 && b < 0;
}

+ (BOOL) isAtLSCWithRouteTag: (NSString*) route NextStopTitle: (NSString*) stop
{
	return [stop isEqualToString:@"Livingston Student Center"] ||
	[stop isEqualToString:@"Quads"] ||
	([stop isEqualToString:@"Public Safety Building South"] &&
	 [route isEqualToString:@"rexl"]);
}

/** TODO: LSC's right bound should be done with quadratic line **/
+ (BOOL) isAtLSCWithLat: (double)lat Lon: (double)lon
{
	return lat > 40.5237 && lat < 40.5243 && lon > -74.4366 && lon < -74.4363;
}

+ (BOOL) isAtRedOakWithLat: (double)lat Lon: (double)lon
{
	return lat > 40.4826 && lat < 40.4832 && lon > -74.4381 && lon < -74.4372;
}
@end
