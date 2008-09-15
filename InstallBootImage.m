/*
 *  InstallBootImage.m
 *  BootXChanger
 *
 *  Created by Zydeco on 2007-11-05.
 *  Copyright 2007 namedfork.net. All rights reserved.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Cocoa/Cocoa.h>
#include "bootfile.h"
#include <unistd.h>

// usage: InstallBootImage path length
//		  then write the boot file to the tool's stdin

OSErr SetFileLocked (const FSRef *ref, int lockStatus);

int main (int argc, char ** argv) {
	// unlock the file, write it, and lock it back
	FSRef				bootFile;
	HFSUniStr255		forkName;
	OSErr				err;
	SInt16				forkRef = 0;
	char				*fileData;
	size_t				fileSize = 0, writtenBytes = 0;
	
	// validate arguemtns
	if (argc != 3) return 1;
	if (strcmp(argv[1],BOOTX_CURRENT) && strcmp(argv[1],BOOTEFI_CURRENT)) return 1;
	if (FSPathMakeRef((UInt8*)argv[1], &bootFile, NULL) != noErr) return 2;
	fileSize = strtol(argv[2], NULL, 10);
	fileData = malloc(fileSize);
	
	NSLog(@"Writing %d bytes to %s", fileSize, argv[1]);
	
	// read data
	if (fread(fileData, fileSize, 1, stdin) == 0) {
		NSLog(@"[!!!] Unexpected end of data");
		free(fileData);
		return 5;
	}
	
	// open file	
	if (SetFileLocked(&bootFile, 0)) {
		NSLog(@"SetFileLocked error");
		free(fileData);
		return 3;
	}
	FSGetDataForkName(&forkName);
	err = FSOpenFork(&bootFile, forkName.length, forkName.unicode, fsWrPerm, &forkRef);
	if (err) {
		NSLog(@"FSOpenFork: error %d", err);
		SetFileLocked(&bootFile, 1);
		free(fileData);
		return 3;
	}
	
	// write data
	err = FSWriteFork(forkRef, fsFromStart, 0, (ByteCount)fileSize, fileData, &writtenBytes);
	if (err || writtenBytes != fileSize) {
		NSLog(@"FSWriteFork: error %d, wrote %d bytes", err, writtenBytes);
		FSCloseFork(forkRef);
		SetFileLocked(&bootFile, 1);
		free(fileData);
		return 4;
	}
	
	// close file
	free(fileData);
	FSCloseFork(forkRef);
	SetFileLocked(&bootFile, 1);
	
	return 0;
}

OSErr SetFileLocked (const FSRef *ref, int lockStatus) {
	FSCatalogInfo		catInfo;
	OSErr				err;
	
	err = FSGetCatalogInfo(ref, kFSCatInfoNodeFlags, &catInfo, NULL, NULL, NULL);
	if (err != noErr) {
		NSLog(@"FSGetCatalogInfo: error %d", err);
		return err;
	}
	
	if (lockStatus) 
		catInfo.nodeFlags |= kFSNodeLockedMask;
	else
		catInfo.nodeFlags &= ~kFSNodeLockedMask;
	
	err = FSSetCatalogInfo(ref, kFSCatInfoNodeFlags, &catInfo);
	if (err != noErr) {
		NSLog(@"FSSetCatalogInfo: error %d", err);
		return err;
	}
	return noErr;
}
