#include "FiveWin.ch"
#include "mail.ch"
MEMVAR oApp
#ifdef __XHARBOUR__
   #xtranslate HB_CurDrive()  => CurDrive()
   #xtranslate HB_TTOS( <t> ) => TTOS( <t> )
   #xtranslate HB_DateTime()  => DateTime()
#endif

#define DEVICE      oWnd:cargo

#define GO_POS      0
#define GO_UP       1
#define GO_DOWN     2
#define GO_LEFT     1
#define GO_RIGHT    2
#define GO_PAGE    .T.

#define VSCROLL_RANGE  20 * ::nZFactor
#define HSCROLL_RANGE  20 * ::nZFactor

#define MK_MBUTTON            16

static bUserPreview
static bUserBtns, lRebar, nBtnW, nBtnH, nStyle
static lWord, lCalc

//----------------------------------------------------------------------------//

CLASS TPreview

   DATA   oWnd, oBar, oFont, oImageList
   DATA   oDevice, oReport
   DATA   oHand, oCursor
   DATA   oMeta1, oMeta2, oSay, oFactor
   DATA   oPage, oTwoPages, oZoom
   DATA   oMenuZoom, oMenuTwoPages, oMenuUnZoom, oMenuOnePage
   DATA   cResFile
   DATA   aFactor, nPage, nZFactor
   DATA   lTwoPages, lZoom, lExit
   DATA   cPageNum
   DATA   cDestinoMail 

   DATA   hOldRes, hNewRes
   DATA   oLvw, oImageListPages

   CLASSDATA cResFile
   CLASSDATA oWndMain
   CLASSDATA bPrint, bExportToWord, bSaveAsWord, bSaveAsPDF, bEmail

   CLASSDATA lListViewHide INIT .F.

   METHOD New( oDevice, oReport )
   METHOD Activate()
   METHOD BuildButtonBar()
   METHOD BuildListView() // mini pages viewer
   METHOD BuildWindow()
   METHOD BuildMenu()
   METHOD GoPage( nPage )
   METHOD PaintMeta()
   METHOD PrintersMenu()
   METHOD NextPage()
   METHOD PrevPage()
   METHOD TopPage()
   METHOD BottomPage()
   METHOD TwoPages( lMenu )
   METHOD Zoom( lMenu )
   METHOD VScroll( nType, lPage, nSteps )
   METHOD HScroll( nType, lPage, nSteps )
   METHOD SetOrg1( nX, nY, nKeyFlags )
   METHOD SetOrg2( nX, nY, nKeyFlags )
   METHOD CheckKey( nKey, nFlags )
   METHOD CheckMouseWheel( nKeys, nDelta, nXPos, nYPos )
   METHOD SelPrinter( cPrinter )
   METHOD SetFactor( nValue )
   METHOD PrintPage()
   METHOD PrintPrv( oDlg, nOption, nPageIni, nPageEnd )

   ACCESS CanExportToWord  INLINE ::bExportToWord != nil .or. lWord != .f. .or. lCalc != .f.
   ACCESS CanExportToExcel INLINE ( ::oReport != nil .and. ;
                                  ( ::oReport:bInit != nil .or. ::oReport:bToExcel != nil ) )
   METHOD ExportToMSWord()


   METHOD ExportToMSExcel() INLINE If( ::CanExportToExcel, ::oReport:ToExcel(), ;
                            MsgInfo( FWString( "Export to Excel is available only" ) + ;
                            CRLF + ;
                            FWString( "for Reports with ::bInit defined" ), FWString( "Information" ) ) )

   METHOD SaveAsMenu()
   METHOD SaveAs( lPDF )
   METHOD SendEmail()

   METHOD CheckStyle() PROTECTED
   METHOD ResizeListView()

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oDevice, oReport ) CLASS TPreview

   if oDevice == nil
      PRINTER oDevice PREVIEW
         PAGE
         ENDPAGE
         // MsgInfo( oDevice:aMeta[ 1 ] )
      // ENDPRINTER
   endif

   ::oDevice   := oDevice
   ::oReport   := oReport
   ::nPage     := 1
   ::nZFactor  := 1
   ::lTwoPages := .F.
   ::lZoom     := .F.
   ::lExit     := .F.

   ::BuildWindow()

return Self

//----------------------------------------------------------------------------//

METHOD Activate() CLASS TPreview

   local hWndMain

   if ::oWnd == nil
      return nil
   endif

   ACTIVATE WINDOW ::oWnd MAXIMIZED ;
      ON RESIZE    ( ::PaintMeta(), ::ResizeListView() ) ;
      ON UP        ::VScroll( GO_UP )             ;
      ON DOWN      ::VScroll( GO_DOWN )           ;
      ON PAGEUP    ::VScroll( GO_UP, GO_PAGE)     ;
      ON PAGEDOWN  ::VScroll( GO_DOWN, GO_PAGE)   ;
      ON LEFT      ::HScroll( GO_LEFT )           ;
      ON RIGHT     ::HScroll( GO_RIGHT )          ;
      ON PAGELEFT  ::HScroll( GO_LEFT, GO_PAGE )  ;
      ON PAGERIGHT ::HScroll( GO_RIGHT, GO_PAGE ) ;
      VALID        ( ::oWnd:oIcon := nil       ,;
                     ::oFont:End()             ,;
                     ::oCursor:End()           ,;
                     ::oMeta1:End()            ,;
                     ::oMeta2:End()            ,;
                     ::oDevice:End()           ,;
                     ::oHand:End()             ,;
                     If( Empty( ::oImageList ),, ( ::oImageList:End(), ::oImageList := nil ) ),;
                     If( ! Empty( ::oImageListPages ), ::oImageListPages:End(),),;
                     ::oWnd := nil             ,;
                     ::oDevice:oPreview := nil ,;
                     ::lExit := .T. )

     if ::oDevice:lPrvModal
         if ::oWndMain == nil
            StopUntil( { || ::lExit } )
         else
            hWndMain    := WndMain():hWnd
            StopUntil( { || ::lExit .or. !IsWindow( hWndMain ) } )
         endif
     endif

return nil

//----------------------------------------------------------------------------//

