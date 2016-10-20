//
//  AppDelegate.m
//  App Update Detector
//
//  Created by Andrew Mellen on 10/17/16.
//  Copyright © 2016 theawesomecoder61. All rights reserved.
//

#import "AppDelegate.h"
#import "XMLDictionary.h"

@interface AppDelegate () {
    NSMutableArray *appURLs;
    NSMutableArray *appNames;
    NSMutableArray *appVersions;
    NSMutableArray *appShortVersions;
    NSMutableArray *newestVersions;
    NSMutableArray *newestShortVersions;
    NSMutableArray *appcasts;
    NSInteger ctUseSparkle;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *tv;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.tv setDelegate:self];
    [self.tv setDataSource:self];
    
    appURLs = [NSMutableArray array];
    appNames = [NSMutableArray array];
    appVersions = [NSMutableArray array];
    appShortVersions = [NSMutableArray array];
    newestVersions = [NSMutableArray array];
    newestShortVersions = [NSMutableArray array];
    appcasts = [NSMutableArray array];
    [self loadList];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [appURLs removeAllObjects];
    [appNames removeAllObjects];
    [appVersions removeAllObjects];
    [appShortVersions removeAllObjects];
    [newestVersions removeAllObjects];
    [newestShortVersions removeAllObjects];
    [appcasts removeAllObjects];
}

- (IBAction)refreshList:(id)sender {
    [appURLs removeAllObjects];
    [appNames removeAllObjects];
    [appVersions removeAllObjects];
    [appShortVersions removeAllObjects];
    [newestVersions removeAllObjects];
    [newestShortVersions removeAllObjects];
    [appcasts removeAllObjects];
    [self loadList];
}

- (IBAction)runApp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[appURLs objectAtIndex:[self.tv selectedRow]]];
}

- (IBAction)openAppcast:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[appcasts objectAtIndex:[self.tv selectedRow]]];
}

- (void)loadList {
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask];
    NSArray *properties = [NSArray arrayWithObjects:NSURLLocalizedNameKey,NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    NSArray *aurls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[urls objectAtIndex:0] includingPropertiesForKeys:properties options:(NSDirectoryEnumerationSkipsHiddenFiles) error:nil];
    for(NSURL *u in aurls) {
        NSString *us = [self getAppcastOfApp:u];
        if([us isNotEqualTo:nil] && ![self isFromMAS:u]) {
            [appURLs addObject:u];
            [appNames addObject:[[[u relativePath] stringByRemovingPercentEncoding] lastPathComponent]];
            [appVersions addObject:[[self getVersionOfApp:u] valueForKey:@"v"]];
            [appShortVersions addObject:[[self getVersionOfApp:u] valueForKey:@"sv"]];
            NSString *nv = [[self getLatestVersionFromAppcast:[NSURL URLWithString:us]] valueForKey:@"v"];
            [newestVersions addObject:nv];
            NSString *nsv = [[self getLatestVersionFromAppcast:[NSURL URLWithString:us]] valueForKey:@"sv"];
            [newestShortVersions addObject:nsv];
            [appcasts addObject:[NSURL URLWithString:us]];
        }
    }
    [self.tv reloadData];
}

- (BOOL)isFromMAS:(NSURL *)appURL {
    bool mas = NO;
    if(appURL != nil) {
        mas = [[NSFileManager defaultManager] fileExistsAtPath:[[appURL URLByAppendingPathComponent:@"/Contents/_MASReceipt/receipt"] relativePath]];
    }
    return mas;
}

- (NSString *)getAppcastOfApp:(NSURL *)u {
    NSString *bb;
    if(u != nil) {
        NSBundle *b = [NSBundle bundleWithURL:u];
        bb = [b objectForInfoDictionaryKey:@"SUFeedURL"];
    }
    return bb;
}

- (NSDictionary *)getVersionOfApp:(NSURL *)u {
    NSString *svs = @"";
    NSString *vs = @"";
    if(u != nil) {
        NSBundle *b = [NSBundle bundleWithURL:u];
        vs = [b objectForInfoDictionaryKey:@"CFBundleVersion"];
        svs = [b objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:vs, @"v", svs, @"sv", nil];
}

- (NSDictionary *)getLatestVersionFromAppcast:(NSURL *)u {
    NSDictionary *d = [NSDictionary dictionaryWithXMLString:[NSString stringWithContentsOfURL:u encoding:NSUTF8StringEncoding error:nil]];
    NSArray *av = [[d objectForKey:@"channel"] objectForKey:@"item"];
    id ev = [[av valueForKey:@"enclosure"] valueForKey:@"_sparkle:version"];
    id esv = [[av valueForKey:@"enclosure"] valueForKey:@"_sparkle:shortVersionString"];
    id sv = [av valueForKey:@"sparkle:shortVersionString"];
    NSString *vs = @"";
    NSString *svs = @"";
    if(ev != nil) {
        if([ev isKindOfClass:[NSArray class]]) {
            vs = [ev firstObject];
        } else if([ev isKindOfClass:[NSString class]]) {
            vs = ev;
        }
    }
    if(esv != nil) {
        if([esv isKindOfClass:[NSArray class]]) {
            svs = [esv firstObject];
        } else if([esv isKindOfClass:[NSString class]]) {
            svs = esv;
        }
    } else if(sv != nil) {
        if([sv isKindOfClass:[NSArray class]]) {
            svs = [sv firstObject];
        } else if([sv isKindOfClass:[NSString class]]) {
            svs = sv;
        }
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:vs, @"v", svs, @"sv", nil];
}


//
// Tableview
//
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [appNames count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if([[tableColumn identifier] isEqualToString:@"l"]) {
        if([[appVersions objectAtIndex:row] isEqualTo:[newestVersions objectAtIndex:row]] || [[appShortVersions objectAtIndex:row] isEqualTo:[newestShortVersions objectAtIndex:row]] ) {
            return @"Yes";
        }
    } else if([[tableColumn identifier] isEqualToString:@"n"])  {
        return [appNames objectAtIndex:row];
    } else if([[tableColumn identifier] isEqualToString:@"iv"])  {
        return [appVersions objectAtIndex:row];
    } else if([[tableColumn identifier] isEqualToString:@"isv"])  {
        return [appShortVersions objectAtIndex:row];
    } else if([[tableColumn identifier] isEqualToString:@"nv"])  {
        return [newestVersions objectAtIndex:row];
    } else if([[tableColumn identifier] isEqualToString:@"nsv"])  {
        return [newestShortVersions objectAtIndex:row];
    }
    return nil;
}

@end