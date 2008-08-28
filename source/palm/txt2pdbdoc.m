/*
**	Text to Doc converter for Palm Pilots
**	txt2pdbdoc.c
**
**	Copyright (C) 1998  Paul J. Lucas
**
**	This program is free software; you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation; either version 2 of the License, or
**	(at your option) any later version.
** 
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
** 
**	You should have received a copy of the GNU General Public License
**	along with this program; if not, write to the Free Software
**	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import <Foundation/Foundation.h>
#import "../BooksDefaultsController.h" //ugh
/* standard */
#include <sys/types.h>			/* for FreeBSD */
#include <netinet/in.h>			/* for htonl, etc */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* local */

/* standard */
#include <time.h>

/*****************************************************************************
*
*	Define integral type Byte, Word, and DWord to match those on the
*	Pilot being 8, 16, and 32 bits, respectively.
*
*****************************************************************************/

typedef unsigned char Byte;
typedef unsigned short Word;
typedef unsigned int DWord;

/********** Other stuff ******************************************************/

#define	dmDBNameLength	32		/* 31 chars + 1 null terminator */
#define RECORD_SIZE_MAX	4096		/* Pilots have a max 4K record size */

#define	palm_date()	(DWord)(time(0) + 2082844800ul)

/*
 * DESCRIPTION
 *
 *	Every record has one of these headers.
 *
 * SEE ALSO
 *
 *	Christopher Bey and Kathleen Dupre.  "Palm File Format Specification,"
 *	Document Number 3008-003, Palm, Inc., May 16, 2000.
 *
 *****************************************************************************/
struct RecordEntryType {
	DWord	localChunkID;		/* offset to where record starts */
	struct {
		unsigned delete   : 1;
		unsigned dirty    : 1;
		unsigned busy     : 1;
		unsigned secret   : 1;
		unsigned category : 4;
	} attributes;
	Byte	uniqueID[3];
};
typedef struct RecordEntryType RecordEntryType;

/*
 ** Some compilers pad structures out to DWord boundaries so using sizeof()
 ** doesn't give the right result.
 */
#define	RecordEntrySize		8


/*
 * DESCRIPTION
 *
 *	This is a PDB database header as currently defined by Palm, Inc.
 *
 * SEE ALSO
 *
 *	Ibid.
 *
 *****************************************************************************/
struct RecordListType		/* 6 bytes total */ {
	DWord	nextRecordListID;
	Word	numRecords;
};
typedef struct RecordListType RecordListType;

#define	RecordListSize		6

/*
 * DESCRIPTION
 *
 *	This is a PDB database header as currently defined by Palm, Inc.
 *
 *****************************************************************************/
struct DatabaseHdrType		/* 78 bytes total */ {
	char		name[ dmDBNameLength ];
	Word		attributes;
	Word		version;
	DWord		creationDate;
	DWord		modificationDate;
	DWord		lastBackupDate;
	DWord		modificationNumber;
	DWord		appInfoID;
	DWord		sortInfoID;
	char		type[4];
	char		creator[4];
	DWord		uniqueIDSeed;
	RecordListType	recordList;
};
typedef struct DatabaseHdrType DatabaseHdrType;

#define DatabaseHdrSize		78

/* constants */
#define	BUFFER_SIZE	6000		/* big enough for uncompressed record */
#define	COMPRESSED	2
#define	COUNT_BITS	3		/* why this value?  I don't know */
#define	DISP_BITS	11		/* ditto */
#define	DOC_CREATOR	"REAd"
#define	DOC_TYPE	"TEXt"
#define	UNCOMPRESSED	1

/* exit status codes */
enum {
	Exit_Success			= 0,
	Exit_Usage			= 1,
	Exit_No_Open_Source		= 2,
	Exit_No_Open_Dest		= 3,
	Exit_No_Read			= 4,
	Exit_No_Write			= 5,
	Exit_Not_Doc_File		= 6,
	Exit_Unknown_Compression	= 7
};

/* macros */
#define	NEW_BUFFER(b)	(b)->data = malloc( (b)->len = BUFFER_SIZE )

#define	GET_DWord(f,n) \
	{ fread( &n, 4, 1, f ) != 1; n = ntohl(n); }

#define	SEEK_REC_ENTRY(f,i) \
	fseek( f, DatabaseHdrSize + RecordEntrySize * (i), SEEK_SET )

/*
 * DESCRIPTION
 *
 *	Record 0 of a Doc file contains information about the document as a
 *	whole.
 *
 *****************************************************************************/
struct doc_record0		/* 16 bytes total */ {
	Word	version;		/* 1 = plain text, 2 = compressed */
	Word	reserved1;
	DWord	doc_size;		/* in bytes, when uncompressed */
	Word	num_records; 		/* PDB header numRecords - 1 */
	Word	rec_size;		/* usually RECORD_SIZE_MAX */
	DWord	reserved2;
};
typedef struct doc_record0 doc_record0;

typedef struct {
	Byte	*data;
	unsigned len;
} buffer;


/*
 * DESCRIPTION
 *
 *	Replace the given buffer with an uncompressed version of itself.
 *
 * PARAMETERS
 *
 *	b	The buffer to be uncompressed.
 *
 *****************************************************************************/
