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
 
#define ZIP_DISK_TRAILER	(0x06054b50)
#define ZIP_BUFF_SIZE	512

/* central directory end record */
typedef struct cde_record {
	uint32_t signature;
	uint16_t curr_disk;
	uint16_t cd_disk;
	uint16_t nr_files_disk;
	uint16_t nr_files;
	uint32_t cd_len;
	uint32_t cd_offset;
	uint16_t comment_len;
} CDERecord;

typedef struct local_file_header {
	uint32_t signature; /* 0x04034b50 */
	uint16_t min_version;
	uint16_t flag;
	uint16_t compression;
	uint16_t last_mod_time;
	uint16_t last_mod_date;
	uint32_t crc32;
	uint32_t compressed;
	uint32_t uncompressed;
	uint16_t name_len;
	uint16_t extra_len;
	
	/* file name (variable size) */
	char *name;
	/* extra field (variable size) */
} FileHeader;

typedef struct data_descriptor {
	uint32_t crc32;
	uint32_t compressed;
	uint32_t uncompressed;
} DataDescriptor;

/* Central directory file header */
typedef struct cd_file_record {
	uint32_t signature; /* 0x02014b50 */
	uint16_t made_by;
	uint16_t min_version;
	uint16_t flag;
	uint16_t compression;
	uint16_t last_mod_time;
	uint16_t last_mod_date;
	uint32_t crc;
	uint32_t compressed; // compressed size
	uint32_t uncompressed; // uncrompressed size
	uint16_t name_len;
	uint16_t extra_len;
	uint16_t comment_len;
	uint16_t disk_start;
	uint16_t int_attr;
	uint32_t ext_attr;
	uint32_t local_offset;
	
	/* file name (variable size) */
	char *name;
	/* extra field (variable size) */
	/* file comment (variable size) */
} CDFileHeader;

typedef enum {
	NoCompression = 0,
	Deflated = 8
} CompressionType;