#include <Foundation/NSString.h>
#include <stdarg.h>
#include <stdio.h>
void dolog(id formatstring,...)
{
   va_list arglist;
   if (formatstring)
   {
     va_start(arglist, formatstring);
     id outstring = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
     fprintf(stderr, "%s\n", [outstring UTF8String]);
	 va_end(arglist);
	 [outstring release];
   }

}