METHOD BuildButtonBar() CLASS TPreview

   local oImageList, oReBar, oBar, oHand, uRet, oBtn

   DEFINE CURSOR ::oHand HAND

   if lRebar
      DEFINE IMAGELIST oImageList SIZE 16, 16

      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "top2" ) ),      nRGB( 192, 192, 192 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "previous2" ) ), nRGB( 192, 192, 192 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "next2" ) ),     nRGB( 192, 192, 192 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "bottom2" ) ),   nRGB( 192, 192, 192 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "zoom2" ) ),     nRGB( 255,   0, 255 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "twopages2" ) ), nRGB( 192, 192, 192 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "printer" ) ),   nRGB( 255,   0, 255 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "save" ) ),      nRGB( 255,   0, 255 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "pdf" ) ),       nRGB( 255,   0, 255 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "email" ) ),     nRGB( 255, 255, 255 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "word2" ) ),     nRGB( 255,   0, 255 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "excel" ) ),     nRGB( 255,   0, 255 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "exit2" ) ),     nRGB( 192, 192, 192 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "onepage2" ) ),  nRGB( 192, 192, 192 ) )
      oImageList:AddMasked( TBitmap():Define( ,,, FWBitmap( "onepage2" ) ),  nRGB( 192, 192, 192 ) )
      ::oImageList = oImageList

      oReBar = TReBar():New( ::oWnd )

      DEFINE TOOLBAR oBar OF oReBar SIZE 25, 25 IMAGELIST oImageList

      ::oBar = oBar
      oReBar:InsertBand( oBar )

      oBar:nHeight -= 2

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::TopPage() ;
         TOOLTIP FWString( "First" ) ;
         MESSAGE FWString( "Go to first page" )

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::PrevPage() ;
         TOOLTIP FWString( "Previous" ) ;
         MESSAGE FWString( "Go to previous page" )

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::NextPage() ;
         TOOLTIP FWString( "Next" ) ;
         MESSAGE FWString( "Go to next page" )

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::BottomPage() ;
         TOOLTIP FWString( "Last" ) ;
         MESSAGE FWString( "Go to last page" )

      DEFINE TBSEPARATOR OF oBar

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::Zoom() ;
         TOOLTIP FWString( "Zoom" ) ;
         MESSAGE FWString( "Page zoom" )

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::TwoPages() ;
         TOOLTIP FWString( "Two pages" ) ;
         MESSAGE FWString( "Preview on two pages" )

      DEFINE TBSEPARATOR OF oBar

      DEFINE TBMENU OF oBar ;
         ACTION  If( ValType( ::bPrint ) == 'B', Eval( ::bPrint, Self ), ::PrintPage() ) ;
         TOOLTIP FWString( "Print" ) ;
         MESSAGE FWString( "Print actual page" ) ;
         MENU    ::PrintersMenu()

      DEFINE TBMENU OF oBar ;
         ACTION  ::SaveAs( .f. ) ;
         TOOLTIP FWString( "Save as" ) ;
         MESSAGE FWString( "Save to DOC/PDF" ) ;
         MENU ::SaveAsMenu()

     DEFINE TBBUTTON OF oBar ;
        ACTION ::SaveAs( .t. ) ; //If( ::bSaveAsPDF == nil, FWSavePreviewToPDF( Self ), Eval( ::bSaveAsPDF, Self ) ) ;
        TOOLTIP FWString( "Export to PDF" ) ;
        MESSAGE FWString( "Export to PDF" )

     DEFINE TBBUTTON OF oBar ;
        ACTION ::SendEmail() ;
        TOOLTIP FWString( "Send by email as PDF" ) ;
        MESSAGE FWString( "Send by email as PDF" )

     DEFINE TBBUTTON OF oBar ;
        ACTION ::ExportToMSWord() ;
        TOOLTIP FWString( "Export to MS Word" ) ;
        MESSAGE FWString( "Export to MS Word" )

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::ExportToMSExcel() ;
         TOOLTIP FWString( "Export to Excel" ) ;
         MESSAGE FWString( "Export to Excel" ) ;
         WHEN ::CanExportToExcel

      DEFINE TBSEPARATOR OF oBar

      DEFINE TBBUTTON OF oBar ;
         ACTION  ::oWnd:End() ;
         TOOLTIP FWString( "Exit" ) ;
         MESSAGE FWString( "Exit from preview" )

   else
      if nStyle == 2010
         DEFINE BUTTONBAR oBar OF ::oWnd 2010 ;
            SIZE IfNil( nBtnW, 26 ), IfNil( nBtnH, If( LargeFonts(), 30, 26 ) )
      else
         DEFINE BUTTONBAR oBar OF ::oWnd ;
            SIZE IfNil( nBtnW, 26 ), IfNil( nBtnH, If( LargeFonts(), 30, 26 ) )
      endif
      ::oBar = oBar
      oBar:l2007     := ( nStyle == 2007 )
      oBar:l2010     := ( nStyle == 2010 )
      oBar:l97Look   := ( nStyle == 97 )
      oBar:bRClicked := { || nil }  // to retain the bar on top only

      DEFINE BUTTON oBtn  OF oBar ;
         MESSAGE FWString( "Go to first page" ) ;
         ACTION  ::TopPage() ;
         TOOLTIP FWString( "First" )

      oBtn:hBitmap1 = FWBitmap( "top2" )

      DEFINE BUTTON oBtn OF oBar ;
         MESSAGE FWString( "Go to previous page" ) ;
         ACTION  ::PrevPage() ;
         TOOLTIP FWString( "Previous" )

      oBtn:hBitmap1 = FWBitmap( "previous2" )

      DEFINE BUTTON oBtn OF oBar ;
         MESSAGE FWString( "Go to next page" ) ;
         ACTION  ::NextPage() ;
         TOOLTIP FWString( "Next" )

      oBtn:hBitmap1 = FWBitmap( "Next2" )

      DEFINE BUTTON oBtn OF oBar ;
         MESSAGE FWString( "Go to last page" ) ;
         ACTION  ::BottomPage() ;
         TOOLTIP FWString( "Last" )

      oBtn:hBitmap1 = FWBitmap( "Bottom2" )

      DEFINE BUTTON ::oZoom OF oBar GROUP ;
         MESSAGE FWString( "Page zoom" ) ;
         ACTION  ::Zoom() ;
         TOOLTIP FWString( "Zoom" )

      ::oZoom:hBitmap1 = FWBitmap( "Zoom2" )

      DEFINE BUTTON ::oTwoPages OF oBar ;
         MESSAGE FWString( "Preview on two pages" ) ;
         ACTION  ::TwoPages() ;
         WHEN Len( ::oDevice:aMeta ) > 1 ;
         TOOLTIP FWString( "Two pages" )

      ::oTwoPages:hBitmap1 = FWBitmap( "TwoPages2" )

      DEFINE BUTTON oBtn OF oBar GROUP ;
         MENU    ::PrintersMenu() ;
         MESSAGE FWString( "Print actual page" );
         ACTION  If( ValType( ::bPrint ) == 'B', Eval( ::bPrint, Self ), ::PrintPage() ) ;
         TOOLTIP FWString( "Print" )

      oBtn:hBitmap1 = FWBitmap( "Printer" )

      if ! Empty( bUserBtns )
         uRet = Eval( bUserBtns, Self, oBar )
      endif

      if ! ( ValType( uRet ) == 'L' .and. uRet == .f. )

         DEFINE BUTTON oBtn OF oBar ;
            MENU ::SaveAsMenu() ;
            MESSAGE FWString( "Save to DOC/PDF" ) ;
            ACTION This:ShowPopUp() ;
            TOOLTIP FWString( "Save to DOC/PDF" )

         oBtn:hBitmap1 = FWBitmap( "Save" )

         DEFINE BUTTON oBtn OF oBar ;
            MESSAGE FWString( "Export to PDF" ) ;
            ACTION  ::SaveAs( .t. ) ;
            TOOLTIP FWString( "Export to PDF" )

         oBtn:hBitmap1 = FWBitmap( "PDF" )

         DEFINE BUTTON oBtn OF oBar ;
            MESSAGE FWString( "Send by email as PDF" ) ;
            ACTION  ::SendEmail() ;
            TOOLTIP FWString( "Send by email as PDF" )

         oBtn:hBitmap1 = FWBitmap( "email" )

         DEFINE BUTTON oBtn OF oBar ;
            MESSAGE FWString( "Export to MS Word" ) ;
            ACTION  ::ExportToMSWord() ;
            TOOLTIP FWString( "Export to MS Word" ) ;
            WHEN ::CanExportToWord

         oBtn:hBitmap1 = FWBitmap( "Word2" )

         DEFINE BUTTON oBtn OF oBar ;
            MESSAGE FWString( "Export to Excel" ) ;
            ACTION ::ExportToMSExcel() ;
            TOOLTIP FWString( "Export to Excel" ) ;
            WHEN ::CanExportToExcel

         oBtn:hBitmap1 = FWBitmap( "Excel" )

      endif

      DEFINE BUTTON oBtn OF oBar GROUP ;
         MESSAGE FWString( "Exit from preview" )               ;
         ACTION  ::oWnd:End()                   ;
         TOOLTIP FWString( "Exit" )

      oBtn:hBitmap1 = FWBitmap( "Exit2" )

      AEval( oBar:aControls, { | o | o:oCursor := ::oHand } )

   endif

return nil

//----------------------------------------------------------------------------//

METHOD BuildWindow() CLASS TPreview

   local oIcon, cTitle := FWString( "Printing Preview" )
   local oBar, nCol := 420
   local oThis := Self, nRow := 7

   if Len( ::oDevice:aMeta ) < 1
      return nil
   endif

   DEFAULT ::oWndMain := WndMain()

   if ::oDevice != nil
      cTitle = ::oDevice:cDocument
   endif

   if ::oWndMain != nil
      oIcon = ::oWndMain:oIcon
   else
      DEFINE ICON oIcon RESOURCE "Print"
   ENDIF

   DEFINE FONT ::oFont NAME GetSysFont() SIZE 0, -12

   ::CheckStyle()

   if ! ::oDevice:lPrvModal .and. ::oWndMain != nil .and. ;
      Upper( ::oWndMain:ClassName() ) == "TMDIFRAME"
      DEFINE WINDOW ::oWnd ;
         TITLE cTitle ;
         COLOR CLR_BLACK,CLR_LIGHTGRAY ;
         VSCROLL HSCROLL MDICHILD
   else
      DEFINE WINDOW ::oWnd ;
         TITLE cTitle ;
         COLOR CLR_BLACK,CLR_LIGHTGRAY ;
         VSCROLL HSCROLL MENU ::BuildMenu()
   ENDIF

   ::oWnd:SetIcon( oIcon )
   ::oWnd:SetFont( ::oFont )

   ::oWnd:oVScroll:SetRange( 0, 0 )
   ::oWnd:oHScroll:SetRange( 0, 0 )

   ::cPageNum = FWString( "Page number:" )
   ::BuildButtonBar()

   if lRebar
      DEFINE STATUSBAR OF ::oWnd PROMPT "  " + FWString( "Preview" )
   else
      SET MESSAGE OF ::oWnd TO FWString( "Preview" ) CENTERED ;
         NOINSET CLOCK DATE KEYBOARD
      ::oWnd:oMsgBar:l2007    := ( nStyle == 2007 )
      ::oWnd:oMsgBar:l2010    := ( nStyle == 2010 )
   endif

   // We build the left thumbs listview
   if ! ::lListViewHide
      ::BuildListView()
   endif

   // We build the main metafiles to display the pages

   ::oMeta1 := TMetaFile():New( 0, 0, 0, 0,;
                                ::oDevice:aMeta[ 1 ],;
                                ::oWnd,;
                                CLR_BLACK,;
                                CLR_WHITE,;
                                ::oDevice:nHorzRes(),;
                                ::oDevice:nVertRes() )

   DEFINE CURSOR ::oCursor SEARCH

   ::oMeta1:oCursor := ::oCursor
   ::oMeta1:blDblClick := { | nRow, nCol, nKeyFlags | ;
                            ::SetOrg1( nCol, nRow, nKeyFlags ),;
                            If ( ::lListViewHide, nil, If( ::lZoom, ::oLvw:Hide(), ::oLvw:Show() ) ) }

   ::oMeta1:bKeyDown := { | nKey, nFlags | ::CheckKey( nKey, nFlags ) }
   ::oMeta1:bMouseWheel := { | nKeys, nDelta, nXPos, nYPos | ;
                             ::CheckMouseWheel( nKeys, nDelta, nXPos, nYPos ) }

   ::oMeta2 := TMetaFile():New( 0, 0, 0, 0, "",;
                                ::oWnd, CLR_BLACK, CLR_WHITE, ::oDevice:nHorzRes(),;
                                ::oDevice:nVertRes() )

   ::oMeta2:oCursor = ::oCursor
   ::oMeta2:blDblClick := { | nRow, nCol, nKeyFlags | ;
                            ::SetOrg2( nCol, nRow, nKeyFlags ),;
                            If ( ::lListViewHide, nil, If( ::lZoom, ::oLvw:Hide(), ::oLvw:Show() ) ) }

   ::oMeta2:hide()

   ::SetFactor()

   oBar     := ::oBar

   if .T. // ! lRebar
      nCol  := If( ! Empty( oBar:aControls ), ATail( oBar:aControls ):nRight, Len( oBar:aButtons ) * ( oBar:nBtnWidth + 2 ) ) + 30
      nRow  := Int( oBar:nHeight / 2 ) - 8
   endif

   if nStyle >= 2007
      oBar:bPainted = { || oBar:Say( nRow, nCol, "Factor:",,, ::oFont, .T., .T. ),;
                           oBar:Say( nRow, nCol+100, ::cPageNum + " " + ;
                           LTrim( Str( ::nPage, 4, 0 ) ) + " / " + ;
                           LTrim( Str( Len( ::oDevice:aMeta ) ) ),,, ::oFont, .T., .T. ) }

   endif

   if nStyle < 2007
      @ nRow, nCol SAY ::oSay PROMPT "Factor:" ;
         SIZE 45, 15 PIXEL OF ::oBar FONT ::oFont

      ::oSay:lTransparent = .T.
   endif

   @ nRow - 4, nCol + 40 COMBOBOX ::oFactor VAR ::nZFactor ;
      ITEMS { "1", "2", "3", "4", "5", "6", "7", "8", "9" } ;
      OF ::oBar FONT ::oFont PIXEL SIZE 35,200 ;
      ON CHANGE oThis:SetFactor( oThis:nZFactor )

   if nStyle < 2007
      @ nRow, nCol + 100 SAY ::oPage PROMPT FWString( "Page number:" ) + ;
        LTrim( Str( ::nPage, 4, 0 ) ) + " / " + ;
        LTrim( Str( Len( ::oDevice:aMeta ) ) ) ;
        SIZE 180, 15 PIXEL OF ::oBar FONT ::oFont
      ::oPage:lTransparent = .T.
   endif

   if lRebar .or. nStyle >= 2007
      #define NULL_BRUSH 5
      FixSays( ::oBar:hWnd, GetStockObject( NULL_BRUSH ) )
   endif

   ::oFactor:Set3dLook( .T. )

   ::oWnd:oHScroll:bPos := { | nPos | ::HScroll( GO_POS, .f., nPos ) }
   ::oWnd:oVScroll:bPos := { | nPos | ::VScroll( GO_POS, .f., nPos ) }