void uncompressPalmDoc( register buffer *b ) {
	Byte *const new_data = malloc( BUFFER_SIZE );
	int i, j;
  
	for ( i = j = 0; i < b->len; ) {
		register unsigned c = b->data[ i++ ];
    
		if ( c >= 1 && c <= 8 )
			while ( c-- )			/* copy 'c' bytes */
				new_data[ j++ ] = b->data[ i++ ];
    
		else if ( c <= 0x7F )			/* 0,09-7F = self */
			new_data[ j++ ] = c;
    
		else if ( c >= 0xC0 )			/* space + ASCII char */
			new_data[ j++ ] = ' ', new_data[ j++ ] = c ^ 0x80;
    
		else {					/* 80-BF = sequences */
			register int di, n;
			c = (c << 8) + b->data[ i++ ];
			di = (c & 0x3FFF) >> COUNT_BITS;
			for ( n = (c & ((1 << COUNT_BITS) - 1)) + 3; n--; ++j )
				new_data[ j ] = new_data[ j - di ];
		}
	}
free( b->data );
b->data = new_data;
b->len = j;
}

/*
 * DESCRIPTION
 *
 *	Decode the source Doc file to a text file.
 *
 * PARAMETERS
 *
 *	src_file_name	The name of the Doc file.
 *
 *	dest_file_name	The name of the text file.  If null, text is sent to
 *			standard output.
 *
 *****************************************************************************/
NSMutableString *decodePalmDoc( FILE *fin ) {
	buffer		buf;
	int		compression;
	DWord		file_size, offset, rec_size;
	DatabaseHdrType	header;
	int		num_records, rec_num;
	doc_record0	rec0;
  NSMutableData *retData;

	/********** read header, we'll assume the magic is okay since we wouldn't have got here otherwise. *****/

	if ( fread( &header, DatabaseHdrSize, 1, fin ) != 1 )
		return @"Error reading PDB";

	num_records = ntohs( header.recordList.numRecords ) - 1; /* w/o rec 0 */

	/********** read record 0 ********************************************/
	SEEK_REC_ENTRY( fin, 0 );
	GET_DWord( fin, offset );		/* get offset of rec 0 */
	fseek( fin, offset, SEEK_SET );
	if ( fread( &rec0, sizeof rec0, 1, fin ) != 1 )
		return @"File access error";

	compression = ntohs( rec0.version );
	if ( compression != COMPRESSED && compression != UNCOMPRESSED ) {
    return @"Unknown PalmDOC Compression type";
	}
  
  retData = [[NSMutableData alloc] initWithCapacity:rec0.rec_size * rec0.num_records];

	/********* read Doc file record-by-record ****************************/
	fseek( fin, 0, SEEK_END );
	file_size = ftell( fin );

	NEW_BUFFER( &buf );
	for ( rec_num = 1; rec_num <= num_records; ++rec_num ) {
		DWord next_offset;

		/* read the record offset */
		SEEK_REC_ENTRY( fin, rec_num );
		GET_DWord( fin, offset );

		/* read the next record offset to compute the record size */
		if ( rec_num < num_records ) {
			SEEK_REC_ENTRY( fin, rec_num + 1 );
			GET_DWord( fin, next_offset );
		} else {
      next_offset = file_size;
    }
		rec_size = next_offset - offset;

		/* read the record */
		fseek( fin, offset, SEEK_SET );
		buf.len = fread( buf.data, 1, rec_size, fin );
		if ( buf.len != rec_size ) {
      break;
      // Error.  Give up.
    }			

		if ( compression == COMPRESSED )
			uncompressPalmDoc( &buf );

    [retData appendBytes:buf.data length:buf.len];
	}
	//  I wish this crap weren't here.  It should be handled in the
	// Books code, like all the other encoding jazz.
  
  BooksDefaultsController *defaults = [[BooksDefaultsController alloc] init];
  NSMutableString *ret;
  if (AUTOMATIC_ENCODING == [defaults defaultTextEncoding])
    {
      NSLog(@"Trying UTF-8 encoding...");
      ret = [[NSMutableString alloc]
	      initWithCString:(char *)[retData bytes]
	      encoding: NSUTF8StringEncoding];
      if (0 == [ret length])
	{
	  [ret release];
	  NSLog(@"Trying ISO Latin-1 encoding...");
	  ret = [[NSMutableString alloc]
		  initWithCString:(char *)[retData bytes]
		  encoding: NSISOLatin1StringEncoding];
	}
      if (0 == [ret length])
	{
	  [ret release];
	  NSLog(@"Trying Mac OS Roman encoding...");
	  ret = [[NSMutableString alloc]
		  initWithCString:(char *)[retData bytes]
		  encoding: NSMacOSRomanStringEncoding];
	}
      if (0 == [ret length])
	{
	  [ret release];
	  NSLog(@"Trying ASCII encoding...");
	  ret = [[NSMutableString alloc] 
		  initWithCString:(char *)[retData bytes]
		  encoding: NSASCIIStringEncoding];
	}
      if (0 == [ret length])
	{
	  [ret release];
	  NSLog(@"No encoding guessed!");
	  ret = [[NSMutableString alloc] initWithString:@"Could not determine text encoding.  Try changing the default encoding in Preferences.\n\n"];
	}
    }
  else
    {
      ret = [[NSMutableString alloc] initWithCString:(char *)[retData bytes]
			     encoding:[defaults defaultTextEncoding]];
      if (0 == [ret length])
	{
	  [ret release];
	  ret = [[NSMutableString alloc] initWithString:@"Incorrect text encoding.  Try changing the default encoding in Preferences.\n\n"];
	}

    }  
  [retData release];
  return [ret autorelease];
}
