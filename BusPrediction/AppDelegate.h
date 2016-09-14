//
//  AppDelegate.h
//  BusPrediction
//
//  Created by Li Bohan on 2/10/14.
//  Copyright (c) 2014 Li Bohan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSBrowserDelegate, NSTableViewDataSource, NSWindowDelegate>

@property NSString* agency;
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSBrowser *browser;
@property (weak) IBOutlet NSProgressIndicator *progress;
@property (unsafe_unretained) IBOutlet NSWindow *busStatWindow;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSTableView *table;
@property (weak) IBOutlet NSTableColumn *stopColumn;
@property (weak) IBOutlet NSTableColumn *predictionColumn;
@property (weak) IBOutlet NSImageView *image;
@property (weak) IBOutlet NSTextField *label;



- (IBAction)refreshRouteAction:(NSButton *)sender;
- (IBAction)refreshPredictAction:(NSButton *)sender;
- (IBAction)browserAction:(NSBrowser *)sender;
- (IBAction)segCellAction:(NSSegmentedCell *)sender;

@end