return nil

//----------------------------------------------------------------------------//

METHOD BuildListView() CLASS TPreview

   local nSizeH, nSizeV, oBmp, n, aPrompts := {}

   if ::oDevice:nHorzRes() > ::oDevice:nVertRes()
     nSizeH = 100
     nSizeV = 80
   else
     nSizeH = 80
     nSizeV = 100
   endif

   oBmp = TBitmap():Define()
   ::oImageListPages = TImageList():New( nSizeH, nSizeV )

   for n := 1 to Len( ::oDevice:aMeta )
      oBmp:hBitmap := PageBitmap( ::oDevice:aMeta[ n ], nSizeH, nSizeV )
      ::oImageListPages:Add( oBmp )
      oBmp:End()
      Aadd( aPrompts, AllTrim( Str( n ) ) )
   NEXT

   ::oLvw = TListView():New( 33 - If( ::oWnd:oTop:IsKindOf( "TBAR" ), 6, 0 ),;
                             0, aPrompts, { | nPage | ::GoPage( nPage ) }, ::oWnd,;
                             ,, .T.,, nSizeH + 45, ScreenHeight() - ;
                             If( ::oWnd:oBar != nil, ::oWnd:oBar:nHeight() - 2,;
                             ::oWnd:oTop:nHeight() ) - ;
                             If( ::oWnd:oMsgBar != nil, ::oWnd:oMsgBar:nHeight(),;
                             ::oWnd:oBottom:nHeight() ) - 38 )
   ::oLvw:SetImageList( ::oImageListPages )
   ::oLvw:bRClicked = { || If( ::oLvw:nLeft == 0,;
                               ::oLvw:nLeft := ::oWnd:nWidth - ::oLvw:nWidth - 30,;
                               ::oLvw:nLeft := 0 ) }

return nil

//----------------------------------------------------------------------------//

static function PageBitmap( cEMF, nWidth, nHeight )

   local hDC1 := GetDC( GetDesktopWindow() )
   local hDC2 := CreateCompatibleDC( hDC1 )
   local hBmp := CreateCompatibleBitmap( hDC1, nWidth, nHeight )
   local hOldBmp := SelectObject( hDC2, hBmp )
   local hEMF := GetEnhMetaFile( cEmf )

   Rectangle( hDC2, 0, 0, nHeight, nWidth )
   XPlayEnhMetaFile( hDC2, hEMF, 0, 0, nHeight, nWidth )
   CloseEnhMetafile( hEMF )

   SelectObject( hDC2, hOldBmp )
   DeleteDC( hDC2 )
   ReleaseDC( hDC1 )

return hBmp

//----------------------------------------------------------------------------//

METHOD BuildMenu() CLASS TPreview

   local nFor, oMenu, oMItem
   local lThemed := IsAppThemed()

   ::aFactor := Array( 9 )

   MENU oMenu
      oMenu:l2007    := ( nStyle == 2007 )
      oMenu:l2010    := ( nStyle == 2010 )
      MENUITEM FWString( "&File" )
      MENU
         MENUITEM oMItem PROMPT FWString( "&Print" ) ACTION If( ValType( ::bPrint ) == 'B', Eval( ::bPrint, Self ), ::PrintPage() ) ;
            MESSAGE FWString( "Print actual page" )

         oMItem:hBitmap = FWBitmap( "printer" )

         SEPARATOR

         MENUITEM oMItem PROMPT FWString( "&Exit" ) ACTION ::oWnd:End() ;
            MESSAGE FWString( "Exit from preview" )

         oMItem:hBitmap = FWBitmap( "Exit2" )

      ENDMENU

      MENUITEM FWString( "&Page" )
      MENU
         MENUITEM oMItem PROMPT FWString( "&First" ) ACTION ::TopPage() ;
            MESSAGE FWString( "Go to first page" )

         oMItem:hBitmap = FWBitmap( "top2" )

         MENUITEM oMItem PROMPT FWString( "&Previous" ) ACTION ::PrevPage() ;
            MESSAGE FWString( "Go to previous page" )

         oMItem:hBitmap = FWBitmap( "previous2" )

         MENUITEM oMItem PROMPT FWString( "&Next" ) ACTION ::NextPage() ;
            MESSAGE FWString( "Go to next page" )

         oMItem:hBitmap = FWBitmap( "next2" )

         MENUITEM oMItem PROMPT FWString( "&Last" ) ACTION ::BottomPage() ;
            MESSAGE FWString( "Go to last page" )

         oMItem:hBitmap = FWBitmap( "bottom2" )

         SEPARATOR

         MENUITEM oMItem PROMPT ::oMenuZoom PROMPT FWString( "&Zoom" ) ACTION ::Zoom( .T. ) ;
            MESSAGE FWString( "Page zoom" )

         oMItem:hBitmap = FWBitmap( "zoom2" )

         MENUITEM oMItem PROMPT ::oMenuUnZoom PROMPT FWString( "&Normal" ) ACTION ::Zoom( .T. ) ;
            MESSAGE FWString( "Page unzoom" )

         oMItem:hBitmap = FWBitmap( "onepage2" )

         MENUITEM FWString( "&Factor" ) MESSAGE FWString( "Zoom factor" )
         MENU
            for nFor := 1 to Len( ::aFactor )
               MENUITEM ::aFactor[ nFor ]                  ;
                  PROMPT "&" + LTrim( Str( nFor ) )        ;
                  MESSAGE FWString( "Factor" ) + " " + LTrim( Str( nFor ) ) ;
                  ACTION ( ::oFactor:Set( oMenuItem:nHelpId ),;
                           Eval( ::oFactor:bChange ) )

            next
         ENDMENU

         SEPARATOR

         MENUITEM ::oMenuTwoPages PROMPT FWString( "&Two pages" ) ACTION ::TwoPages( .T. ) ;
            MESSAGE FWString( "Preview on two pages" )

         ::oMenuTwoPages:hBitmap = FWBitmap( "TwoPages2" )
         ::oMenuTwoPages:bWhen   = {|| Len( ::oDevice:aMeta ) > 1 }

         MENUITEM ::oMenuOnePage PROMPT FWString( "One &page" ) ACTION ::TwoPages(.T.) ;
            MESSAGE FWString( "Preview on one page" )

         ::oMenuOnePage:hBitmap = FWBitmap( "onepage2" )

      ENDMENU
   ENDMENU

   ::oMenuUnZoom:Disable()
   ::oMenuOnePage:Disable()

