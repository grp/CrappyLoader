
#import <Foundation/Foundation.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSFileManager.h> 

#define EXTENSIONS_PATH @"/Library/CycriptLoader/Extensions/"

static __attribute__((constructor)) void cl_init() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int pid;
	NSArray *files;
	NSMutableArray *args;
	NSTask *cycript;
	
	pid = [[NSProcessInfo processInfo] processIdentifier];
	files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:EXTENSIONS_PATH error:NULL];
	
	for (NSString *base in files) {
		NSString *file = [EXTENSIONS_PATH stringByAppendingString:base];
		
		BOOL isDirectory;
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory];
		if (![file hasSuffix:@".cy"] || !exists || isDirectory) continue;
		
		NSString *plistFile = [EXTENSIONS_PATH stringByAppendingString:[[file substringWithRange:NSMakeRange(0, [file length] - 3)] stringByAppendingString:@".plist"]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:plistFile]) {
			NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistFile];
			NSDictionary *filter;
			
			if (plist != nil && (filter = [plist objectForKey:@"Filter"]) && [filter isKindOfClass:[NSDictionary class]]) {
				NSArray *version, *bundles, *classes;
				
				if ((version = [plist objectForKey:@"CoreFoundationVersion"]) && [version isKindOfClass:[NSArray class]]) {
					int count = [version count];
					if (count > 2) goto next;
					
					NSNumber *number;
					if ((number = [version objectAtIndex:0]) && [number isKindOfClass:[NSNumber class]]) {
						if ([number doubleValue] > kCFCoreFoundationVersionNumber) goto next;
					}
					if (count != 1 && (number = [version objectAtIndex:1]) && [number isKindOfClass:[NSNumber class]]) {
						if ([number doubleValue] <= kCFCoreFoundationVersionNumber) goto next;
					}
				}
			
				if ((bundles = [plist objectForKey:@"Bundles"]) && [bundles isKindOfClass:[NSArray class]]) {
					for (NSString *bundle in bundles) {
						if (![bundle isKindOfClass:[NSString class]]) continue;
						
						if ([NSBundle bundleWithIdentifier:bundle] == nil) goto next;
					}
				}
				
				if ((classes = [plist objectForKey:@"Classes"]) && [classes isKindOfClass:[NSArray class]]) {
					for (NSString *className in classes) {
						if (![className isKindOfClass:[NSString class]]) continue;
						
						if (NSClassFromString(className) == nil) goto next;
					}
				}
			}
		}
		
		NSLog(@"CL:Notice: Loading %@.", base);
		
		args = [NSMutableArray array];
		cycript = [[NSTask alloc] init];
		[cycript setLaunchPath:@"/usr/bin/cycript"];
		
		[args addObject:@"-p"];
		[args addObject:[[NSNumber numberWithInt:pid] stringValue]];
		[args addObject:file];
		[cycript setArguments:args];
		
		[cycript launch];
		[cycript waitUntilExit];
		[cycript release];
		
		continue;
		
		next: 
		NSLog(@"CL:Debug: Skipping %@");
		continue;
	}
	
	[pool release];
}

