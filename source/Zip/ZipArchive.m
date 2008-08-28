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

#import <stdlib.h>
#import <stdio.h>

#import "zlib.h"

#import "ZipArchive.h"
#import "ZipArchive+PrivateAPI.h"

uint16_t JKReadUInt16(FILE *fp) {
	uint16_t n;
	
	fread(&n, sizeof(uint16_t), 1, fp);
	
	return CFSwapInt16LittleToHost(n);
}

uint32_t JKReadUInt32(FILE *fp) {
	uint32_t n;
	
	fread(&n, sizeof(uint32_t), 1, fp);
	
	return CFSwapInt32LittleToHost(n);
}

BOOL isDiskTrailer(char *start) {
	return (*(start+1) == 0x4b) && (*(start+2) == 0x05) && (*(start+3) == 0x06);
}

int zipDiskTrailerInFile(FILE *fp, int size) {
	char *buffer = (char *) calloc(ZIP_BUFF_SIZE, sizeof(char));
	int offset, buflen, trailerPosition;
	
	// Loop thru the zip file from the end backwards, ZIP_BUFF_SIZE bytes a time to find
	// the ZIP_DISK_TRAILER
	offset = size;
	buflen = 0;
	trailerPosition = -1;
	
	while (offset > 0) {
		offset -= ZIP_BUFF_SIZE;
		offset += 20; // keep some overlap
		buflen = ZIP_BUFF_SIZE;
	
		if (offset < 0) {
			offset = 0;
		}
		
		if (offset + buflen > size) {
			buflen = size - offset;
		}
		
		fseek(fp, offset, SEEK_SET);
		fread(buffer, sizeof(char), buflen, fp);
		
		// loop thru buf to find byte marker
		char *pos;
		for (pos = buffer + buflen; pos >= buffer; pos--) {
			if (*pos == 0x50 && isDiskTrailer(pos)) {
				trailerPosition = offset + (pos - buffer);
				goto positionBreak;
			}
		} 
	}
	
	positionBreak:
	
	free(buffer);
	return trailerPosition;
}

void readCentralDirectoryTrailer(CDERecord *record, FILE *fp) {
	record->signature = JKReadUInt32(fp);
	record->curr_disk = JKReadUInt16(fp);
	record->cd_disk = JKReadUInt16(fp);
	record->nr_files_disk = JKReadUInt16(fp);
	record->nr_files = JKReadUInt16(fp);
	record->cd_len = JKReadUInt32(fp);
	record->cd_offset = JKReadUInt32(fp);
	record->comment_len = JKReadUInt16(fp);
}

void readCDFileHeader(CDFileHeader *header, FILE *fp) {
	// TODO: read header in single read statement

	header->signature = JKReadUInt32(fp);
	header->made_by = JKReadUInt16(fp);
	header->min_version = JKReadUInt16(fp);
	header->flag = JKReadUInt16(fp);
	header->compression = JKReadUInt16(fp);
	header->last_mod_time = JKReadUInt16(fp);
	header->last_mod_date = JKReadUInt16(fp);	
	header->crc = JKReadUInt32(fp);
	header->compressed = JKReadUInt32(fp);
	header->uncompressed = JKReadUInt32(fp);
	header->name_len = JKReadUInt16(fp);
	header->extra_len = JKReadUInt16(fp);
	header->comment_len = JKReadUInt16(fp);
	header->disk_start = JKReadUInt16(fp);
	header->int_attr = JKReadUInt16(fp);
	header->ext_attr = JKReadUInt32(fp);
	header->local_offset = JKReadUInt32(fp);
	
	if (header->name_len > 0) {
		header->name = (char *) malloc(sizeof(char) * (header->name_len + 1));
		fread(header->name, header->name_len, 1, fp);
		header->name[header->name_len] = '\0';
	} else {
		header->name = nil;
	}
	
	fseek(fp, header->extra_len, SEEK_CUR); // skip over extra field
	fseek(fp, header->comment_len, SEEK_CUR); // skip over current
}