return oMenu

//----------------------------------------------------------------------------//

METHOD CheckStyle() CLASS TPreview

   local o

   if nStyle == nil
      nStyle      := 0
      DEFAULT ::oWndMain   := WndMain()

      if ::oWndMain != nil
         if ( o := ::oWndMain:oMenu ) != nil
            nStyle   := Max( nStyle, If( o:l2010, 2010, 0 ) )
         endif

         if nStyle < 2010 .and. ( o := ::oWndMain:oMsgBar ) != nil
            nStyle   := Max( nStyle, If( o:l2010, 2010, If( o:l2007, 2007, 0 ) ) )
         endif

         if nStyle < 2010 .and. ( o := ::oWndMain:oTop ) != nil
            if o:IsKindOf( "TRIBBONBAR" )
               nStyle   := Max( nStyle, If( o:l2010, 2010, 2007 ) )

            elseif o:IsKindOf( "TBAR" )
               nStyle   := Max( nStyle, If( o:l2010, 2010, 2007 ) )
               if Empty( nStyle ) .and. Len( o:aControls ) > 0 .and. o:aControls[ 1 ]:l97look
                  nStyle   := 97
               endif
            endif
         endif
      endif
   endif

   lRebar   := ( IsAppThemed() .and. Empty( nStyle ) .and. bUserBtns == nil .and. nBtnW == nil .and. nBtnH == nil )

return Self

//----------------------------------------------------------------------------//

METHOD GoPage( nPage ) CLASS TPreview

   local aFiles := ::oDevice:aMeta

   if nPage > Len( aFiles ) .OR. nPage < 1
      MsgBeep()
      return .F.
   endif

   ::nPage := nPage

   ::oMeta1:SetFile( aFiles[ ::nPage ] )
   if nStyle < 2007
      ::oPage:SetText( FWString( "Page number:" ) + " " + ;
                       LTrim( Str( ::nPage, 4, 0 ) ) + " / " + ;
                       LTrim( Str( Len( aFiles ) ) ) )
   endif

   ::oBar:Refresh()
   ::oMeta1:Refresh()

   if ::lTwoPages
      if Len( aFiles ) >= ::nPage + 1
         ::oMeta2:SetFile( aFiles[ ::nPage + 1 ] )
      else
         ::oMeta2:SetFile( "" )
      endif
      ::oMeta2:Refresh()
   endif

   ::oMeta1:SetFocus()

return .T.

//----------------------------------------------------------------------------//

METHOD PaintMeta() CLASS TPreview

   local oRect, oRect1, oRect2
   local aFiles := ::oDevice:aMeta  // DEVICE
   local nWidth, nHeight, nMaxWidth, nAspect, nMetaWidth, nGutter

   if ::oWnd != nil
      if IsIconic( ::oWnd:hWnd )
         return nil
      endif
      oRect          := ::oWnd:GetCliRect()
      oRect:nTop     += ( ::oBar:nHeight    + 4 )
      oRect:nBottom  -= ( IfNil( ::oWnd:oMsgBar, ::oWnd:oBottom ):nHeight + 4 + 5 )  // 5 shadow depth
      nMaxWidth      := oRect:nWidth * If( ::lTwoPages, 0.40, 0.95 )
      nGutter        := oRect:nWidth * 0.05

      nAspect        := ::oDevice:nHorzSize() / ::oDevice:nVertSize()

      nMetaWidth     := If( ::lZoom, nMaxWidth, oRect:nHeight * nAspect )
      nHeight        := oRect:nHeight
      if nMetaWidth > nMaxWidth
         nMetaWidth  := nMaxWidth
         nHeight     := nMetaWidth / nAspect
      endif

      if ::lTwoPages

         oRect1  := OClone( oRect )
         WITH OBJECT oRect1
            :nTop          += ( oRect:nHeight - nHeight ) / 2
            :nLeft         := oRect:nLeft + oRect:nWidth / 2 - nMetaWidth - nGutter
            :nWidth        := nMetaWidth
            :nHeight       := nHeight
         END

         oRect2  := OClone( oRect1 )
         WITH OBJECT oRect2
            :nLeft         := oRect:nLeft + oRect:nWidth / 2 + nGutter
            :nWidth        := nMetaWidth
         END

         if ::nPage == Len( aFiles )
            ::oMeta2:SetFile( "" )
         else
            ::oMeta2:SetFile( aFiles[ ::nPage + 1 ] )
         endif

         ::oMeta1:SetCoors( oRect1 )
         ::oMeta2:SetCoors( oRect2 )
         ::oMeta1:Refresh()
         ::oMeta2:Show()

      else
         oRect1  := OClone( oRect )
         WITH OBJECT oRect1
            :nTop          += ( oRect:nHeight - nHeight ) / 2
            :nLeft         += ( oRect:nWidth - nMetaWidth ) / 2
            :nWidth        := nMetaWidth
            :nHeight       := nHeight
         END

         ::oMeta2:Hide()
         ::oMeta1:SetCoors( oRect1 )
         ::oMeta1:Refresh()

      endif

      ::oMeta1:SetFocus()

   endif

return nil

//----------------------------------------------------------------------------//

METHOD NextPage() CLASS TPreview

   local aFiles  := ::oDevice:aMeta  // DEVICE

   if ::nPage >= Len( aFiles )
      MsgBeep()
      return nil
   endif

   ::nPage++

   ::oMeta1:SetFile( aFiles[ ::nPage ] )
   if nStyle < 2007
      ::oPage:SetText( FWString( "Page number:" ) + LTrim( Str( ::nPage, 4, 0 ) ) + ;
                       " / " + LTrim( Str( Len( aFiles ) ) ) )
   endif

   ::oBar:Refresh()
   ::oMeta1:Refresh()

   if ::lTwoPages
      if Len( aFiles ) >= ::nPage + 1
         ::oMeta2:SetFile( aFiles[ ::nPage + 1 ] )
      else
         ::oMeta2:SetFile( "" )
      endif
      ::oMeta2:Refresh()
   endif

   ::oMeta1:SetFocus()

return nil

//----------------------------------------------------------------------------//

METHOD PrevPage() CLASS TPreview

   local aFiles  := ::oDevice:aMeta  // DEVICE

   if ::nPage == 1
      MsgBeep()
      return nil
   endif

   ::nPage--

   ::oMeta1:SetFile( aFiles[ ::nPage ] )

   if nStyle < 2007
      ::oPage:SetText( FWString( "Page number:" ) + LTrim( Str( ::nPage, 4, 0 ) ) + ;
                       " / " + LTrim( Str( Len( aFiles ) ) ) )
   endif
   ::oBar:Refresh()
   ::oMeta1:Refresh()

   if ::lTwoPages
      if Len( aFiles ) >= ::nPage + 1
         ::oMeta2:SetFile( aFiles[ ::nPage + 1 ] )
      else
         ::oMeta2:SetFile( "" )
      endif
      ::oMeta2:Refresh()
   endif

   ::oMeta1:SetFocus()

return nil

//----------------------------------------------------------------------------//

METHOD TopPage() CLASS TPreview

   local aFiles  := ::oDevice:aMeta  // DEVICE

   if ::nPage == 1
      MsgBeep()
      return nil
   endif

   ::nPage = 1

   ::oMeta1:SetFile( aFiles[ ::nPage ] )
   if nStyle < 2007
      ::oPage:SetText( FWString( "Page number:" ) + " " + LTrim( Str( ::nPage, 4, 0 ) ) + ;
                       " / " + LTrim( Str( Len( aFiles ) ) ) )
   endif
   ::oBar:Refresh()
   ::oMeta1:Refresh()

   if ::lTwoPages
      if Len( aFiles ) >= ::nPage + 1
         ::oMeta2:SetFile( aFiles[ ::nPage + 1 ] )
      else
         ::oMeta2:SetFile( "" )
      endif
      ::oMeta2:Refresh()
   endif

   ::oMeta1:SetFocus()

return nil

//----------------------------------------------------------------------------//

METHOD BottomPage() CLASS TPreview

   local aFiles  := ::oDevice:aMeta  // DEVICE

   if ::nPage == Len( aFiles )
      MsgBeep()
      return nil
   endif

   ::nPage = Len( aFiles )

   ::oMeta1:SetFile( aFiles[ ::nPage ] )
   if nStyle < 2007
      ::oPage:SetText( FWString( "Page number:" ) + " " + LTrim( Str( ::nPage, 4, 0 ) ) + ;
                       " / " + LTrim( Str( Len( aFiles ) ) ) )
   endif
   ::oBar:Refresh()
   ::oMeta1:Refresh()

   if ::lTwoPages
      ::oMeta2:SetFile( "" )
      ::oMeta2:Refresh()
   endif

   ::oMeta1:SetFocus()

return nil

//----------------------------------------------------------------------------//

