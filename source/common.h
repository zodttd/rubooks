// common.h, for ruBooks.app
/*

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; version 2
 of the License.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/


#ifndef COMMON_H
#define COMMON_H
/**
 * appended to the home directory to create the real EBooksPath
 */
#define OUT_FILE @"/var/logs/ruBooks.out"
#define ERR_FILE @"/var/logs/ruBooks.err"

#define EBOOK_PATH_SUFFIX @".."
// #define EBOOK_PATH_SUFFIX @"Media/EBooks"
#define LIBRARY_PATH @"Library/ruBooks"
#define DEFAULT_REAL_PATH @"Library/ruBooks/Default.png"
#define MIN_FONT_SIZE (10)
#define MAX_FONT_SIZE (36)

#define AUTOMATIC_ENCODING (0)
#define ENCODINGSELECTED @"encodingSelectedNotification"
#define COLORSELECTED @"colorSelectedNotification"
#define NEWFONTSELECTED @"newFontSelectedNotification"
#define CHANGEDSCROLLSPEED @"scrollSpeedChangedNotification"

#define OPENEDTHISFILE @"openedThisFileNotification"
#define RELOADTOPBROWSER @"reloadTopBrowserNotification"
#define RELOADALLBROWSERS @"reloadAllBrowsersNotification"

#define DONATE_URL_STRING @"http://colel.info/rubooks/"

#endif