void readLocalFileHeader(FileHeader *header, FILE *fp) {
	// TODO: read header in single read statement

	header->signature = JKReadUInt32(fp);
	header->min_version = JKReadUInt16(fp);
	header->flag = JKReadUInt16(fp);
	header->compression = JKReadUInt16(fp);
	header->last_mod_time = JKReadUInt16(fp);
	header->last_mod_date = JKReadUInt16(fp);
	header->crc32 = JKReadUInt32(fp);
	header->compressed = JKReadUInt32(fp);
	header->uncompressed = JKReadUInt32(fp);
	header->name_len = JKReadUInt16(fp);
	header->extra_len = JKReadUInt16(fp);
	
	JKLog(@"Name len: %d", header->name_len);
	JKLog(@"Extra len: %d", header->extra_len);
	
	if (header->name_len > 0) {
			header->name = (char *) malloc(sizeof(char) * (header->name_len + 1));
			fread(header->name, header->name_len, 1, fp);
			header->name[header->name_len] = '\0';
	} else {
		header->name = nil;
	}
	
	fseek(fp, header->extra_len, SEEK_CUR); // ignore extra field
}


#pragma mark -
#pragma mark File reading (funopen) delegates
int ZipArchive_entry_do_read(void *cookie, char *buf, int len) {
	return [((ZipEntryInfo *)cookie)->archive readFromEntry:(ZipEntryInfo *)cookie buffer:buf length:len];
}

int ZipArchive_entry_do_close(void *cookie) {
	return [((ZipEntryInfo *)cookie)->archive closeEntry:(ZipEntryInfo *)cookie];
}

#pragma mark -

@implementation ZipArchive
+ (id) archiveWithFile:(NSString *)location {
	return [[[ZipArchive alloc] initWithFile:location] autorelease];
}

- (id) initWithFile:(NSString *)location {
	// check if file exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:location]) {
		return nil;
	}
	
	// check if file is readable
	if (![[NSFileManager defaultManager] isReadableFileAtPath:location]) {
		return nil;
	}

	self = [super init];
	
	if (self) {
		file = [location retain];
		central_directory = nil;
		file_count = 0;
	}
	
	return self;
}

- (NSString *) name {
	return [file lastPathComponent];
}

- (NSString *) path {
	return file;
}

- (int) numberOfEntries {
	if (central_directory == nil) {
		[self readCentralDirectory];
	}

	return file_count;
}

- (NSArray *) entries {
	if (central_directory == nil) {
		[self readCentralDirectory];
	}

	return file_names;
}

- (NSDictionary *) infoForEntry:(NSString *)fileName {
	return nil;
}

- (FILE *) entryNamed:(NSString *)fileName {
	CDFileHeader *cd_header = [self CDFileHeaderForFile:fileName];
	
	if (cd_header == nil) {
		JKLog(@"file not found in archive");
		return NULL;
	} 
	
	if (cd_header->compressed == 0) {
		JKLog(@"Compressed size == 0: not a file");
		return NULL;
	}
	
	/* cookie that will be passed to delegate fread functions */
	ZipEntryInfo *entry_io = (ZipEntryInfo *) malloc(sizeof(ZipEntryInfo));
	entry_io->archive = self;
	entry_io->read_pos = 0;
	entry_io->uncompressed_size = cd_header->uncompressed;
	entry_io->compressed_size = cd_header->compressed;
	entry_io->fp = fopen([file UTF8String], "r");
	
	if (entry_io->fp == NULL) {
		JKLog(@"Unable to open zip for reading");
		return NULL;
	}
	
	/* Move to file header position in zip file */
	fseek(entry_io->fp, cd_header->local_offset, SEEK_SET);
	readLocalFileHeader(&(entry_io->file_header), entry_io->fp);
	
	entry_io->offset_in_file = ftell(entry_io->fp); // save position of first compressed data byte
	
	/* allocate zlib stream for decompression */
	entry_io->stream = (z_streamp) malloc(sizeof(struct z_stream_s));
	if (entry_io->stream == NULL) {
		NSLog(@"entry_io->stream == NULL");
	}
	entry_io->stream->zalloc = Z_NULL;
	entry_io->stream->zfree = Z_NULL;
	entry_io->stream->opaque = 0;
	entry_io->stream->next_in = Z_NULL;
	entry_io->stream->avail_in = 0;
	
	/* initialize zlib stream, read header */
	int result = inflateInit2(entry_io->stream, -15);
	if (result != Z_OK) {
		// TODO: free entry_io & stream
		JKLog(@"Error setting up decompression stream");
		return nil;
	}
	
	// TODO: setup fclose handler
	return funopen(
		(void *)entry_io, 
		ZipArchive_entry_do_read,
		NULL,
		NULL,
		ZipArchive_entry_do_close
	);
}