METHOD TwoPages( lMenu ) CLASS TPreview

   DEFAULT lMenu := .F.

   ::lTwoPages := ! ::lTwoPages

   if ::lTwoPages

      if Len( ::oDevice:aMeta) == 1 // solo hay una pagina   // DEVICE
         ::lTwoPages := ! ::lTwoPages
         MsgBeep()
         return nil
      endif

      if ::oDevice:nHorzSize() >= ;        // Apaisado  // DEVICE
         ::oDevice:nVertSize()  // DEVICE
         ::lTwoPages := ! ::lTwoPages
         MsgBeep()
         return nil
      endif

      if ::lZoom
         ::Zoom( .T. )
      endif

      if ! lRebar
         ::oTwoPages:FreeBitmaps()
         ::oTwoPages:hBitmap1 = FWBitmap( "OnePage2" )
         ::oTwoPages:cMsg = FWString( "Preview on one page" )
         ::oTwoPages:cTooltip = StrTran( FWString( "One &page" ), '&', '' )
         ::oTwoPages:Refresh()
      else
         ::oBar:ChangeBitmap( 6, 10+2 )
         ::oBar:SetTooltip( 6, StrTran( FWString( "One &page" ), '&', '' ) )
         ::oBar:SetMessage( 6, FWString( "Preview on one page" ) )
      endif

      if ::oWnd:oMenu != nil
         ::oMenuTwoPages:Disable()
         ::oMenuOnePage:Enable()
      endif

      if ! ::lListViewHide
         ::oLvw:Hide()
      endif
   else

      if ! lRebar
         ::oTwoPages:FreeBitmaps()
         ::oTwoPages:hBitmap1 = FWBitmap( "twopages2" )
         ::oTwoPages:cMsg = FWString( "Preview on two pages" )
         ::oTwoPages:cTooltip = FWString( "Two pages" )
         ::oTwoPages:Refresh()
      else
         ::oBar:ChangeBitmap( 6, 6 )
         ::oBar:SetTooltip( 6, FWString( "&Two pages" ) )
         ::oBar:SetMessage( 6, FWString( "Preview on two pages" ) )
      endif

      if ::oWnd:oMenu != nil
         ::oMenuTwoPages:Enable()
         ::oMenuOnePage:Disable()
      endif

      if ! ::lListViewHide
         ::oLvw:Show()
      endif

   endif

   if lMenu .and. ! IsAppThemed()
      ::oTwoPages:Refresh()
   endif

   ::oWnd:Refresh()
   ::PaintMeta()

return nil

//----------------------------------------------------------------------------//

METHOD Zoom( lMenu ) CLASS TPreview

   DEFAULT lMenu := .F.

   ::lZoom := ! ::lZoom

   if ::oLvw != nil
      if IsWindowVisible( ::oLvw:hWnd )
         ::oLvw:Hide()
      else
         ::oLvw:Show()
      endif
   endif

   if ::lZoom

      if ::lTwoPages
         ::TwoPages( .T. )
      endif

      if ! lRebar
         ::oZoom:FreeBitmaps()
         ::oZoom:hBitmap1 = FWBitmap( "onepage2" )    //"Unzoom2" )
         ::oZoom:cMsg := FWString( "Page unzoom" )
         ::oZoom:cTooltip := StrTran( FWString( "&Normal" ), "&", "" )
         ::oZoom:Refresh()
      else
         ::oBar:ChangeBitmap( 5, 9 + 5 )
         ::oBar:SetTooltip( 5, StrTran( FWString( "&Normal" ), "&", "" ) )
         ::oBar:SetMessage( 5, FWString( "Page unzoom" ) )
      endif

      if ::oWnd:oMenu != nil
         ::oMenuZoom:Disable()
         ::oMenuUnZoom:Enable()
      endif

      ::oWnd:oVScroll:SetRange( 1, VSCROLL_RANGE )

      if ::nZFactor > 1
         ::oWnd:oHScroll:SetRange( 1, HSCROLL_RANGE )
      endif

      ::oMeta1:ZoomIn()

   else

      if ! lRebar
         ::oZoom:FreeBitmaps()
         ::oZoom:hBitmap1 = FWBitmap( "Zoom2" )
         ::oZoom:cMsg = FWString( "Page zoom" )
         ::oZoom:cTooltip := FWString( "Zoom" )
         ::oZoom:Refresh()
      else
         ::oBar:ChangeBitmap( 5, 5 )
         ::oBar:SetTooltip( 5, FWString( "Zoom" ) )
         ::oBar:SetMessage( 5, FWString( "Page zoom" ) )
      endif

      if ::oWnd:oMenu != nil
         ::oMenuZoom:Enable()
         ::oMenuUnZoom:Disable()
      endif

      ::oWnd:oVScroll:SetRange( 0, 0 )
      ::oWnd:oHScroll:SetRange( 0, 0 )

      ::oMeta1:ZoomOut()
      ::nZFactor = 1
      if ::oWnd:oMenu != nil
         AEval( ::aFactor, { | val, elem | val:SetCheck( ( elem == 1 ) ) } )
      endif
      ::oFactor:Set( 1 )

   endif

   if lMenu .and. ! IsAppThemed()
      ::oZoom:Refresh()
   endif

   ::oWnd:Refresh()  // Fix for clearing shadows when unzoomed .. fwh 11.5
   ::PaintMeta()

return nil

//----------------------------------------------------------------------------//

METHOD VScroll( nType, lPage, nSteps ) CLASS TPreview

   local nYfactor, nYorig, nStep

   DEFAULT lPage := .F.

   if nType == GO_UP
      if ::oWnd:oVScroll:GetPos() <= ::oWnd:oVScroll:nMin
         return nil
      endif
   else
      if ::oWnd:oVScroll:GetPos() > ::oWnd:oVScroll:nMax
         return nil
      endif
   endif

   nYfactor := Int( ::oDevice:nVertRes() / ::oWnd:oVScroll:nMax )  // DEVICE

   if nSteps != nil
      nStep := nSteps
   elseif lPage
      nStep := ::oWnd:oVScroll:nMax / 10
   else
      nStep := 1
   endif

   if nType == GO_UP
      nStep := -nStep
   elseif nType == GO_POS
      ::oWnd:oVscroll:SetPos( nSteps )
      nStep := 0
   endif

   nYorig := nYfactor * ( ::oWnd:oVScroll:GetPos() + nStep - 1 )

   if nYorig > ::oDevice:nVertRes()    // DEVICE
      nYorig := ::oDevice:nVertRes()   // DEVICE
   endif

   if nYorig < 0
      nYorig := 0
   endif

   ::oMeta1:SetOrg( nil, nYorig / ::oDevice:nVertRes() * 10 )  // DEVICE

   ::oMeta1:Refresh()

return nil

//----------------------------------------------------------------------------//

METHOD HScroll( nType, lPage, nSteps ) CLASS TPreview

   local nXfactor, nXorig, nStep

   DEFAULT lPage := .F.

   if nType == GO_UP
      if ::oWnd:oHScroll:GetPos() <= ::oWnd:oHScroll:nMin
         return nil
      endif
   else
      if ::oWnd:oHScroll:GetPos() > ::oWnd:oHScroll:nMax
         return nil
      endif
   endif

   nXfactor := Int( ::oDevice:nHorzRes() / ::oWnd:oHScroll:nMax )  // DEVICE

   if nSteps != nil
      nStep := nSteps
   elseif lPage
      nStep := ::oWnd:oHScroll:nMax/10
   else
      nStep := 1
   endif

   if nType == GO_LEFT
      nStep := -nStep
   elseif nType == GO_POS
      ::oWnd:oHscroll:SetPos( nSteps )
      nStep := 0
   endif

   nXorig := nXfactor * ( ::oWnd:oHScroll:GetPos() + nStep - 1 )

   if nXorig > ::oDevice:nHorzRes()     // DEVICE
      nXorig := ::oDevice:nHorzRes()    // DEVICE
   endif

   if nXorig < 0
      nXorig := 0
   endif

   ::oMeta1:SetOrg( nXorig / ::oDevice:nHorzRes() * 10, nil )  // DEVICE

   ::oMeta1:Refresh()

return nil

//----------------------------------------------------------------------------//

