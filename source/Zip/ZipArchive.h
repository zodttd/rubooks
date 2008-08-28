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
 
/*!
	@header	Zip.framework
	Zip.framework provides functionality to read from zip a zip archive using just
	a few lines of code.
	
	@copyright	Joris Kluivers
*/

#import <Foundation/Foundation.h>

#import "ZipStructure.h"

/*!
	@class	ZipArchive
	@discussion ZipArchive represents a zip file on disk.
*/

@interface ZipArchive : NSObject {
	NSString *file;
	NSMutableArray *file_names;
	
	int file_count;
	CDFileHeader *central_directory; // array of CDFileHeaders
}

/*!
	@functiongroup	Creating ZipArchive objects
*/

/*!
	@method	archiveWithFile
	@abstract	An autoreleased version of the result returned by initWithFile
*/
+ (id) archiveWithFile:(NSString *)location;

/*!
	@method initWithFile
	@result A ZipArchive or nil if file doesn't exist or is not readable
*/
- (id) initWithFile:(NSString *)location;

/*!
	The filename of the ZipArchive. Equivalent to [[self path] lastPathComponent];
*/
- (NSString *) name;

/*! 
	The complete path to the ZipArchive on disk
*/
- (NSString *) path;

/*!
	@method numberOfEntries
	@result	The number of entries in the zip file, this includes directories
*/
- (int) numberOfEntries;

/*!
	@method entries
	@abstract Returns an array with all names of entries in the zip archive.
	@result	An array of strings
*/
- (NSArray *) entries;

/*!
	@method	entryNamed
	@abstract	Returns a c filestream that can be read from. 
	@discussion	Currently the filestream only supports fread. fseek and fwrite are not implemented yet.
	@param The path of the entry in the archive
	@result	A standard c filestream that can be read from: NULL if the path doesn't exist or is a directory
*/
- (FILE *) entryNamed:(NSString *)filePath;

// TODO: - (NSData *) dataForEntryNamed:(NSString *)fileName;
@end
