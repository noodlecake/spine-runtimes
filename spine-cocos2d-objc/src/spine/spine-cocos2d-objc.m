/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated May 1, 2019. Replaces all prior versions.
 *
 * Copyright (c) 2013-2019, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
 * NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS
 * INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#import <spine/spine-cocos2d-objc.h>
#import <spine/extension.h>

// Optional per-call instrumentation for the spine file-read path. The Android
// branch here goes through bridged NSData; iOS uses raw fopen. Bucket by file
// extension so we can split skel vs atlas vs (json fallback) in the dump.
#import "GBLoadProfiler.h"

#include <string.h>

void _spAtlasPage_createTexture (spAtlasPage* self, const char* path) {
	CCTexture* texture = [[CCTexture textureWithFile:@(path)] retain];
	self->rendererObject = texture;
	CGSize size = texture.contentSizeInPixels;
	self->width = size.width;
	self->height = size.height;
}

void _spAtlasPage_disposeTexture (spAtlasPage* self) {
	[(CCTexture*)self->rendererObject release];
}

static int gb_spine_cat_for_path (const char* path) {
	if (!path) return GB_LP_SpineOtherRead;
	size_t n = strlen(path);
	if (n >= 5 && strcmp(path + n - 5, ".skel") == 0)  return GB_LP_SpineSkelRead;
	if (n >= 6 && strcmp(path + n - 6, ".atlas") == 0) return GB_LP_SpineAtlasRead;
	return GB_LP_SpineOtherRead;  // .json fallback or anything else
}

char* _spUtil_readFile (const char* path, int* length) {
	GB_LP_T(_t_read);
	char* result;
	#ifdef ANDROID
		// Use NSData to read from the apk path
		NSString* filePath = [[CCFileUtils sharedFileUtils] fullPathForFilename:@(path)];
		NSData* fileData = [NSData dataWithContentsOfFile:filePath];
		int fileSize = [fileData length];
		char* bytes = malloc(fileSize);
		[fileData getBytes:bytes];
		*length = fileSize;
		result = bytes;
	#else
		result = _spReadFile([[[CCFileUtils sharedFileUtils] fullPathForFilename:@(path)] UTF8String], length);
	#endif
	GB_LP_REC(gb_spine_cat_for_path(path), _t_read, path);
	return result;
}
