/*
*
* imgtxtio.prg
*
*/

#include "fivewin.ch"

#define SRCCOPY      0x00CC0020

#define DT_TOP              0
#define DT_LEFT             0
#define DT_CENTER           1
#define DT_RIGHT            2
#define DT_VCENTER          4
#define DT_BOTTOM           8
#define DT_WORDBREAK       16
#define DT_SINGLELINE      32
#define DT_CALCRECT      1024
#define DT_EDITCONTROL              0x00002000

#define NULL_BRUSH          5

#define OBJ_PEN             1
#define OBJ_BRUSH           2
#define OBJ_DC              3
#define OBJ_METADC          4
#define OBJ_PAL             5
#define OBJ_FONT            6
#define OBJ_BITMAP          7
#define OBJ_REGION          8
#define OBJ_METAFILE        9
#define OBJ_MEMDC           10
#define OBJ_EXTPEN          11
#define OBJ_ENHMETADC       12
#define OBJ_ENHMETAFILE     13
#define OBJ_COLORSPACE      14

#define SM_CXICON               11
#define SM_CYICON               12

#define TRANSPARENT         1
#define OPAQUE              2

#define RGN_AND             1
#define RGN_OR              2
#define RGN_XOR             3
#define RGN_DIFF            4
#define RGN_COPY            5
#define RGN_MIN             RGN_AND
#define RGN_MAX             RGN_COPY

#xtranslate ISCOLOR( <n> ) => ( HB_ISNUMERIC( <n> ) .and. GetObjectType( <n> ) == 0 .and. <n> >= 0 .and. <n> <= 0xffffffff )
#xtranslate ISRGB( <n> )   => ( HB_ISNUMERIC( <n> ) .and. GetObjectType( <n> ) == 0 .and. <n> >= 0 .and. <n> <= 0x00ffffff )
#xtranslate ISARGB( <n> )  => ( HB_ISNUMERIC( <n> ) .and. GetObjectType( <n> ) == 0 .and. <n> > 0x00ffffff .and. <n> <= 0xffffffff )

#define CHART_COLORS { METRO_AMBER, METRO_OLIVE, CLR_HMAGENTA, CLR_HBLUE, CLR_HRED, CLR_HGREEN, CLR_RED, CLR_MAGENTA, CLR_GREEN }

//----------------------------------------------------------------------------//

static nIconWidth, nIconHeight

//----------------------------------------------------------------------------//

INIT PROCEDURE imgtxtio_Init

   nIconWidth   := GetSysMetrics( SM_CXICON )
   nIconHeight  := GetSysMetrics( SM_CYICON )

return

//----------------------------------------------------------------------------//

function WebPageContents( cUrl, lText )

   local oHttp, cContents := ""
   local nOle  := 0
   local aOle  := { "MSXML2.XMLHTTP", "WINHTTP.WinHttpRequest.5.1" }

   if Lower( Left( cUrl, 7 ) ) == "http://" .or. Lower( Left( cUrl, 8 ) ) == "https://"

      do while Empty( cContents ) .and. nOle < 2
         nOle++
         TRY
            oHttp     := FWGetOleObject( aOle[ nOle ] )
            oHttp:Open("GET", cUrl, .f. )
            oHttp:Send()
            DEFAULT lText := .f.
            if lText
               cContents   := oHttp:ResponseText()
            else
               cContents   := oHttp:ResponseBody()
               memowrit( 'img.txt', cContents )
            endif
         CATCH
         END
      enddo
   endif

return cContents

//----------------------------------------------------------------------------//

function WebImage( cImage )

   if Lower( Left( cImage, 7 ) ) == "http://" .or. Lower( Left( cImage, 8 ) ) == "https://"
      cImage   := WebPageContents( cImage, .f. )      
   endif

   if "base64" $ cImage
      return ExtractBase64Image( cImage )
   elseif IsBinaryData( cImage )
      return cImage
   endif

return ""

//----------------------------------------------------------------------------//

function ExtractBase64Image( cText )

   local cImage   := ""
   local c, cBase64, cImgType, lUrlEncode
   local nAt

   if ( nAt := At( "base64", cText ) ) == 0
      return ""
   endif

   cText    := StrTran( cText, CRLF,   "" )
   cText    := StrTran( cText, CHR(10), "" )

   c           := SubStr( cText, nAt + 6, 1 )
   lUrlEncode  := ( c == "%" )
   if lUrlEncode
      cBase64  := SubStr( cText, nAt + 9 )
   else
      cBase64  := SubStr( cText, nAt + 7 )
   endif

   if ( nAt := At( ">", cBase64 ) ) > 0
      cBase64  := Left( cBase64, nAt - 1 )
   endif

   do while Right( cBase64, 1 ) $ [>)"']
      cBase64 := Left( cBase64, Len( cBase64 ) - 1 )
   enddo

   cImage   := HB_BASE64DECODE( cBase64 )
   cImgType := MemoryBufferType( cImage )

   if !( Left( cImgType, 4 ) == "IMG." )
      return ""
   endif

return cImage

//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//

EXTERNAL GDIBMP

