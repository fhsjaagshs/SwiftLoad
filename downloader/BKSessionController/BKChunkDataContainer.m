//
//  BKChunkDataContainer.m
//  BKSessionController
//
//  Created by boreal-kiss.com on 10/09/15.
//  Copyright 2010 boreal-kiss.com. All rights reserved.
//

#import "BKChunkDataContainer.h"

static NSUInteger DefaultChunkLength = 12800;
static NSUInteger MaximumChunkLength = 87000;

@interface BKChunkDataContainer ()
- (void)_setup;
- (void)_createChunkData;
@end

@implementation BKChunkDataContainer
@synthesize chunkLength = _chunkLength;
@synthesize data = _data;
@synthesize chunkDataContainer = _chunkDataContainer;

+ (id)chunkDataContainerWithData:(NSData *)data {
	return [[[[self class]alloc]initWithData:data]autorelease];
}

+ (id)chunkDataContainerWithData:(NSData *)data chunkLength:(NSUInteger)length {
	return [[[[self class]alloc]initWithData:data chunkLength:length]autorelease];
}

- (id)initWithData:(NSData *)data {
	return [self initWithData:data chunkLength:DefaultChunkLength];
}

- (id)initWithData:(NSData *)data chunkLength:(NSUInteger)length {
	if (self = [super init]) {
		self.data = data;
		_chunkLength = length;

		if (_chunkLength > MaximumChunkLength) {
            _chunkLength = MaximumChunkLength;
		}
		
		[self _setup];
	}
	return self;
}

- (NSData *)chunkDataAtIndex:(NSUInteger)index {
	return (NSData *)[_chunkDataContainer objectAtIndex:index];
}

- (NSUInteger)count {
	return _chunkDataContainer.count;
}
		
- (void)dealloc {
	self.data = nil;
	self.chunkDataContainer = nil;
	[super dealloc];
}

- (void)_setup {
	[self _createChunkData];
}

- (void)_createChunkData {
	
	int numItems = ceil((double)_data.length/_chunkLength);
	_chunkDataContainer = [[NSMutableArray alloc]initWithCapacity:numItems];
	
	for (int i = 0; i < numItems; i++) {
		NSUInteger start = i * _chunkLength;
		NSUInteger length = _chunkLength;
		NSUInteger end = start + length;

		if (end > _data.length) {
			length = _data.length % _chunkLength;
		}
		
		NSRange range = {start, length};
		NSData *chunkData = [_data subdataWithRange:range];
		
		[_chunkDataContainer addObject:chunkData];
	}
}

@end
