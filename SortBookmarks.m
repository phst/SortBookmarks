/*
Copyright (c) 2010, Philipp Stephani <st_philipp@yahoo.de>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

#import <stdlib.h>
#import <stdio.h>

#import <Foundation/Foundation.h>

BOOL run(void);
BOOL walk(NSMutableDictionary *dict, NSString *parentPath, NSUInteger level);
NSInteger compare(id first, id second, void *context);
BOOL isFolder(NSDictionary *dict);
NSString *getType(NSDictionary *dict);
NSString *getTitle(NSDictionary *dict, BOOL folder);
NSMutableArray *getChildren(NSMutableDictionary *dict);

BOOL sort = NO;
BOOL ask = YES;
BOOL save = YES;

int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL success = run();
	if (!success) NSLog(@"Error");
    [pool drain];
	return success ? EXIT_SUCCESS : EXIT_FAILURE;
}

BOOL run(void) {
	NSString *path = [@"~/Library/Safari/Bookmarks.plist" stringByExpandingTildeInPath];
	if (!path) return NO;
	NSMutableDictionary *root = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	if (!root) return NO;
	walk(root, NULL, 0);
	if (save) {
		NSFileManager *manager = [NSFileManager defaultManager];
		for (NSUInteger i = 1; i < 1000; ++i) {
			NSString *backupPath = [path stringByAppendingFormat:@".%u", i];
			if ([manager moveItemAtPath:path toPath:backupPath error:NULL]) {
				return [root writeToFile:path atomically:YES];
			}
		}
		return NO;
	}
	return YES;
}

BOOL walk(NSMutableDictionary *dict, NSString *parentPath, NSUInteger level) {
	if (!isFolder(dict)) return YES;
	NSMutableArray *children = getChildren(dict);
	NSString *path = [NSString string];
	BOOL resetAsk = NO;
	if (level > 0) {
		path = parentPath;
		if (level > 1) {
			path = [path stringByAppendingString:@"/"];
		}
		NSString *title = getTitle(dict, YES);
		path = [path stringByAppendingString:title];
		if (ask) {
			printf("Sort folder %s? [yrs!qx] ", [path UTF8String]);
			char answer = getchar();
			char ch = answer;
			while ((ch != EOF) && (ch != '\n')) {
				ch = getchar();
			}
			switch (answer) {
				case 'y':
					sort = YES;
					break;
				case 'r':
					sort = YES;
					ask = NO;
					resetAsk = YES;
					break;
				case 's':
					sort = NO;
					return YES;
				case '!':
					sort = YES;
					ask = NO;
					break;
				case 'q':
					sort = NO;
					ask = NO;
					return NO;
				case 'x':
					sort = NO;
					ask = NO;
					save = NO;
					return NO;
				default:
					sort = NO;
					break;
			}
		}
		if (sort) {
			printf("Sorting folder %s\n", [path UTF8String]);
			[children sortUsingFunction:compare context:nil];
		}
	}
	for (NSMutableDictionary* child in children) {
		if (!walk(child, path, level + 1)) return NO;
	}
	if (resetAsk) ask = YES;
	return YES;
}

NSInteger compare(id first, id second, void *context) {
	NSMutableDictionary *firstDict = first;
	NSMutableDictionary *secondDict = second;
	BOOL firstFolder = isFolder(firstDict);
	BOOL secondFolder = isFolder(secondDict);
	if (firstFolder && !secondFolder) {
		return NSOrderedAscending;
	} else if (!firstFolder && secondFolder) {
		return NSOrderedDescending;
	} else {
		NSString *firstTitle = getTitle(firstDict, firstFolder);
		NSString *secondTitle = getTitle(secondDict, secondFolder);
		return [firstTitle localizedStandardCompare:secondTitle];
	}
}

BOOL isFolder(NSDictionary *dict) {
	return [getType(dict) isEqualToString:@"WebBookmarkTypeList"];
}

NSString *getType(NSDictionary *dict) {
	return [dict objectForKey:@"WebBookmarkType"];
}

NSString *getTitle(NSDictionary *dict, BOOL folder) {
	if (folder) {
		return [dict objectForKey:@"Title"];
	} else {
		NSDictionary *child = [dict objectForKey:@"URIDictionary"];
		return [child objectForKey:@"title"];
	}
}

NSMutableArray *getChildren(NSMutableDictionary *dict) {
	return [dict objectForKey:@"Children"];
}
