#include "fivewin.ch"

#ifdef __XHARBOUR__
   #xtranslate HB_CurDrive() => CurDrive()
#endif

#define JPEG_DEFAULT        0
#define JPEG_QUALITYSUPERB  0x80 // save with superb quality (100:1)
#define JPEG_QUALITYGOOD    0x0100  // save with good quality (75:1)
#define JPEG_QUALITYNORMAL  0x0200  // save with normal quality (50:1)
#define JPEG_QUALITYAVERAGE 0x0400  // save with average quality (25:1)
#define JPEG_QUALITYBAD     0x0800  // save with bad quality (10:1)
#define JPEG_PROGRESSIVE   0x2000   // save as a progressive-JPEG (use | to combine with other save flags)
#define JPEG_SUBSAMPLING_411 0x1000    // save with high 4x1 chroma subsampling (4:1:1)
#define JPEG_SUBSAMPLING_420 0x4000    // save with medium 2x2 medium chroma subsampling (4:2:0) - default value
#define JPEG_SUBSAMPLING_422 0x8000    // save with low 2x1 chroma subsampling (4:2:2)
#define JPEG_SUBSAMPLING_444 0x10000   // save with no chroma subsampling (4:4:4)
#define JPEG_OPTIMIZE      0x20000     // on saving, compute optimal Huffman coding tables (can reduce a few percent of file size)
#define JPEG_BASELINE      0x40000     // save basic JPEG, without metadata or any markers

#define USEGDI

#define a4_width           595.0
#define a4_height          842.0

//----------------------------------------------------------------------------//

function FWSavePreviewToPDF( oDevice, cPDF, lOpen )   // oDevice can be oPrinter or oPreview

   local cOrient, oPDF
   local hWnd
   lOpen := .f.

   if oDevice:IsKindOf( "TPREVIEW" )
      hWnd    := oDevice:oWnd:hWnd
      oDevice := oDevice:oDevice
   endif
#ifndef USEGDI
   if LoadFreeImage() <= 32
      MsgAlert( FWString( "freeimage.dll not found" ), FWString( "Alert" ) )
      return nil
   endif
#endif
    
   DEFAULT cPDF   := cGetFile( FWString( "PDF files | *.pdf |" ),;
                               FWString( "Select PDF File to Save" ),, ;
                               hb_CurDrive() + ":\" + CurDir() + "\documentos\", .T.,,,;
                               hb_CurDrive() + ":\" + CurDir() + "\documentos\" + ;
                               If( oDevice:IsKindOf( "TPreview" ),;
                               oDevice:cName, oDevice:cDocument ) + ".pdf"  )
   if ! Empty( cPDF )
      cPDF = cFileSetExt( cPDF, "pdf" )
      CursorWait()
      cOrient = If( oDevice:nHorzSize() > oDevice:nVertSize(), 'L', 'P' )
      oPdf = fwPdf():New( cPdf, cOrient )
      AEval( oDevice:aMeta, { | cMeta | oPdf:AddMeta( cMeta ) } )
      oPdf:Close()
      CursorArrow()

      DEFAULT lOpen := MsgYesNo( If( FWLanguageID() == 2, FWString( "¿" ) + " ", "" ) + ;
                       FWString( "View" ) + ;
                       " " + cPDF + " " + FWString( "(Y/N)" ) + " ?",;
                       FWString( "Please select" ) )

      if lOpen
         ShellExecute( IfNil( hWnd, GetWndDefault() ), "open", cPDF )
      endif
   else
      cPDF  := nil
   endif

return cPDF

//----------------------------------------------------------------------------//

function FWJPGTOPDF( aJpg, cPDF )

   local oPdf  := FWPdf():New( cPDF )

   if ValType( aJpg ) != 'A'
      aJpg     := { aJpg }
   endif

   AEval( aJpg, { |cJpg| oPdf:nPage++, oPdf:WritePage( MemoRead( cJpg ) ) } )
   oPdf:Close()

return cPDF

//----------------------------------------------------------------------------//