METHOD SetOrg1( nX, nY, nKeyFlags ) CLASS TPreview

   local oCoors
   local nXStep, nYStep, nXFactor, nYFactor,;
         nWidth, nHeight, nXOrg

   if ::lZoom
      ::Zoom( .T. )
      return nil
   endif

   oCoors   := ::oMeta1:GetRect()
   nWidth   := oCoors:nRight - oCoors:nLeft + 1
   nHeight  := oCoors:nBottom - oCoors:nTop + 1

   if .f.
      nXStep   := Max( Int( nX / nWidth * HSCROLL_RANGE ) - 9, 0 )
      nXFactor := Int( ::oDevice:nHorzRes() / HSCROLL_RANGE )  // DEVICE
   endif

   if .f.
      nYStep   := Max( Int( nY / nHeight * VSCROLL_RANGE ) - 9, 0 )
      nYFactor := Int( ::oDevice:nVertRes() / VSCROLL_RANGE )  // DEVICE
   endif

   ::Zoom( .T. )

   if ! Empty( nXStep )
      ::HScroll( 2,, nxStep )
      ::oWnd:oHScroll:SetPos( nxStep )
   endif

   if ! Empty( nYStep )
      ::VScroll( 2,, nyStep )
      ::oWnd:oVScroll:SetPos( nyStep )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD SetOrg2( nX, nY, nKeyFlags ) CLASS TPreview

   local oCoors
   local aFiles
   local nXStep, nYStep, nXFactor, nYFactor,;
         nWidth, nHeight, nXOrg

   if ::oMeta2:cCaption == ""
      return nil
   endif

   if ::lZoom
      ::Zoom( .T. )
      return nil
   endif

   oCoors := ::oMeta2:GetRect()
   nWidth   := oCoors:nRight - oCoors:nLeft + 1
   nHeight  := oCoors:nBottom - oCoors:nTop + 1

   if .f.
      nXStep   := Max( Int( nX / nWidth * HSCROLL_RANGE ) - 9, 0 )
      nXFactor := Int( ::oDevice:nHorzRes() / HSCROLL_RANGE )
   endif

   if .f.
      nYStep   := Max( Int( nY / nHeight * VSCROLL_RANGE ) - 9, 0 )
      nYFactor := Int( ::oDevice:nVertRes() / VSCROLL_RANGE )  // DEVICE
   endif

   ::oMeta1:SetFile( ::oMeta2:cCaption )

   aFiles := ::oDevice:aMeta  // DEVICE

   if ::nPage = Len( aFiles )
      ::oMeta2:SetFile( "" )
   else
      ::oMeta2:SetFile( aFiles[ ++::nPage ] )
   endif

   if nStyle < 2007
      ::oPage:Refresh()
   endif
   ::oBar:Refresh()

   ::Zoom( .T. )

   if ! Empty( nXStep )
      ::HScroll( 2,, nxStep )
      ::oWnd:oHScroll:SetPos( nxStep )
   endif

   if ! Empty( nYStep )
      ::VScroll( 2,, nyStep )
      ::oWnd:oVScroll:SetPos( nyStep )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD CheckKey( nKey, nFlags ) CLASS TPreview

   if ! ::lZoom
      do case
         case nKey == VK_HOME
              ::TopPage()

         case nKey == VK_END
              ::BottomPage()

         case nKey == VK_PRIOR
              ::PrevPage()

         case nKey == VK_NEXT
              ::NextPage()

      endcase
   else
      do case
         case nKey == VK_UP
              ::oWnd:oVScroll:GoUp()

         case nKey == VK_PRIOR
              ::oWnd:oVScroll:PageUp()

         case nKey == VK_DOWN
              ::oWnd:oVScroll:GoDown()

         case nKey == VK_NEXT
              ::oWnd:oVScroll:PageDown()

         case nKey == VK_LEFT
              ::oWnd:oHScroll:GoUp()

         case nKey == VK_RIGHT
              if ::oWnd:oHScroll != nil .and. ::oWnd:oHScroll:nMax > 0
                 ::oWnd:oHScroll:GoDown()
              endif

         case nKey == VK_HOME
              ::oWnd:oVScroll:GoTop()
              ::oWnd:oHScroll:GoTop()
              ::oMeta1:SetOrg( 0, 0 )
              ::oMeta1:Refresh()

         case nKey == VK_END
              ::oWnd:oVScroll:GoBottom()
              ::oWnd:oHScroll:GoBottom()
              ::oMeta1:SetOrg( .8 * ::oDevice:nHorzRes(), .8 * ::oDevice:nVertRes() )  // DEVICE
              ::oMeta1:Refresh()
      endcase
   endif

return nil

//----------------------------------------------------------------------------//

METHOD CheckMouseWheel( nKeys, nDelta, nXPos, nYPos ) CLASS TPreview

   if ! ::lZoom
      if lAnd( nKeys, MK_MBUTTON )
         if nDelta > 0
            ::TopPage()
         else
            ::BottomPage()
         endif
      else
         if nDelta > 0
            ::PrevPage()
         else
            ::NextPage()
         endif
      endif
   else
      if lAnd( nKeys, MK_MBUTTON )
         if nDelta > 0
            if ::oWnd:oVScroll:GetPos() > ::oWnd:oVScroll:nMin
               ::oWnd:oVScroll:PageUp()
            endif
         else
            if ::oWnd:oVScroll:GetPos() < ::oWnd:oVScroll:nMax
               ::oWnd:oVScroll:PageDown()
            endif
         endif
      else
         if nDelta > 0
            if ::oWnd:oVScroll:GetPos() > ::oWnd:oVScroll:nMin
               ::oWnd:oVScroll:GoUp()
            endif
         else
            if ::oWnd:oVScroll:GetPos() < ::oWnd:oVScroll:nMax
               ::oWnd:oVScroll:GoDown()
            endif
         endif
      endif
   endif

return nil

//----------------------------------------------------------------------------//

METHOD SelPrinter( cPrinter ) CLASS TPreview

   local cOldPrinter := GetProfString( "windows", "device" , "" )

   WriteProfString( "windows", "device", cPrinter )
   SysRefresh()
   PrinterInit()

   DeleteDC( ::oDevice:hDC )

   ::oDevice:hDC    = GetPrintDefault( GetActiveWindow() )
   ::oDevice:cModel = cPrinter

   SysRefresh()
   WriteProfString( "windows", "device", cOldPrinter )

RETURN nil

//----------------------------------------------------------------------------//

METHOD SetFactor( nValue ) CLASS TPreview

   local lInit := ( PCount() == 0 )  // 2014-07-01: Prevuew on MDIChild is now OK

   DEFAULT nValue := ::nZFactor

   if ::oWnd:oMenu != nil
      if lInit
         AEval( ::aFactor, { | v, e | v:nHelpId := e } )
      endif
      AEval( ::aFactor, { | val, elem | val:SetCheck( elem == nValue ) } )
   endif

/*
   if nValue == nil .and. ::oWnd:oMenu != nil
      AEval( ::aFactor, { | v, e | v:nHelpId := e } )
      nValue := ::nZFactor
      lInit  := .T.
   endif

   if ::oWnd:oMenu != nil
      AEval( ::aFactor, { | val, elem | val:SetCheck( elem == nValue ) } )
   endif
*/

   ::oMeta1:SetZoomFactor( ::nZFactor, ::nZFactor * 2 )

   if ! lInit .and. ! ::lZoom
      ::Zoom( .T. )
   endif

   if ::lZoom
      ::oWnd:oVScroll:SetRange( 1, VSCROLL_RANGE )
      if ::nZFactor > 1
         ::oWnd:oHScroll:SetRange( 1, HSCROLL_RANGE )
      else
         ::oWnd:oHScroll:SetRange( 0, 0 )
      endif
   endif

   ::oMeta1:SetFocus()

return nil

//----------------------------------------------------------------------------//

METHOD PrintersMenu() CLASS TPreview

   local oPop, aPrinters := aGetPrinters()

   MENU oPop POPUP
      oPop:l2007 = ( nStyle == 2007 )
      oPop:l2010 = ( nStyle == 2010 )

      AEval( aPrinters, { | cPrinter | MenuAddItem( cPrinter,,;
             cPrinter $ ::oDevice:cModel,,;
             { | oMenuItem | ::SelPrinter( oMenuItem:cPrompt ),;
             oMenuItem:oMenu:UnCheckAll(), oMenuItem:SetCheck( .T. ) } ) } )
   ENDMENU

return oPop

//----------------------------------------------------------------------------//

METHOD PrintPage() CLASS TPreview

   local hMeta   := ::oMeta1:hMeta
   local oDlg, oRad, oPageIni, oPageEnd
   local nOption := 1, nFirst := 1, nLast := Len( ::oDevice:aMeta )  // DEVICE
   local oThis   := Self
   local lCancel := .t.

   if nLast != 1

      DEFINE DIALOG oDlg SIZE 400, 183 TITLE FWString( "Printing" )
      oDlg:lTruePixel := .f.

      @ 8, 8 GROUP PROMPT FWString( "Printing range" ) SIZE 135, 72 PIXEL OF oDlg

      @ 18, 18 RADIO oRad VAR nOption ;
        ITEMS FWString( "All" ), FWString( "Current page" ), FWString( "Pages" ) ;
        ON CHANGE If( nOption == 3,;
                  ( oPageIni:Enable(), oPageEnd:Enable() ),;
                  ( oPageIni:Disable(), oPageEnd:Disable() ) ) PIXEL

      @ 61, 30 SAY FWString( "From" ) OF oDlg PIXEL

      @ 60, 53 GET oPageIni ;
        VAR nFirst PICTURE "@K 99999" ;
        VALID If( nFirst < 1 .or. nFirst > nLast, ( MsgBeep(), .F. ), .T. ) ;
        OF oDlg SIZE 22, 11 PIXEL

      @ 61, 80 SAY FWString( "To" ) OF oDlg PIXEL

      @ 60, 103 GET oPageEnd ;
        VAR nLast PICTURE "@K 99999" ;
        VALID If( nLast < nFirst .or. nLast > Len( ::oDevice:aMeta ),; // DEVICE
               ( MsgBeep(),.F. ), .T.) OF oDlg PIXEL

      @ 10, 152 BUTTON FWString( "&Ok" ) OF oDlg SIZE 42, 14 ;
        ACTION ( lCancel := .f., oDlg:End() ) PIXEL

      @ 28, 152 BUTTON FWString( "&Cancel" ) OF oDlg SIZE 42, 14 ;
        ACTION oDlg:End() PIXEL

      ACTIVATE DIALOG oDlg CENTERED ;
        ON INIT ( oPageIni:Disable(), oPageEnd:Disable(), .T. )

   else
      lCancel := .f.
   endif

   if ! lCancel
      MsgRun( ::oDevice:cDocument, "Printing Report",;
              { || ::PrintPrv( nil, nOption, nFirst, nLast ) } )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD PrintPrv( oDlg, nOption, nPageIni, nPageEnd ) CLASS TPreview

   local oDevice := ::oDevice   // DEVICE
   local aFiles  := oDevice:aMeta
   local hMeta   := ::oMeta1:hMeta
   local nFor

   CursorWait()

   StartDoc( oDevice:hDC, oDevice:cDocument )

   do case

      case nOption == 1                           // All

          for nFor := 1 to Len( aFiles )
              StartPage( oDevice:hDC )
              hMeta := GetEnhMetaFile( aFiles[ nFor ] )
              PlayEnhMetaFile( oDevice:hDC, hMeta,, .t. )
              DeleteEnhMetafile( hMeta )
              EndPage( oDevice:hDC )
          next

     case nOption == 2                           // Current page

          StartPage( oDevice:hDC )
          hMeta := ::oMeta1:hMeta
          PlayEnhMetaFile( oDevice:hDC, hMeta,, .t. )
          EndPage( oDevice:hDC )

     case nOption == 3                           // Range

          for nFor := nPageIni to nPageEnd
               StartPage( oDevice:hDC )
               hMeta := GetEnhMetaFile( aFiles[ nFor ] )
               PlayEnhMetaFile( oDevice:hDC, hMeta,, .t. )
               DeleteEnhMetafile( hMeta )
               EndPage( oDevice:hDC )
          next

     endcase

     EndDoc( oDevice:hDC )

     CursorArrow()

     if oDlg != nil
        oDlg:End()
     endif