#pragma mark -
#pragma mark Private method implementation
- (void) readCentralDirectory {
	CDERecord trailer;
	int filesize, trailerPosition;
	unsigned int cd_pos;
	FILE *fp = fopen([file UTF8String], "r");
	
	fseek(fp, 0, SEEK_END);
	filesize = (int) ftell(fp);
	
	trailerPosition = zipDiskTrailerInFile(fp, filesize);
	if (trailerPosition < 0) {
		JKLog(@"No disk trailer found in file");
		return;
	}
	
	file_names = [[NSMutableArray alloc] init];
	
	JKLog(@"Trailer found at: %d", trailerPosition);
	
	fseek(fp, trailerPosition, SEEK_SET);
	readCentralDirectoryTrailer(&trailer, fp);
	
	file_count = trailer.nr_files;
	cd_pos = trailer.cd_offset;
	
	central_directory = (CDFileHeader *) malloc(sizeof(CDFileHeader) * file_count);
	
	unsigned int i;
	fseek(fp, cd_pos, SEEK_SET);
	for (i=0; i<file_count; i++) {
		readCDFileHeader(&(central_directory[i]), fp);
		[file_names addObject:[NSString stringWithUTF8String:central_directory[i].name]];
	}
	
	fclose(fp);
}

- (int) readFromEntry:(ZipEntryInfo *)entry_io buffer:(char *)buf_out length:(int)len_out {
	unsigned char buf_read[512];
	int num_read, total_in_read;

	if (len_out < 1) {
		return 0;
	}

	JKLog(@"Position in file: %d + %d = %d", entry_io->offset_in_file, entry_io->read_pos, entry_io->offset_in_file + entry_io->read_pos);
	int offset_in_file = entry_io->offset_in_file + entry_io->read_pos; // read position on compressed bytes

	entry_io->stream->next_out = (unsigned char *) buf_out;
	entry_io->stream->avail_out = len_out;
	entry_io->stream->avail_in = 0;
	
	total_in_read = 0;
	
	while (entry_io->stream->avail_out > 0 // room left in output buffer
		&& total_in_read + entry_io->read_pos < entry_io->compressed_size // not read all compressed bytes yet
		) {
		
		// read compressed bytes
		fseek(entry_io->fp, offset_in_file + total_in_read, SEEK_SET); // TODO: maybe only once per readFromEntry: call
		num_read = fread(buf_read, sizeof(char), 512, entry_io->fp);
		
		entry_io->stream->next_in = buf_read;
		entry_io->stream->avail_in = num_read;
	
		// decompress
		/*int res =*/ (void) inflate(entry_io->stream, Z_SYNC_FLUSH);
		// TODO: check inflate result
		
		total_in_read += num_read - entry_io->stream->avail_in;
	}
	
	entry_io->read_pos += total_in_read;
	
	// return number of bytes in output buffer
	return len_out - entry_io->stream->avail_out;
}

- (int) closeEntry:(ZipEntryInfo *)entry_io {
	int close_status = 0; // EOF for failure, see man fclose

	entry_io->archive = nil; // weak reference

	if (fclose(entry_io->fp) != 0) {
		close_status = EOF;
	}

	if (inflateEnd(entry_io->stream) != Z_OK) {
		close_status = EOF;
	}
	free(entry_io->stream);
	
	free(entry_io);
	
	return close_status;
}

- (CDFileHeader *) CDFileHeaderForFile:(NSString *)fileName {
	if (central_directory == nil) {
		[self readCentralDirectory];
	}

	int i;
	const char *tmp_name = [fileName UTF8String];
	char *name = malloc(sizeof(char) * (strlen(tmp_name) + 1));
	strncpy(name, tmp_name, strlen(tmp_name) + 1);
	
	for (i=0; i<file_count; i++) {
		if (strncmp(name, central_directory[i].name, strlen(name)) == 0) {
			return &(central_directory[i]);
		}
	}
	
	return nil;
}

- (void) dealloc {
	[file release];

	if (central_directory != NULL) {
		int i;
		for (i=0; i<file_count; i++) {
			if (central_directory[i].name != nil) {
				free(central_directory[i].name);
			}
		}
		free(central_directory);
	}
	
	
	[file_names release];
	
	[super dealloc];
}
@end