static function Emf2Jpeg( cEMF )

   local cJpeg    := cFileSetExt( cEMF, "jpg" )
   local hDC1, hDC, hDib, hDib2, hMem, hBmp, hOldBmp, hEMF
   local cBuf, oRect, lRet := .f.
   local nFormat

   cBuf         := MemoRead( cEMF )
#ifdef USEGDI
   GDIPLUSEMFTOJPG( cBuf, Len( cBuf ), AnsiToWide( cJpeg ), 5 ) //  nQuality )
   cBuf        := MemoRead( cJpeg )
#else
   oRect        := TRect():New( 0, 0, Bin2L( SubStr( cBuf, 21, 4 ) ) / 2, ;
                                  Bin2L( SubStr( cBuf, 17, 4 ) ) / 2  )
   hEMF        := GetEnhMetaFile( cEMF )
   hDC1        := GetDC( GetDesktopWindow() )
   hDC         := CreateCompatibleDC( hDC1 )
   hBmp        := CreateCompatibleBitmap( hDC1, oRect:nWidth, oRect:nHeight )
   hOldBmp     := SelectObject( hDC, hBmp )
   FillRect( hDC, oRect:aRect, GetStockObject( 0 ) )
   PlayEMF( hDC, hEMF, oRect:cRect )

   hDib        := DibFromBitmap( hBmp )
   cBuf        := DibToStr( hDib )

   GlobalFree( hDib )
//   CloseEnhMetafile( hEMF )     // commented out 2014-02-13
   DeleteEnhMetafile( hEMF )      // inserted 2014-02-13

   SelectObject( hDC, hOldBmp )
   DeleteDC( hDC )
   DeleteDC( hDC1 )
   DeleteObject( hBmp )

   hMem        := FI_OpenMemory( cBuf, Len( cBuf ) )
   nFormat     := FI_GetFileTypeFromMemory( hMem, 0 )
   hDib        := FI_LoadFromMemory( nFormat, hMem, 0 )
   cBuf        := nil  // to release memory
   FI_CloseMemory( hMem )
   hDib2       := FICnv24( hDib )
   FIUnload( hDib )
   lRet        := FISave( 2, hDib2, cJpeg, JPEG_DEFAULT )
   FIUnload( hDib2 )
   cBuf        := If( lRet, MemoRead( cJpeg ), "" )
#endif
   FErase( cJpeg )

return cBuf

//----------------------------------------------------------------------------//

CLASS FWPDF STATIC

   DATA nPageWidth   INIT a4_width
   DATA nPageHeight  INIT a4_height
   DATA nPage        INIT 0
   DATA nObject      INIT 1
   DATA nNextObj     INIT 5
   DATA nDocLen      INIT 0
   DATA cKids        INIT ""
   DATA aRefs        INIT Array( 0 )
   DATA nImageAt

   METHOD New( cFile, cOrient )
   METHOD AddMeta( cMeta )
   METHOD WritePage()
   METHOD Close()

ENDCLASS

METHOD New( cFile, cOrient ) CLASS FWPDF

   DEFAULT cOrient   := "P"

   if cOrient == "P"
      ::nPageWidth   := a4_width
      ::nPageHeight  := a4_height
   else
      ::nPageWidth   := a4_height
      ::nPageHeight  := a4_width
   endif
   ::aRefs           := { 0, 0 }
   ::nDocLen      := PdfBegin( cFile )

return Self

METHOD AddMeta( cMeta ) CLASS FWPDF

   local nAt

   ::nPage++
   ::WritePage( Emf2Jpeg( cMeta ) )

return Self