return nil

//----------------------------------------------------------------------------//

METHOD ExportToMSWord() CLASS TPreview

   local oDoc

   if ValType( ::bExportToWord ) == 'B'
      return Eval( ::bExportToWord, Self )
   endif

   oDoc = ConvertToWordDoc( Self )

   if oDoc != nil
      oDoc:Application:Visible   := .t.
   endif

return Self

//----------------------------------------------------------------------------//

METHOD SaveAsMenu() CLASS TPreview

   local oPop, oMItem

   MENU oPop POPUP
      oPop:l2007 = ( nStyle == 2007 )
      oPop:l2010 = ( nStyle == 2010 )

      MENUITEM oMItem PROMPT FWString( "DOC Format" ) ;
         ACTION ::SaveAs( .f. )

      oMItem:hBitmap = FWBitmap( "Word2" )

      MENUITEM oMItem PROMPT FWString( "PDF Format" ) ;
         ACTION ::SaveAs( .t. )

      oMItem:hBitmap = FWBitmap( "pdf" )

   ENDMENU

return oPop

//----------------------------------------------------------------------------//

METHOD ResizeListView() CLASS TPreview

   if ::oWnd != nil .and. ::oLvw != nil
      ::oLvw:nHeight = ::oWnd:GetCliRect():nHeight - 2 - ;
                       If( ::oWnd:oBar != nil, ::oWnd:oBar:nHeight() - 2,;
                           ::oWnd:oTop:nHeight() ) - ;
                       If( ::oWnd:oMsgBar != nil, ::oWnd:oMsgBar:nHeight(),;
                           ::oWnd:oBottom:nHeight() )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD SaveAs( lPDF, cFile, lView ) CLASS TPreview

   static lWordPDF   := .t.

   local oWord, nVer, oDoc
   local cExt, cMsg

   if lPDF
      if ValType( ::bSaveAsPDF ) == 'B'
         return Eval( ::bSaveAsPDF, Self, cFile, lView )
      elseif ! lWordPDF // tested earlier and found Word with PDF plugin not availble
         return FWSavePreviewToPDF( Self, cFile, lView )
      endif
   else
      if ValType( ::bSaveAsWord ) == 'B'
         return Eval( ::bSaveAsWord, Self, cFile, lView )
      endif
   endif

   oWord       := WinWordObj()
   if oWord == nil
      lWordPDF    := .f.
      if lPDF
        return FWSavePreviewToPDF( Self, cFile, lView )
      ELSE
        return ToWordDocViaWriter( Self, , "W" )
      Endif
   endif
   nVer        := Val( oWord:Version )

   if lPDF
      if nVer >= 12.0 .and. WordHasPDFPlugIn()
         cExt  := "*.pdf"
      else
         lWordPDF    := .f.
         return FWSavePreviewToPDF( Self, cFile, lView )
      endif
   else
      cExt = If( nVer < 12.0, "*.doc", "*.docx; *.doc" )
   endif
   cMsg    = If( lPDF, "PDF", "Doc" ) + " " + ;
             FWString( "File to Save" ) + "( " + cExt + ") |" + cExt + "|"

   if Empty( cFile ) .and. Empty( cFile := cGetFile(  If( ::oDevice:IsKindOf( "TPreview" ) ,;
                               ::oDevice:cName, ::oDevice:cDocument ) + ".pdf", FWString( "File to Save" ), 1,;
                       hb_CurDrive() + ":\" + CurDir() + "\documentos\",hb_CurDrive() + ":\" + CurDir() + "\documentos\" ;
                       , .t. ) )
      return nil
   endif

   if !( Lower( cFileExt( cFile ) ) $ cExt )
      cFile = cFilePath( cFile ) + cFileNoExt( cFile ) + ;
              If( lPDF, ".pdf", If( nVer < 12.0, ".doc", ".docx" ) )
   endif

   DEFAULT lView := MsgYesNo( FWString( "View" ) + " " + cFile + "?", FWString( "Please select" ) )
   oDoc  = ConvertToWordDoc( Self )

   if oDoc != nil
      TRY
         oDoc:ExportAsFixedFormat( cFile, 17, lView )
      CATCH
         lWordPDF    := .f.
//         MsgInfo( FWString( "PDF Plugin Error" ), FWString( "Information" ) )
      END
      if lPDF
         oDoc:Close( .f. )
         if ! lWordPDF
            // word failed to save as PDF due to PDF Plugin Error
            return FWSavePreviewToPDF( Self, cFile, lView )
         endif
      else
         if nVer >= 12.0
            oDoc:SaveAs( cFile, If( Lower( cFileExt( cFile ) ) == 'doc', 0, 16 ) )
         else
            oDoc:SaveAs( cFile )
         endif
         if lView
            oDoc:Application:Visible := .t.
         else
            oDoc:Close( .f. )
         endif
      endif
   endif

return cFile

//----------------------------------------------------------------------------//

METHOD SendEmail() CLASS TPreview

   local cName, cFile, cReplyTo := oApp:oServer:Query("SELECT email FROM ge_"+oApp:cId+"parametros"):email,;
         oDlg, aCor, oGet:=ARRAY(2), oBot := ARRAY(2), lRta := .f., cDestino

   cDestino := IF(EMPTY(oApp:cDestinoMail), cReplyTo,oApp:cDestinoMail)

   cName := If( ::oReport != nil, ::oReport:cName, ::oDevice:cDocument )
   cFile := cFilePath( ::oDevice:aMeta[ 1 ] ) + StrTran( cName, '.', '' ) + ;
            Left( HB_TToS( HB_DateTime() ), 14 ) + ".pdf"
   cName := ALLTRIM(oApp:nomb_emp)+" - "+cName + SPACE(40 - len(cName))         
   
   CursorWait()
   cFile := ::SaveAs( .t., cFile, .f. )
   CursorArrow()

   if ! File( cFile )
      MsgInfo( FWString( "PDF not saved to send Email" ), FWString( "Information" ) )
      ELSE 
      DEFINE DIALOG oDlg TITLE "Escriba mail destino" FROM 05,15 TO 13,60;
      OF ::oWnd ICON oApp:oIco 
      acor := AcepCanc(oDlg)
      @ 07, 05 SAY "Escriba mail:"   OF oDlg PIXEL SIZE 40,20 RIGHT            
      @ 22, 05 SAY "Asunto:"         OF oDlg PIXEL SIZE 40,20 RIGHT            
      @ 05, 46 GET oGet[1] VAR cDestino OF oDlg PIXEL PICTURE "@S30"      
      @ 20, 46 GET oGet[2] VAR cName    OF oDlg PIXEL PICTURE "@S30"      
         
      @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Enviar" OF oDlg SIZE 30,10 ;
              ACTION ((lRta := .t.), oDlg:End() ) PIXEL
      @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
              ACTION ((lRta := .f.), oDlg:End() ) PIXEL CANCEL
      ACTIVATE DIALOG oDlg CENTER
      IF !lRta
         RETURN nil 
      ENDIF  
      IF Empty(cDestino) .or. Empty(cName)
         MsgStop("Debe poner un destinatario y un asunto")
         RETURN nil
      ENDIF   
      EnviarPorMail(cDestino,cName,cReplyTo,cFile)
   endif

   ::oMeta1:SetFocus()

return nil

//----------------------------------------------------------------------------//

function RPreview( oDevice, oReport )

   local oPreview

   if bUserPreview == nil
      oPreview := TPreview():New( oDevice, oReport )
      oDevice:oPreview := oPreview
      oPreview:Activate()
   else
      Eval( bUserPreview, oDevice, oReport )
   endif

return nil

//----------------------------------------------------------------------------//

