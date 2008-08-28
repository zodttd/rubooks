#import <Foundation/Foundation.h>
#include <stdio.h>

#include "txt2pdbdoc.h"
#include "pluckhtml.h"


/**
 * Opens filename and attempts to decode its contents using several PalmOS
 * encodings.
 *
 * @param filename full path/filename of PDB file
 * @param retType reference var to NSString.  Will be set to txt or htm
 *  to reflect type of content returned.  txt might need further processing
 *
 * @return text or html contents of the PDB or an error message if read or
 *  decode fails or if PDB is not one of the supported types
 */
NSMutableString *ReadPDBFile(NSString *filename, NSString **retType) {
  FILE *src = fopen([filename cString], "rb");
  NSMutableString *ret = nil;
  
  // Check magic to figure out what kind of PDB we have.
  char sMagic[9];
  fseek(src, 60, SEEK_SET);
  fread(sMagic, 1, 8, src);
  fseek(src, 0, SEEK_SET);
  sMagic[8] = 0;
  
  if(!strncmp("DataPlkr", sMagic, 8)) {
    // It's a plucker file
    ret = HTMLFromPluckerFile(src);
    *retType = @"htm";
  } else if(!strncmp("TEXtREAd", sMagic, 8)) {
    // It's a PalmDOC format
    ret = decodePalmDoc(src);
    *retType = @"txt";
  } else {
    // We don't know how to deal with this!
    ret = [NSMutableString stringWithFormat:@"Got unknown PDB magic of %s\n", sMagic];
    *retType = @"???";
  }
  
  fclose(src);
  
  return ret;
}