METHOD WritePage( cJpeg ) CLASS FWPDF

   local nAt, x, y
   local lClose   := Empty( cJpeg )

   Aadd( ::aRefs, ::nDocLen )

   if ! lClose
      ::cKids += " " + NTrim( ::nObject + 1 ) + " 0 R"
   endif

   AAdd( ::aRefs, PgPart1( ::nObject, ::nPageWidth, ::nPageHeight ) )
   ::nObject   += 3
   if ! lClose
      ::nNextObj ++
      ::nImageAt   := ::nNextObj
   endif
   AAdd( ::aRefs, PgPart2( ::nObject - 1, ::nPage, ::nImageAt ) )
   AAdd( ::aRefs, PgPart3( ::nObject, ::nPageWidth, ::nPageHeight, ::nPage ) )
   ::nDocLen := PgPart4( ++ ::nObject )

   if ! lClose
      Aadd( ::aRefs, ::nDocLen )

      nAt   := At( Chr( 255 ) + Chr( 192 ), cJpeg ) + 5
      y     := Asc( Substr( cJpeg, nAt,     1 ) ) * 256 + Asc( Substr( cJpeg, nAt + 1, 1 ) )
      x     := Asc( Substr( cJpeg, nAt + 2, 1 ) ) * 256 + Asc( Substr( cJpeg, nAt + 3, 1 ) )

      ::nDocLen := PGJPEG1( ::nImageAt, ::nPage, x, y, cJpeg )
   endif

   ::nObject      := ::nNextObj
   ::nNextObj     := ::nObject + 4

return nil

METHOD Close() CLASS FWPDF

   ::WritePage()
   ::aRefs[ 2 ]   := ::nDocLen
   Aadd( ::aRefs, PdfClose1( ::nPage, ::cKids ) )
   AAdd( ::aRefs, PdfClose2( ++ ::nObject, Left( TToS( DateTime() ), 14 ) ) )
   AAdd( ::aRefs, PdfClose3( ++ ::nObject ) )
   PdfClose4( ++ ::nObject, ::aRefs )

return Self

//----------------------------------------------------------------------------//

static function NTrim( n )
return LTrim( Str( n ) )

//----------------------------------------------------------------------------//

dll32 static function PLAYEMF( hDC AS LONG, hEMF AS LONG, cRect AS LPSTR ) AS BOOL;
      PASCAL FROM "PlayEnhMetaFile" LIB "gdi32.dll"

//----------------------------------------------------------------------------//

#pragma BEGINDUMP
#include <windows.h>
#include <hbapi.h>

#ifdef __XHARBOUR__
  #define hb_parvnl( x, y ) hb_parnl( x, y )
  #define hb_storvnl( v, x, y ) hb_stornl( v, x, y )
#endif


FILE * fp;
LONG nDocLen;
int iBufLen = 0;