function ConvertToWordDoc( oPreview )

   local aFiles   := oPreview:oDevice:aMeta
   local oWord, oDoc, cEMF

   if Len( aFiles ) > 0
      if ( oWord := WinWordObj() ) == nil
         lWord    := .f.
         MsgAlert( FWString( "MS Word not installed" ), FWString( "Alert" ) )
         oDoc = ToWordDocViaWriter( oPreview, aFiles, "W" )
      else
         lWord    := .t.
         oDoc = oWord:Documents:Add()
         if oDoc == nil
            MsgAlert( FWString( "Failed to Create Word Document" ), FWString( "Alert" ) )
         else
            oDoc:PageSetup:Orientation := If( oPreview:oDevice:GetOrientation() == 1, 0, 1 )
            WITH OBJECT oDoc:PageSetup
               :LeftMargin    := 0
               :TopMargin     := 0
               :RightMargin   := 0
               :BottomMargin  := 0
            END
            for each cEMF in aFiles
               oWord:Selection:InlineShapes:AddPicture( cEMF, .f., .t. )
            next
            // oDoc:Application:Visible   := .t.
         endif
      endif
   else
      MsgAlert( FWString( "There is no output for export" ), FWString( "Alert" ) )
   endif

return oDoc

//----------------------------------------------------------------------------//

Function ToWordDocViaWriter( oPreview, aFiles, cFileType )

    local oWriter, oDesktop, oDoc, oCusor, oText, oGraphic, cEMF, cURL, i, aProp
    local oStyle, nPageWidth, nPageHeight, aPdfFilters
    local cExt, cMsg, cFile, oSize, oCursor

    DEFAULT cFileType := "W"  // ByDefault Word File
    DEFAULT aFiles := oPreview:oDevice:aMeta

    if Len( aFiles ) == 0
        MsgAlert( FWString( "There is no output for export" ), FWString( "Alert" ) )
        Return nil
    Endif

    if ( oWriter := SunCalcObj() ) == nil
        lCalc  := .f.
        MsgAlert( FWString( "No .Doc file manipulation software installed" ), FWString( "Alert" ) )
        Return NIL
    Endif
    lCalc    := .t.
    oDesktop := oWriter:CreateInstance( "com.sun.star.frame.Desktop" )

    // Create OpenOffice Word Instance with the Window Hidden Property
    aProp = {}
    AAdd( aProp, GetPropertyValue( oWriter, "Hidden", .T. ) )
    oDoc = oDesktop:LoadComponentFromURL( "private:factory/swriter", "_blank", 0, aProp )
    oDoc:Refresh()

    // Set Page Orientation Properties ie Portrait/Landscape
    aProp = {}
    AAdd( aProp, GetPropertyValue( oWriter, "PaperOrientation",;
          If( oPreview:oDevice:GetOrientation() == 1, 0, 1 ) )  ) // 0-> Portrait, 1-> Landscape
    oDoc:Printer:= aProp

    oStyle = oDoc:StyleFamilies:getByName( "PageStyles" ):getByName( "Standard" )

    // Set Page Margins
    oStyle:LeftMargin   = 0
    oStyle:TopMargin    = 0
    oStyle:RightMargin  = 0
    oStyle:BottomMargin = 0

    // Find out the Page's Size ie Height and width. Later this size is used to set the EMF image size while inserting on the page
    nPageWidth  = oStyle:Size:Width - oStyle:LeftMargin - oStyle:RightMargin
    nPageHeight = oStyle:Size:Height - oStyle:TopMargin - oStyle:BottomMargin

    // Create a Size Structure. This size structure is later used to set the image size
    oSize:= oWriter:Bridge_GetStruct( "com.sun.star.awt.Size" )
    oSize:Width:=nPageWidth
    oSize:Height = nPageHeight

    i = 1

    for each cEMF in aFiles

        cURL = ConvertToOoURL( cEMF )

        oText = oDoc:GetText()
        oCursor = oText:CreateTextCursor()
        oCursor:GotoEnd( .F. )

        if i > 1  // Applicable only for page nos > 1
            oText:InsertControlCharacter( oCursor, 0, .F. )  // 0->New Paragraph, 1->New line in a paragraph, 5->This control character appends a new paragraph.
        endif

        oGraphic = oDoc:CreateInstance( "com.sun.star.text.GraphicObject" )
        oGraphic:SetPropertyValue( "GraphicURL", cURL )
        oGraphic:SetPropertyValue( "AnchorType", 1 )  // com.sun.star.text.TextContentAnchorType.AS_CHARACTER
        oGraphic:SetSize( oSize )

        oText:InsertTextContent( oCursor:End(), oGraphic, .F.)
        i++
    next

    // Convert the image links and then Embedd the images onto the document
    OoEmbeddGraphics( oWriter, oDoc )

    cExt = If( cFileType == "W", "*.doc", "*.pdf" )
    cMsg = If( cFileType == "W", "Doc", "PDF" ) + " " + ;
               FWString( "File to Save" ) + "( " + cExt + ") |" + cExt + "|"

    if Empty( cFile := cGetFile( cMsg, "File to Save", 1, CurDir(), , .T. ) )
        oDoc:Close( 1 )  // To Close OpenOffice Writer
        oDesktop:terminate()  // To close the OpenOffice QuickOpen Window
        return nil
    endif

    if ! ( Lower( cFileExt( cFile ) ) $ cExt )
        cFile = cFilePath( cFile ) + cFileNoExt( cFile ) + ;
                If( cFileType == "W", ".doc", ".pdf" )
    endif

    // Convert the FileName and Path to OpenOffice Standard URL
    cURL = ConvertToOoURL( cFile )


    // The Word or PDF file will be saved in the Temp Folder
    * cURL = ConvertToOoURL( Getenv( "TMP" ) + "\" )
    * cURL = cURL + cTempFile()

    if cFileType == "W"  // Word
       * cURL += "Doc"

        // Save the Writer File as Word 97/2000/XP .Doc file. This is the most compatible format
        aProp = {}
        AAdd( aProp, GetPropertyValue( oWriter, "FilterName", "MS Word 97" ) )
        oDoc:StoreToURL( cURL, aProp )

    Else  // PDF
        * cURL += "Pdf"

        // Save the Writer File as PDF file
        aPdfFilters = {}
        AAdd( aPdfFilters, GetPropertyValue( oWriter, "UseLosslessCompression", .T. )  ) // Specifies if graphics are exported to PDF using a lossless compression. If this property is set to true, it overwrites the "Quality" property
        AAdd( aPdfFilters, GetPropertyValue( oWriter, "ReduceImageResolution", .F. )  )
        AAdd( aPdfFilters, GetPropertyValue( oWriter, "Quality", 50 )  )  // Value can be between 1 to 100

        aProp = {}
        AAdd( aProp, GetPropertyValue( oWriter, "FilterName", "writer_pdf_Export" )  )
        AAdd( aProp, GetPropertyValue( oWriter, "FilterData", aPdfFilters )  )

        oDoc:StoreToURL( cURL, aProp )

    Endif

    // Inform the user about the Exported Filename along with the Full path
    * MsgInfo( cUrl )

    * oDoc:GetCurrentController():GetFrame():GetContainerWindow():SetVisible( .T. )
    oDoc:Close( 1 )  // To Close OpenOffice Word
    oDesktop:Terminate()  // To close the OpenOffice QuickOpen Window
    oDoc = nil

return nil

//------------------------------------//

static Function OoEmbeddGraphics(oWriter,oDoc)

   local oDrawPage, oProvider, aProp, i, oGraphic

   oDrawPage = oDoc:DrawPage
   oProvider = oWriter:CreateInstance( "com.sun.star.graphic.GraphicProvider" )

   if oDrawPage:hasElements()
      for i = 0 To oDrawPage:Count - 1
          oGraphic = oDrawPage:getByIndex( i )
          if oGraphic:supportsService( "com.sun.star.text.TextGraphicObject" )
             aProp = {}
             AAdd( aProp, GetPropertyValue( oWriter, "URL", oGraphic:GraphicUrl ) )
             oGraphic:Graphic = oProvider:queryGraphic( aProp )
          endIf
      next i
   endif

return nil

//----------------------------------------------------------------------------//

static function WordHasPDFPlugIn()

   static lPDF

   local oWord, oFilter

   if lPDF == nil
      lPDF = .F.
      if ( oWord := WinWordObj() ) != nil .and. Val( oWord:Version ) >= 12.0
         for each oFilter in oWord:FileDialog( 2 ):Filters
            if "*.pdf" $ oFilter:Extensions
               lPDF     := .t.
               exit
            endif
         next
      endif
   endif

return lPDF

//--------------------------------------------------------------------//

function RPrevUserBtns( bNewUserBtns, nBarStyle, aSize )

   local bPrev    := bUserBtns

   if PCount() > 0
      bUserBtns   := bNewUserBtns
      if PCount() > 1
         if nBarStyle == nil
            nStyle   := nil
         elseif ValType( nBarStyle ) == 'L' .and. nBarStyle == .t.
            nStyle   := 2007
         elseif ValType( nBarStyle ) == 'N' .and. AScan( { 97, 2007, 2010 }, nBarStyle ) > 0
            nStyle   := nBarStyle
         endif
         if PCount() > 2
            if ValType( aSize ) == 'A' .and. Len( aSize ) >= 2
               nBtnW    := aSize[ 1 ]
               nBtnH    := aSize[ 2 ]
            endif
         endif
      endif
   endif

return bPrev

//--------------------------------------------------------------------//

function SetCustomPrintPreview( bPreview )

   local bPrev    := bUserPreview

   if PCount() > 0
      bUserPreview   := If( ValType( bPreview ) == 'B', bPreview, nil )
   endif

return bPrev

//----------------------------------------------------------------------------//

