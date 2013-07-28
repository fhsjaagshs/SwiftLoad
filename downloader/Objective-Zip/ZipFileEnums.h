//
//  ZipFileEnums.h
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

typedef enum {
	ZipFileModeUnzip,
	ZipFileModeCreate,
	ZipFileModeAppend
} ZipFileMode;

typedef enum {
	ZipCompressionLevelDefault = -1,
	ZipCompressionLevelNone = 0,
	ZipCompressionLevelFastest = 1,
	ZipCompressionLevelBest = 9
} ZipCompressionLevel;