HB_FUNC_STATIC( PDFBEGIN ) // ( cPDF )
{
   fp       = fopen( hb_parcx( 1 ), "wb" );
   nDocLen  = fprintf( fp, "%s\r\n", "%PDF-1.3" );

   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PGPART1 ) // ( nObj, nPageWidth, nPageHeight )
{

   LONG  nObj;
   char * format = "%d 0 obj\r\n<<\r\n/Type /Page /Parent 1 0 R\r\n"
                   "/Resources %d 0 R\r\n/MediaBox [ 0 0 %.2f %.2f ]\r\n"
                   "/Contents %d 0 R\r\n>>\r\nendobj\r\n";

   nObj     =  hb_parnl( 1 );
   nDocLen  += fprintf( fp, format, nObj+1, nObj+2, hb_parnd( 2 ), hb_parnd( 3 ), nObj+3 );

   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PGPART2 ) // ( nObject, nPage, nImageAt )
{
   char * format = "%d 0 obj\r\n<<\r\n/ColorSpace << /DeviceRGB /DeviceGray >>\r\n"
                   "/ProcSet [ /PDF /Text /ImageB /ImageC ]\r\n/XObject\r\n<<"
                   "\r\n/Image%d %d 0 R\r\n>>\r\n>>\r\nendobj\r\n";

   nDocLen  += fprintf( fp, format, hb_parnl( 1 ), hb_parnl( 2 ), hb_parnl( 3 ) );
   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PGPART3 ) // ( nObject, nPageWidth, nPageHeight, nPage )
{
   LONG nObj;

   nObj     =  hb_parnl( 1 );
   nDocLen  += fprintf( fp, "%d 0 obj << /Length %d 0 R \r\n\r\n>>\r\nstream\r\n",
                        nObj, nObj + 1 );
   iBufLen  =  fprintf( fp,
                        "\r\nq\r\n%.1f 0 0 %.1f 0 0 cm\r\n/Image%d Do\r\nQ \r\nendstream\r\nendobj\r\n",
                        hb_parnd( 2 ), hb_parnd( 3 ), hb_parnl( 4 ) );
   nDocLen  += iBufLen;
   iBufLen  -= 21;

   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PGPART4 ) // ( nObj, nBufLen )
{
   char * format = "%d 0 obj\r\n%d\r\nendobj\r\n";

   nDocLen  += fprintf( fp, format, hb_parnl( 1 ), iBufLen );
   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PGJPEG1 ) // ( nImageAt, nPage, nJpegWidth, nJpegHeight, cJpegBuf )
{

   LONG nBufSize = hb_parclen( 5 );
   char * format = "%d 0 obj\r\n<<\r\n/Type /XObject\r\n/Subtype /Image\r\n/Name /Image%d\r\n"
              "/Filter [ /DCTDecode ]\r\n/Width %d\r\n/Height %d\r\n/BitsPerComponent 8\r\n"
              "/ColorSpace/DeviceRGB\r\n/Length %d\r\n>>\r\nstream\r\n";

   nDocLen  += fprintf( fp, format, hb_parnl( 1 ), hb_parnl( 2 ), hb_parnl( 3 ), hb_parnl( 4 ), nBufSize );
   nDocLen  += fwrite( hb_parcx( 5 ), sizeof( char ), nBufSize, fp );
   nDocLen  += fprintf( fp, "endstream\r\nendobj\r\n" );
   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PDFCLOSE1 ) // ( nPages, cKids )
{
   char * format = "1 0 obj\r\n<<\r\n/Type /Pages /Count %d\r\n/Kids [%s ]\r\n>>\r\nendobj\r\n";

   nDocLen  += fprintf( fp, format, hb_parnl( 1 ), hb_parcx( 2 ) );
   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PDFCLOSE2 ) // ( nObj, cDateTime )
{
   char * format = "%d 0 obj\r\n<< /Title ()\r\n/Producer ()\r\n/Author ()\r\n/Creator ()\r\n"
           "/Subject ()\r\n/Keywords ()\r\n/CreationDate (D:%s)\r\n>>\r\nendobj\r\n";

   nDocLen  += fprintf( fp, format, hb_parnl( 1 ), hb_parcx( 2 ) );
   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PDFCLOSE3 ) // ( nObject )
{
   char * format = "%d 0 obj\r\n<< /Type /Catalog /Pages 1 0 R /Outlines %d 0 R >>\r\nendobj\r\n";
   LONG nObject = hb_parnl( 1 );

   nDocLen  += fprintf( fp, format, nObject, nObject + 1 );
   hb_retnl( nDocLen );
}

HB_FUNC_STATIC( PDFCLOSE4 ) // ( nObj, aRefs )
{

   long nRefs, nLen;
   int n;
   LONG nObj = hb_parnl( 1 );

   nDocLen  += fprintf( fp, "%d 0 obj\r\n<< /Type /Outlines /Count 0 >>\r\nendobj\r\n\r\n", hb_parnl( 1 ) );
   // This is the final Document Length to be written at the end of file

   nRefs    =  hb_parinfa( 2, 0 );
   nLen     = fprintf( fp, "xref\r\n0 %d\r\n", nObj + 1 );

   nLen     += fprintf( fp, "%010d 65535 f\r\n", hb_parvnl( 2, 1 ) );
   for ( n = 2; n <= nRefs; n++ )
   {
      nLen  += fprintf( fp, "%010d 00000 n\r\n", hb_parvnl( 2, n ) );
   }

   nLen     += fprintf( fp,
            "trailer << /Size %d /Root %d 0 R /Info %d 0 R >>\r\nstartxref\r\n%d\r\n%s\r\n",
            nObj + 1, nObj - 1, nObj - 2, nDocLen, "%%EOF" );

   nDocLen  += nLen;
   fclose( fp );
   fp       = NULL;

   hb_retnl( nDocLen );
}

#pragma ENDDUMP
