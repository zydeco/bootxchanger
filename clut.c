/*
 *  clut.c
 *  BootXChanger
 *
 *  Created by Zydeco on 2007-11-04.
 *  Copyright 2007-2009 namedfork.net. All rights reserved.
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

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "clut.h"

#define abs(x) (((x)<0)?((x)*-1):(x))
#define ColorVal(c) (((int)c.red << 16) | ((int)c.green << 8) | ((int)c.blue))

struct colorTag {
	unsigned char red;
	unsigned char green;
	unsigned char blue;
};

float ColorDistance (struct colorTag ca, struct colorTag cb) {
	float dx,dy,dz,d;
	d = ca.red-cb.red;
	dx = d*d;
	d = ca.green-cb.green;
	dy = d*d;
	d = ca.blue-cb.blue;
	dz = d*d;
	return sqrtf(dx+dy+dz);
};

#if 0
bool isPersistentColor(unsigned long color) {
	static unsigned long persistentColors = {
		0xFFFFFF, 0xBFBFBF, 0xBEBEBE, 0xBDBDBD, 0xBCBCBC, 0xFFFF00, 0xBABABA, 0xB9B9B9, 
		0xB8B8B8, 0xB7B7B7, 0xB6B6B6, 0xB5B5B5, 0xB4B4B4, 0xB3B3B3, 0xB2B2B2, 0x000000, 
		0xB1B1B1, 0xB0B0B0, 0xAFAFAF, 0xAEAEAE, 0xADADAD, 0xACACAC, 0xABABAB, 0xAAAAAA, 
		0xFF00FF, 0xA9A9A9, 0xA8A8A8, 0xA7A7A7, 0xA6A6A6, 0xA5A5A5, 0xA4A4A4, 0xA3A3A3, 
		0xA2A2A2, 0xA1A1A1, 0xA0A0A0, 0xFF0000, 0x9F9F9F, 0x9E9E9E, 0x9D9D9D, 0x9C9C9C, 
		0x9B9B9B, 0x9A9A9A, 0xCCCCFF, 0xCCCCCC, 0x999999, 0x989898, 0x979797, 0x969696, 
		0x959595, 0x949494, 0x939393, 0x929292, 0x919191, 0x909090, 0x8F8F8F, 0x8E8E8E, 
		0x8D8D8D, 0x8C8C8C, 0x8B8B8B, 0x8A8A8A, 0x898989, 0x878787, 0x868686, 0x858585, 
		0x848484, 0x838383, 0x828282, 0x818181, 0x808080, 0x7F7F7F, 0x7E7E7E, 0x7D7D7D, 
		0x7C7C7C, 0x7B7B7B, 0x7A7A7A, 0x797979, 0x787878, 0x767676, 0x757575, 0x747474, 
		0x737373, 0x727272, 0x717171, 0x707070, 0x6F6F6F, 0x6E6E6E, 0x6D6D6D, 0x6C6C6C, 
		0x6B6B6B, 0x6A6A6A, 0x696969, 0x686868, 0x676767, 0x666666, 0x646464, 0x636363, 
		0x626262, 0x616161, 0x606060, 0x5F5F5F, 0x5E5E5E, 0x5D5D5D, 0x5C5C5C, 0x5B5B5B, 
		0x5A5A5A, 0x595959, 0x585858, 0x575757, 0x565656, 0x545454, 0x535353, 0x525252, 
		0x515151, 0x505050, 0x4F4F4F, 0x4E4E4E, 0x4D4D4D, 0x4C4C4C, 0x4B4B4B, 0x4A4A4A, 
		0x494949, 0x484848, 0x474747, 0x464646, 0x454545, 0x434343, 0x424242, 0x414141, 
		0x404040, 0x3F3F3F, 0x3E3E3E, 0x3D3D3D, 0x3C3C3C, 0x3B3B3B, 0x3A3A3A, 0x393939, 
		0x383838, 0x373737, 0x363636, 0x353535, 0x00FFFF, 0x00FF00, 0x0000FF, 0xDD0000, 
		0x00BB00, 0xBBBBBB, 0x888888, 0x777777, 0x555555, 0x444444, 0x222222, 0x656565, 
		0x000000 };
	int i;
	
	// do we have it?
	for(i = 0; i < 154; i++) {
		if (persistentColors[i] == color) return true;
	}
	
	// try with 6-bit resolution
	color = color | 0xFCFCFC;
	for(i = 0; i < 154; i++) {
		if ((persistentColors[i] | 0xFCFCFC) == color) return true;
	}
	
	return false;
}
#endif

unsigned char findColorInCLUT(unsigned char r, unsigned char g, unsigned char b, unsigned char *clutBytes) {
	struct colorTag *clut = (struct colorTag *)clutBytes;
	struct colorTag findColor = {r,g,b};
	int	i;
	
	// is it the magic color?
	if (ColorVal(findColor) == 0x656565) return 254;
	
	// is it in the palette?
	for(i = 0; i < 256; i++) {
		if (ColorVal(clut[i]) == ColorVal(findColor)) return i;
	}
	
	// its not, try to find a place for it
	for(i = 140; i < 248; i++) {
		if (ColorVal(clut[i]) == 0x656565) {
			clut[i] = findColor;
			return i;
		}
	}
	
	// find closest color (doesn't mean it'll actually be similar)
	float dist,minDist;
	int minDistIdx;
	minDist = ColorDistance(findColor, clut[0]);
	minDistIdx = 0;
	for(i = 1; i < 256; i++) {
		dist = ColorDistance(findColor, clut[i]);
		if (dist < minDist) {
			minDist = dist;
			minDistIdx = i;
		}
	}
	return minDistIdx;
}