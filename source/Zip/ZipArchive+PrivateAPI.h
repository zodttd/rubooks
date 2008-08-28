/*
 * Zip.framework
 * Copyright 2007, Joris Kluivers
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice, 
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products 
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ZipStructure.h"
#import <stdio.h>

/* Struct used as cookie to keep information about the file being read */
// TODO: change z_streamp to z_stream (pointer to plain struct)
typedef struct {
	ZipArchive *archive;
	FILE *fp; // file pointer for reading
	FileHeader file_header;
	unsigned int offset_in_file; // start data byte
	z_streamp stream;
	unsigned int read_pos;
	int compressed_size;
	int uncompressed_size;
} ZipEntryInfo;

/* Utility functions for reading bytes from little-endian based file */
uint16_t JKReadUInt16(FILE *fp);
uint32_t JKReadUInt32(FILE *fp);

/* BOOL function to check if char pointer points to start of DiskTrailer */
BOOL isDiskTrailer(char *start);

/* Find the location of the disk trailer in the file fp by reading from end to start */
int zipDiskTrailerInFile(FILE *fp, int size);

/* Read a file header from the central directory */
void readCDFileHeader(CDFileHeader *header, FILE *fp);

/**
 * Delegate functions for the virtual zip file stream. Functions call methods on 
 * a ZipArchive object pointed to by the cookie. The cookie is of type ZipEntryIO.
 */
int ZipArchive_entry_do_read(void *cookie, char *buf, int len);


@interface ZipArchive (PrivateAPI)
/**
 * Delegate method for the virtual zip file stream. Reads the specified number
 * of bytes form the requested file in the ZipArchive.
 */
- (int) readFromEntry:(ZipEntryInfo *)entry_io buffer:(char *)buf length:(int)length;
- (int) closeEntry:(ZipEntryInfo *)entry_io;

- (void) readCentralDirectory;
- (CDFileHeader *) CDFileHeaderForFile:(NSString *)name;
@end

#import <Foundation/NSDebug.h>
#define JKLog(s,...) \
	if (NSDebugEnabled) { NSLog(s, ##__VA_ARGS__); }
