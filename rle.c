/*
 *  rle.c
 *  BootXChanger
 *
 *  Created by Zydeco on 2007-11-17.
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

#include <string.h>
#include "rle.h"

ssize_t RLEEncodeMem(void *dst, const void *src, size_t len) {
	ssize_t	totalSize = 0;
	int		blockLen = 0;
	int		blockChar, c;
	size_t	i;
	
	for(i = 0; i < len; i++) {
		c = ((unsigned char*)src)[i];
		
		if (c == blockChar && blockLen < 255) {	
			/* same block */
			blockLen++;
		}
		else {	
			/* write block */
			if (blockLen && dst) {
				*((unsigned char*)(dst++)) = blockLen;
				*((unsigned char*)(dst++)) = blockChar;
			}
			if (blockLen) totalSize += 2;
			/* start new block */
			blockLen = 1;
			blockChar = c;
		}
	}

	/* write last block */
	if (blockLen && dst) {
		*((unsigned char*)(dst++)) = blockLen;
		*((unsigned char*)(dst++)) = blockChar;
	}
	if (blockLen) totalSize += 2;

	return totalSize;
}

ssize_t RLEDecodeMem(void *dst, const void *src, size_t len) {
	int		blockChar;
	size_t	i, blockLen;
	ssize_t totalSize = 0;
	
	if (len % 2) return -1; /* RLE encoded length must be even, nuttard */
	for(i = 0; i < len; i+=2) {
		blockLen = ((unsigned char*)src)[i];
		blockChar = ((unsigned char*)src)[i+1];
		if (dst && blockLen) memset((unsigned char*)(dst+totalSize), blockChar, blockLen);
		totalSize += blockLen;
	}
	
	return totalSize;
}

ssize_t RLEGetEncodedSize(const void *src, size_t len) {
	return RLEEncodeMem(NULL, src, len);
}

ssize_t RLEGetDecodedSize(const void *src, size_t len) {
	return RLEDecodeMem(NULL,  src, len);
}
