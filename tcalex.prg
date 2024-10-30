//tcalex.prg

#include "fivewin.ch"
#include "calex.ch"

#define HH_DISPLAY_TOPIC       0x0000
#define HH_DISPLAY_TOC         0x0001  //same as #define HH_DISPLAY_TOPIC.
#define HH_DISPLAY_INDEX       0x0002
#define HH_DISPLAY_SEARCH      0x0003
#define HH_KEYWORD_LOOKUP      0x000D
#define HH_DISPLAY_TEXT_POPUP  0x000E
#define HH_HELP_CONTEXT        0x000F
#define HH_CLOSE_ALL           0x0012
#define HH_ALINK_LOOKUP        0x0013


#define VIEW_MIN 140 // valor del ancho de la columna de la celda, si es menor de 140 muestra la ventana con la inf
#DEFINE NUMROWS    0 // Lo pongo yo CNL porque no se encuentra pero no se lo que es ni el TIPO del valor

CLASS TCalEx FROM TControl

   DATA nTool     AS NUMERIC

   DATA hCalInfo                    // Hash with CalInfo object
   DATA aInterval                   // Array with interval minutes

   DATA dStart        AS DATE
   DATA dEnd          AS DATE
   DATA dDate         AS DATE
   DATA dDateSelected AS DATE
   DATA bOnDelete
   DATA bSelected, bSelectedWeek
   DATA bSelectView
   DATA bRSelected

   DATA bOnNext
   DATA bOnPrev

   DATA hDays                        // days hash
   DATA hNextItem, hPrevItem         // Bitmaps handle next/prev "button" normal status
   DATA hNextItemo, hPrevItemo       // Bitmaps handle next/prev "button" over mouse status

   DATA lLeftLabel                   // Show/Hide vertical left label
   DATA lOverNext, lOverPrev         // used internally to check over next/prev bitmap
   DATA lSBVisible                   // used internally to check vertical scroll is visible
   DATA lActive                      //
   DATA lAmPm                        // am-pm format
   DATA lWorking                     //
   DATA lCaptured


   DATA aOverCell                     // Coordenates of over cell
   DATA aLabelText                    // left text (week)
   DATA aDateSelected                 // Position date selected
   DATA aGradCellNormal               // Gradient cell color, normal status
   DATA aGradCellSelected             // Gradient selected day
   DATA aGradHeaderCel                // Gradient Header cell color
   DATA aGradHeaderCelDay             // Gradient Header cell color of current day
   DATA aGradDifMonth                 // Gradient cell for diferent current month selected
   DATA aTodayPos                     // array position of Today

   DATA aGradLeftLabel                // Gradient Left Label fjhg
   DATA aGradHeaderMonth              // Gradient Header Month fjhg
   DATA aGradHeaderWeek               // Gradient Header Week fjhg

   DATA nAtRow
   DATA nAtCol                // Mouse position cell
   DATA nColorGrid                    // Grid line color
   DATA nColorGrid2                   // Grid internal line color
   DATA nColorCellSelected            // Color of border in cell selected
   DATA nColorGridToday               // Today Grid line color
   DATA nDNameHeight                  // Day Name header size
   DATA nLeftLabelWidth               // Left label width size
   DATA nBottomMargin                 // Bottom Margin
   DATA nLeftMargin                   // Left Margin
   DATA nRightMargin                  // Right Margin
   DATA nTopMargin                    // Top Margin
   DATA nWeek                         // nWeek Selected
   DATA nBtnPushed                    // 0 none
                                      // 2 Next
                                      // 1 Prev

   DATA nWks                          // Total week in month
   DATA nDays        PROTECTED        // Total days in view ( 1 / 7 )

   DATA nVirtualHeight
   DATA nVirtualTop
   DATA nStartHour   AS NUMERIC
   DATA nEndHour     AS NUMERIC
   DATA nInterval    AS NUMERIC
   DATA nTimeDown    AS NUMERIC

   //DATA nAtRow, nAtCol                // cell at position


   DATA oFontHeader
   DATA oFontLabel
   DATA oFontTop

   DATA oView                         // Current view active
   DATA oMonthView                    // Month view
   DATA oWeekView                     // Week View
   DATA oDayView                      // Day View

   DATA oCalInfo                      // Current Callendar Info object HITTESTed
   DATA oCalInfoSelected              // Current Callendar Info object selected

   DATA oVScroll

   DATA oBmp         AS ARRAY   INIT { nil,nil,nil,nil }    // fjhg
   DATA nBmpRows     AS NUMERIC INIT 0                      // fjhg
   DATA nIdReserva   AS NUMERIC INIT 0 // fjhg para validar que la reserva ya se
                                       // mostro al mover el raton sobre la cita

   CLASSDATA lRegistered AS LOGICAL

   METHOD New( oWnd, nClrText ) CONSTRUCTOR

   METHOD BuildDates()

   METHOD CheckChildren( oCalInfo )
   METHOD CheckScroll()
   METHOD CheckOverPrev( nRow, nCol )
   METHOD ConvertTime( nTime, l24 )

   METHOD DelCalInfo( lAll )

   METHOD EraseBkGnd( hDC ) INLINE 0

   METHOD Display() INLINE ::BeginPaint(), ::Paint(), ::EndPaint(), 0
   METHOD Destroy()

   METHOD GetCoorFromPos( nAtRow, nAtCol )
   METHOD GetCoorFromTime( nTime, dDate )
   METHOD GetFirstDateWeek()
   METHOD GetInfoFromCoors( nRow, nCol, dDate )
   METHOD GetLastDateWeek()
   METHOD GetStrInterval( nStart )
   METHOD GetTimeFromRow( nAtRow )
   METHOD GridWidth()    INLINE ::nWidth - ::nRightMargin - 2 - ;
                                ( ::nLeftMargin + ::nLeftLabelWidth ) - If( ::lSBVisible, GetSysMetrics( SM_CXVSCROLL ), 0 )
   METHOD GridHeight()   INLINE ::nHeight - ::nBottomMargin - 2

   METHOD GoNext()
   METHOD GoPrev()

   METHOD HitTest( nRow, nCol )

   METHOD Keydown( nKey, nFlags )

   METHOD LButtonDown( nRow, nCol, nKeyFlags )
   METHOD LButtonDownView( nRow, nCol, nKeyFlags )
   METHOD LButtonUp( nRow, nCol, nKeyFlags )
   METHOD LButtonUpView( nRow, nCol, nKeyFlags )
   METHOD LDblClick( nRow, nCol, nKeyFlags ) INLINE ::oView:LDblClick( nRow, nCol, nKeyFlags ), ;
                                                    ::Super:LDblClick( nRow, nCol, nKeyFlags )

   METHOD Line( hDC, nTop, nLeft, nBottom, nRight, nColor )
   METHOD LoadDates()

   METHOD MouseMove( nRow, nCol, nKeyFlags )
   METHOD MouseMoveView( nRow, nCol, nKeyFlags )
   METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos ) INLINE  ::oView:MouseWheel( nKeys, nDelta, nXPos, nYPos )

   METHOD MoveCalInfo()

   METHOD NextInterval()

   METHOD Paint()
   METHOD PaintCalInfo( hDC )
   METHOD PaintHorzLinesWithLeftLabels()	//used in dayv as well as weekv

   METHOD RButtonUp( nRow, nCol, nKeyFlags )

   METHOD Resize( nType, nWidth, nHeight ) INLINE ::oView:CheckScroll(), ;
                                                  ::oView:Resize( nType, nWidth, nHeight ), ;
                                                  ::Super:Resize( nType, nWidth, nHeight )

   METHOD Reset() INLINE ::hCalInfo := hb_HASH() //, ::aOverCell := {}

   METHOD SelectCalInfo( oCalInfo )
   METHOD SetDatas( oView )
   METHOD SetDate( dDate ) INLINE ::oView:SetDate( dDate )

   METHOD SetInterval( nMin )  //   Values allowed { 5, 10, 15, 20, 30, 60 }

   METHOD SetView(o)
   METHOD SetMonthView()  INLINE ::SetView( ::oMonthView )
   METHOD SetWeekView( dDate )
   METHOD SetDayView( dDate )
   METHOD SetScroll()

   METHOD VerifyPos( oCalInfo, oLast )
   METHOD VScrollSetPos( nPos )
   METHOD VScrollSkip( nSkip )

   METHOD UnSelectCalInfo() INLINE If( ::oCalInfoSelected != NIL, ( ::oCalInfoSelected:lSelected := .F. , ::oCalInfoSelected := NIL ), )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oWnd, nClrText) CLASS TCalEx

   local nMod, aFontInfo, n

   DEFAULT oWnd     := GetWndDefault()
   DEFAULT nClrText := 0

   ::oBmp[1] := LoadBitmap( GetResources(), "NEXT"       )    // fjhg
   ::oBmp[2] := LoadBitmap( GetResources(), "PREVIOUS"   )    // fjhg
   ::oBmp[3] := LoadBitmap( GetResources(), "NEXT_O"     )    // fjhg
   ::oBmp[4] := LoadBitmap( GetResources(), "PREVIOUS_O" )    // fjhg

   ::nTop       = 0
   ::nLeft      = 0
   ::nBottom    = 600
   ::nRight     = 600
   ::oWnd       = oWnd

   //Dates
   ::dDate         := Date()   //FechaServer()    // Date() fjhg
   ::dDateSelected := ::dDate

   //Bmp Handles     Adaptado fjhg
   IF ::oBmp[1] <> 0 .AND. ::oBmp[2] <> 0 .AND. ::oBmp[3] <> 0 .AND. ::oBmp[4] <> 0
      ::nBmpRows    = NUMROWS    // fjhg
      ::hNextItem   = ::oBmp[1]
      ::hPrevItem   = ::oBmp[2]
      ::hNextItemo  = ::oBmp[3]
      ::hPrevItemo  = ::oBmp[4]
   ELSE
      ::nBmpRows := 0
      ::hNextItem   = hNextItem()
      ::hPrevItem   = hPrevItem()
      ::hNextItemo  = hNextItemo()
      ::hPrevItemo  = hPrevItemo()
   ENDIF

   ::nClrText    = nClrText
   ::nStyle      = nOr( WS_CHILD, WS_VISIBLE, WS_TABSTOP, WS_BORDER, WS_CLIPCHILDREN )

   //Array
   ::aGradCellNormal    = { { 1, nRGB( 255, 255, 255 ), nRGB( 255, 255, 255 ) } }
   //::aGradHeaderCel     = { { 1, nRGB( 165, 191, 225 ), nRGB( 165, 191, 225 ) } }
   ::aGradHeaderCel     = { { 1, nRGB( 235, 235, 235 ), nRGB( 235, 235, 235 ) } }
   ::aGradDifMonth      = { { 1, nRGB( 165, 191, 225 ), nRGB( 165, 191, 225 ) } }
   //::aGradCellSelected  = { { 1, nRGB( 230, 237, 247 ), nRGB( 0, 25, 64 ) } }    // Aqui nRGB( 230, 237, 247 )
   ::aGradCellSelected  = { { 1, nRGB( 0, 25, 64 ), nRGB( 0, 25, 64 ) } }    // Aqui nRGB( 230, 237, 247 )
   ::aGradLeftLabel     = { { 1, nRGB( 230, 237, 247 ), nRGB( 220, 207, 237 ) } }
   ::aGradHeaderCelDay  = { { 1/2, nRGB( 255, 237, 121 ), nRGB( 255, 216, 157 ) },;
                            { 1/2, nRGB( 255, 216, 157 ), nRGB( 255, 237, 121 ) } }
   ::aGradHeaderMonth   = { { 1/2, nRGB( 219, 230, 244 ),       nRGB( 207-50, 221-25, 255 ) }, ;
                            { 1/2, nRGB( 201-50, 217-25, 255 ), nRGB( 231, 242, 255 ) } }
   ::aGradHeaderWeek    = { { 1/2, nRGB( 219, 230, 244 ),       nRGB( 207-50, 221-25, 255 ) }, ;
                            { 1/2, nRGB( 201-50, 217-25, 255 ), nRGB( 231, 242, 255 ) } }

   ::Reset()

   //LOGICAL
   ::lLeftLabel   = .T.
   ::lOverPrev    = .F.
   ::lOverNext    = .F.
   ::lSBVisible   = .F.
   ::lActive      = .F.

   //Numeric
   ::nColorGrid       = nRGB( 141, 174, 217 )
   ::nColorGrid2      = nRGB( 0, 25, 64 )   // Aqui Celda Seleccionada  nRGB( 230, 237, 247 )
   ::nColorCellSelected = nRGB( 235, 137, 000 ) // 0
   ::nColorGridToday  = nRGB( 235, 137, 000 )
   ::nDNameHeight     = 20
   ::nLeftLabelWidth  = 20
   ::nLeftMargin      = 2
   ::nRightMargin     = 2
   ::nBottomMargin    = 2
   ::nTopMargin       = 60
   ::nWeek            = 0
   ::nStartHour	  	  = 0.00
   ::nEndHour         = 24.00
   ::nVirtualHeight   = ::nHeight

   if ::oFont != NIL
      ::oFont:End()
   endif

   aFontInfo = GetFontInfo( GetStockObject( DEFAULT_GUI_FONT ) )

   DEFINE FONT ::oFont        NAME aFontInfo[ 4 ] SIZE aFontInfo[ 2 ], aFontInfo[ 1 ]
   DEFINE FONT ::oFontHeader  NAME aFontInfo[ 4 ] SIZE aFontInfo[ 2 ], aFontInfo[ 1 ] BOLD
   DEFINE FONT ::oFontTop     NAME aFontInfo[ 4 ] SIZE aFontInfo[ 2 ] * 2.5, aFontInfo[ 1 ] * 2.5

   ::oFontLabel = TFont():New( aFontInfo[ 4 ], aFontInfo[ 2 ], aFontInfo[ 1 ], , , 900, 900 )

   #ifdef __XPP__
      DEFAULT ::lRegistered := .F.
   #endif

  ::SetBrush( ::oWnd:oBrush )

   ::Register()

   if ! Empty( oWnd:hWnd )
      ::Create()
      oWnd:AddControl( Self )
   else
      oWnd:DefControl( Self )
   endif

   DEFINE SCROLLBAR ::oVScroll VERTICAL OF Self

   ::oMonthView = TMonthView():New( Self )
   ::oWeekView  = TWeekView():New( Self )
   ::oDayView   = TDayView():New( Self )
   ::SetMonthView()

   ::oWnd:oClient = Self
   ::GoTop()
   ::SetFocus()                         // Añadido Cnl 28/03/2013

return Self

//----------------------------------------------------------------------------//

METHOD Destroy() CLASS TCalEx

   ::oFontHeader:End()
   ::oFontLabel:End()

   DeleteObject( ::hNextItem  )
   DeleteObject( ::hPrevItem  )
   DeleteObject( ::hNextItemo )
   DeleteObject( ::hPrevItemo )

   DeleteObject( ::oBmp[1] )    // fjhg
   DeleteObject( ::oBmp[2] )    // fjhg
   DeleteObject( ::oBmp[3] )    // fjhg
   DeleteObject( ::oBmp[4] )    // fjhg

return ::Super:Destroy()


//----------------------------------------------------------------------------//

METHOD BuildDates() CLASS TCalEx

   local oCalInfo
   local cStrDay, aInfo, aInfo2
   local aPos, aCoor
   local n, j
   local nAt, nHour, nMin, cStrInterval, hInfo
   local nTime
   locaL nColStep := Int( ::GridWidth() / ::nDays )
   local nModCol := ::GridWidth() % ::nDays - 1
   local dLastDateWeek, oLast

   dLastDateWeek  := ::GetLastDateWeek()
   ::hDays        = hb_HASH()

   //fill and sort dates by day
   for each oCalInfo in ::oCalex:hCalInfo
#ifdef __XHARBOUR__
      oCalInfo = oCalInfo:Value
#endif
      aInfo = {}
      hInfo       = hb_HASH()
      if ValType(::dStart) <> "D"
         ::dStart := oCalInfo:dStart
      endif
      if ValType(::dEnd) <> "D"
         ::dEnd := oCalInfo:dStart
      endif
      if oCalInfo:dStart >= ::dStart .and. oCalInfo:dStart <= ::dEnd
         cStrDay = DToS( oCalInfo:dStart )
         //? cStrDay
         if hb_HHASKEY( ::hDays, cStrDay )
            hInfo := hb_HGET( ::hDays, cStrDay )
         endif

         nTime = oCalInfo:nStart

         cStrInterval = ::GetStrInterval( oCalInfo:nStart )


         if hb_HHASKEY( hInfo, cStrInterval )
            aInfo = hb_HGET( hInfo, cStrInterval )
         else
            hb_HSET( hInfo, cStrInterval, aInfo )
         endif
         oCalInfo:lCreated = .F.
         AAdd( aInfo, oCalInfo )

         ASort( aInfo, , ,{| o1, o2 | o1:nStart < o2:nStart } )

         hb_HSET( ::hDays, cStrDay, hInfo )

      endif

   next

   if ! Empty( ::hDays )

      aCoor = { NIL, NIL }
      for each hInfo in ::hDays
         n = 0
#ifdef __XHARBOUR__
         hInfo = hInfo:Value
#endif
         for each aInfo in hInfo //oCalInfo in aInfo
#ifdef __XHARBOUR__
            aInfo = aInfo:Value
#endif

            for each oCalInfo in aInfo
               n++
               if n == 1
                  aCoor[ 1 ] = ::GetCoorFromTime( oCalInfo:nStart, oCalInfo:dStart )
                  aCoor[ 2 ] = ::GetCoorFromTime( oCalInfo:nEnd, oCalInfo:dStart )

                  oCalInfo:BuildDates( aCoor[ 1 ][ 1 ], ;
                                       aCoor[ 1 ][ 2 ], ;
                                       nColStep + If( oCalInfo:dStart == dLastDateWeek, nModCol, 0 ),;
                                       Max( ::nRowHeight, aCoor[ 2 ][ 1 ] - aCoor[ 1 ][ 1 ] ) + 1, ::oCalex )
                  oCalInfo:nFlags = FLAGS_START
                  ::VerifyPos()
               else
                  ::VerifyPos( oCalInfo, oLast )
               endif

               oLast = oCalInfo
            next
         next
      next
   endif

   ::Resize()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD CheckChildren( oCalInfo ) CLASS TCalEx

   local cStrDay := DToS( oCalInfo:dStart )
   local hInfo
   local nMin, nHour
   local nTot := 1, lRet := .T.
   local cStrInterval, aTempInfo, n := 1, j := 2
   local nStart := oCalInfo:nStart

   if hb_HHASKEY( ::hDays, cStrDay )
      hInfo := hb_HGET( ::hDays, cStrDay )
   endif

   //verify more children in other interval
   while lRet
      cStrInterval := ::GetStrInterval( nStart )
      if hb_HHASKEY( hInfo, cStrInterval )
         aTempInfo = hb_HGET( hInfo, cStrInterval )
         if Len( aTempInfo ) > 0
            for n = j to Len( aTempInfo )
               if nAND( aTempInfo[ n ]:nFlags, FLAGS_RIGHT ) == FLAGS_RIGHT
                  nTot ++
               elseif aTempInfo[ n ]:nFlags == FLAGS_START
                  lRet = .F.
               endif
            next
         endif
      endif
      nStart = ::NextInterval( nStart )
      j = 1
      lRet = nStart > 0 .and. lRet
   enddo

return nTot

//----------------------------------------------------------------------------//

METHOD CheckOverPrev( nRow, nCol ) CLASS TCalEx

    // check over Prev
   if nRow > ( ROWITEM - ::nBmpRows ) .and. nRow < ( ROWITEM - ::nBmpRows ) + BMPITEMH    // fjhg
      if nCol > COLPREV .and. nCol < COLPREV + BMPITEMW
         ::lOverPrev = .T.
         ::lOverNext = .F.
      elseif nCol > COLNEXT .and. nCol < COLNEXT + BMPITEMW
         ::lOverNext = .T.
         ::lOverPrev = .F.
      elseif ::lOverNext .or. ::lOverPrev
         ::lOverNext = .F.
         ::lOverPrev = .F.
      endif
   elseif ::lOverNext .or. ::lOverPrev
      ::lOverNext = .F.
      ::lOverPrev = .F.
   endif
   ::Refresh()

RETURN NIL


//----------------------------------------------------------------------------//

METHOD CheckScroll() CLASS TCalEx

   local nLastRow
   local nPos

   if ! ::lActive
      RETURN nil
   endif

   nLastRow := ::GridHeight() + ::nTopMargin
   if nLastRow > ::nHeight
      ::nVirtualHeight = nLastRow
      SetScrollRangeX( ::hWnd, 1, 0, ::nVirtualHeight - 1)

      if  (::nVirtualHeight - ::nVirtualTop) < ::nHeight
         ::nVirtualTop := ::nVirtualHeight - ::nHeight
      endif

      ::oVScroll:SetPage( ::nHeight, .F. )
      ::oVScroll:SetPos( ::nVirtualTop )
      ::lSBVisible = .T.

   else
      ::nVirtualTop = 0
      ::nVirtualHeight = ::nHeight
      SetScrollRangeX( ::hWnd, 1, 0, 0 )
      ::lSBVisible = .F.
   endif

   ::SetFocus()

RETURN nil

//----------------------------------------------------------------------------//

METHOD DelCalInfo( lAll ) CLASS TCalEx

   local nID
   local oCalInfo
   local hInfo, cStrDay

   DEFAULT lAll := .F.

   if lAll
      ::hCalInfo = hb_HASH()
      ::hDays    = hb_HASH()
   else
      if ::oCalInfoSelected != NIL
         nID = ::oCalInfoSelected:nID
         for each oCalInfo in ::hCalInfo
#ifdef __XHARBOUR__
            oCalInfo = oCalInfo:Value
#endif
            if oCalInfo:nID == nID
               cStrDay = DToS( oCalInfo:dStart )
               if hb_HHASKEY( ::oView:hDays, cStrDay )
                  hInfo := hb_HGET( ::oView:hDays, cStrDay )
               endif
               if hb_HHASKEY( hInfo, StrZero( oCalInfo:nStart ) )
                  hb_HDEL( hInfo, StrZero( oCalInfo:nStart ) )
               endif
               exit
            endif
         next
         if ::oView:bOnDelete != NIL
            Eval( ::oView:bOnDelete, ::oView, If( lAll, NIL, ::hCalInfo[ nID ]:nIdx ) )
         endif
         hb_HDEL( ::hCalInfo, nID )
         ::oView:BuildDates()
      endif
   endif

RETURN NIL

//----------------------------------------------------------------------------//

METHOD GetCoorFromPos( nAtRow, nAtCol ) CLASS TCalEx

   local nColStep, nModCol, nRowStep
   local nGridWidth  := ::GridWidth()
   local nGridHeight := ::GridHeight()
   local aCoor := Array( 4 ) //Top, Left, Bottom, Right

   nColStep = Int( nGridWidth / ::nDays )
   nModCol = nGridWidth % ::nDays

   nRowStep = ::nRowHeight

   aCoor[ 1 ] = Max( 0, ( nAtRow - 1 ) * nRowStep + ::nTopMargin - ::nVirtualTop + 1 )
   aCoor[ 2 ] = ( nAtCol - 1 ) * nColStep + ::nLeftMargin + ::nLeftLabelWidth + 1
   aCoor[ 3 ] = aCoor[ 1 ] + nRowStep - 1
   aCoor[ 4 ] = aCoor[ 2 ] + nColStep + If( nAtCol == ::nDays, nModCol, 0 ) - 1

RETURN aCoor

//----------------------------------------------------------------------------//

METHOD GetCoorFromTime( nTime, dDate ) CLASS TCalEx
   local nRow, nCol
   local nHour
   local nMin
   local nIntByHour := 60 / ::nInterval
   local dFirstDateWeek := ::GetFirstDateWeek()//::dDateSelected - DoW( ::dDateSelected ) + 1
   locaL nColStep := Int( ::GridWidth() / ::nDays )
   local aCoor := Array( 4 )
   local nTimeTemp := nTime - ::nStartHour * 100


   nCol := ( dDate  -  dFirstDateWeek ) * nColStep + ::nLeftMargin + ::nLeftLabelWidth + 1

   nHour = Int( nTimeTemp / 100 )
   nMin  = nTimeTemp - nHour * 100

   nRow := nHour * nIntByHour * ::nRowHeight + ::nRowHeight * nMin / ::nInterval + ::nTopMargin - ::nVirtualTop

RETURN { nRow, nCol }

//----------------------------------------------------------------------------//

METHOD GetFirstDateWeek( dDate ) CLASS TCalEx
   local dFirstDateWeek

   DEFAULT dDate := ::dDateSelected

   if ::Classname() != "TDAYVIEW"
      // Si ponemos +2 empieza en lunes
      dFirstDateWeek  = dDate - DoW( dDate ) + 2 + _GFD  //+ 1 //+ _GFD
   else
      dFirstDateWeek  = dDate
   endif

RETURN dFirstDateWeek

//----------------------------------------------------------------------------//

METHOD GetInfoFromCoors( nRow, nCol, dDate ) CLASS TCalEx

   local oCalInfo, oCalRet
   local hInfo, aInfo
   local nTempRow := nRow //- ::nVirtualTop
   local nTempCol := nCol //+ ::nLeftLabelWidth - ::nLeftMargin
   if ! Empty( ::hDays )

      for each hInfo in ::hDays
#ifdef __XHARBOUR__
         hInfo = hInfo:Value
#endif
         for each aInfo in hInfo //oCalInfo in aInfo
#ifdef __XHARBOUR__
            aInfo = aInfo:Value
#endif

            for each oCalInfo in aInfo
               if dDate == oCalInfo:dStart
                  if oCalInfo:aCoords[ CI_TOP ] < nTempRow .and. oCalInfo:aCoords[ CI_BOTTOM ] > nTempRow .and. ;
                     oCalInfo:aCoords[ CI_LEFT ] + 10 < nTempCol .and. oCalInfo:aCoords[ CI_RIGHT ] > nTempCol    // fjhg 10-10-2012 se agrego "+ 10" para poder seleccionar sobre la misma linea
                     oCalRet = oCalInfo
                     exit
                  endif
               endif
            next
         next
      next
   endif

return oCalRet

//----------------------------------------------------------------------------//

METHOD GetLastDateWeek() CLASS TCalEx
   local dLastDateWeek

   if ::Classname() != "TDAYVIEW"
      dLastDateWeek  := ::GetFirstDateWeek() + ::nDays - 1
   else
      dLastDateWeek  := ::dDateSelected
   endif

RETURN dLastDateWeek

//----------------------------------------------------------------------------//

METHOD GoNext() CLASS TCalEx

   local dDateTemp

   if ::oCalex:oView:IsKindOf( "TWEEKVIEW" )
      dDateTemp = ::GoNextWeek()
      ::oCalex:oMonthView:SetDate( dDateTemp )
      if ::bOnNext != NIL
         Eval( ::bOnNext, Self, dDateTemp )
      endif
      ::oCalex:SetWeekView()
   else
      dDateTemp = ::GoNextDay()
      ::oCalex:oDayView:SetDate( dDateTemp )
      if ::bOnNext != NIL
         Eval( ::bOnNext, Self, dDateTemp )
      endif
      ::oCalex:SetDayView()
   endif

RETURN NIL

//----------------------------------------------------------------------------//

METHOD GoPrev() CLASS TCalEx

   local dDateTemp

   if ::oCalex:oView:IsKindOf( "TWEEKVIEW" )
       dDateTemp = ::GoPrevWeek()
       ::dDateSelected = dDateTemp
       ::oCalex:oMonthView:SetDate( dDateTemp )
       if ::bOnPrev != NIL
          Eval( ::bOnPrev, Self, dDateTemp )
       endif
       ::oCalex:SetWeekView()
    else
       dDateTemp = ::GoPrevDay()
       ::oCalex:oDayView:SetDate( dDateTemp )
       if ::bOnPrev != NIL
          Eval( ::bOnPrev, Self, dDateTemp )
       endif
       ::oCalex:SetDayView()
    endif

RETURN NIL

//----------------------------------------------------------------------------//

METHOD GetStrInterval( nStart ) CLASS TCalEx

   local nHour, nMin, cStrInterval, nAt

   nHour = Int( nStart / 100 )
   nMin  = nStart - nHour * 100

   nAt   = AScan( ::aInterval, {| nVal | nMin < nVal } ) - 1
   if nAt > 0
      cStrInterval = StrZero( Val( Str( nHour, 2 ) ), 2 ) + StrZero( Val( Str( ::aInterval[ nAt ], 2 ) ), 2 )
   else
      cStrInterval = StrZero( Val( Str( nHour, 2 ) ), 2 ) + StrZero( Val( Str( ATail( ::aInterval ), 2 ) ), 2 )
   endif

return cStrInterval

//----------------------------------------------------------------------------//

METHOD GetTimeFromRow( nAtRow ) CLASS TCalEx

   local nTime    := ::nStartHour * 100
   local nMinutes := Val( Right( StrZero( nTime, 4 ), 2 ) )
   local nHour    := ( nTime - nMinutes ) / 100
   local nMinAt
   local nHourAt  := 0

   DEFAULT nAtRow := ::nAtRow

   nMinAt = ::nInterval * ( nAtRow - 1 )

   if nMinAt > 0

      nHourAt = Int( nMinAt / 60 )
      nMinAt  = nMinAt % 60

   endif

   nHour    += nHourAt
   nMinutes = nMinAt

   nTime := nHour * 100 + nMinutes

return Int( nTime )

//----------------------------------------------------------------------------//

METHOD HitTest( nRow, nCol ) CLASS TCalEx
   local nGridWidth := ::GridWidth()
   local nColStep , nModCol
   local nAtCol, nAtRow
   local nRowStep := ::nRowHeight
   local aCoor
   local aRet
   local oCalInfo
   local dFirstDateWeek := ::GetFirstDateWeek()//::dDateSelected - DoW( ::dDateSelected ) + 1

   nColStep = Int( nGridWidth / ::nDays )
   nModCol = nGridWidth % ::nDays

   nAtCol = Min( Int( ( nCol - ::nLeftLabelWidth - ::nLeftMargin ) / nColStep ) + 1, ::nDays )
   //logical row
   nAtRow := Int( ( nRow + ::nVirtualTop - ::nTopMargin ) / nRowStep ) + 1

   if nRow < ::nTopMargin .and. nRow > ::nTopMargin - ::nDNameHeight
      aRet = { HITTEST_HEADER, nAtCol }
   elseif nRow > ::nTopMargin .and. nCol > ::nLeftLabelWidth + ::nLeftMargin .and. nRow < ::GridHeight() + ::nTopMargin
      ::nAtRow = nAtRow
      ::nAtCol = nAtCol
      aCoor = ::GetCoorFromPos( nAtRow, nAtCol )

      //verify is over oCalInfo object
      oCalInfo := ::GetInfoFromCoors( nRow, nCol, dFirstDateWeek + nAtCol - 1 )

      ::oCalex:oCalInfo  = oCalInfo
      aRet = { HITTEST_BODY, If( ::oCalex:oCalInfo != NIL, NIL, aCoor ) }

   elseif  nCol < ::nLeftLabelWidth + ::nLeftMargin
      ::nAtRow = nAtRow
      aRet = { HITTEST_TIME, nAtRow }
   else
      aRet = { HITTEST_EMPTY, NIL }
   endif

return aRet

//----------------------------------------------------------------------------//


METHOD LButtonDown( nRow, nCol, nKeyFlags ) CLASS TCalEx

   if ::oCalInfo != NIL
      ::oCalInfo:lSelected = .F.
   endif

   ::oView:LButtonDown( nRow, nCol, nKeyFlags )

   ::Refresh()
   ::SetFocus()

return ::Super:LButtonDown( nRow, nCol, nKeyFlags )

//----------------------------------------------------------------------------//

METHOD LButtonDownView( nRow, nCol, nKeyFlags ) CLASS TCalEx

   local aRet
   local nOpc

   ::nBtnPushed := If( ::lOverPrev, PUSHEDPREV, If( ::lOverNext, PUSHEDNEXT, 0 ) )
   ::aSelectedRow = {}
   if ::nBtnPushed == 0
      aRet = ::HitTest( nRow, nCol )
      nOpc = aRet[ HITTEST_PLACE ]
      switch nOpc
         case HITTEST_BODY
            SetCapture( ::oCalex:hWnd )
            if ::oCalex:oCalInfo == NIL
               ::nRowDown  = ::nAtRow
               ::nColDown  = ::nAtCol
               ::lCaptured = .T.
               ::nLastRow  = ::nAtRow
               AAdd( ::aSelectedRow, { ::nRowDown, ::nColDown } )
               ::oCalex:UnSelectCalInfo()
            else
               ::oCalex:SelectCalInfo()
            endif
            exit
         case HITTEST_HEADER
            ::nColDown = aRet[ 2 ]

      endswitch
   endif

return nil

//----------------------------------------------------------------------------//

METHOD LButtonUp( nRow, nCol, nKeyFlags ) CLASS TCalEx

   ::oView:LButtonUp( nRow, nCol, nKeyFlags )

return ::Super:LButtonUp( nRow, nCol, nKeyFlags )

//----------------------------------------------------------------------------//

METHOD LButtonUpView( nRow, nCol, nKeyFlags ) CLASS TCalEx

   local nPushed := If( ::lOverPrev, PUSHEDPREV, If( ::lOverNext, PUSHEDNEXT, 0 ) )
   local dDateTemp, nTimeDown
   local nTime, nAtColDown
   local aRet, n

   ReleaseCapture()

   ::lCaptured = .F.

   if nPushed == ::nBtnPushed .and. nPushed != 0
      if nPushed == PUSHEDPREV
         ::GoPrev()

      elseif nPushed == PUSHEDNEXT
         ::GoNext()

      endif
   else
      nAtColDown = ::nColDown
      aRet = ::HitTest( nRow, nCol )
      if ::nRowDown > ::nAtRow
         nTime     = ::GetTimeFromRow( ::nRowDown + 1 )
         nTimeDown = ::GetTimeFromRow()
      else
         nTime     = ::GetTimeFromRow( ::nAtRow + 1 )
         nTimeDown = ::GetTimeFromRow( ::nRowDown )
      endif

      switch aRet[ 1 ]
         case HITTEST_BODY
            if ::bSelected != nil
               Eval( ::bSelected, nRow, nCol, Self, ;
                               ::GetFirstDateWeek() + nAtColDown - 1, ;
                               ::GetFirstDateWeek() + ::nAtCol - 1, ;
                               nTimeDown,;
                               nTime )
            endif
            exit
         case HITTEST_HEADER
//  omitido por fjhg para que no pinte todo el dia al clickar en el encabezado
            ::aSelectedRow = {}
            for n = 1 to ::nRowCount
               AAdd( ::aSelectedRow, { n, ::nColDown } )
            next
           if ::oCalex:oView:IsKindOf( "TWEEKVIEW" )     // fjhg 28-09-2012
              ::dDateSelected := ( ::GetFirstDateWeek() + ::nColDown - 1 )
              ::dDate := ::dDateSelected
              ::SetDate( ::dDate )
           endif
           ::Refresh()
      endswitch

   endif

   ::Refresh()

return nil

//-----------------------------------------------------------------//

METHOD Line( hDC, nTop, nLeft, nBottom, nRight, nColor ) CLASS TCalEx

   local hPen, hOldPen


   hPen = CreatePen( PS_SOLID, 1, nColor )
   hOldPen = SelectObject( hDC, hPen )
   MoveTo( hDC, nLeft, nTop )
   LineTo( hDC, nRight, nBottom )
   SelectObject( hDC, hOldPen )
   DeleteObject( hPen )


return nil

//-----------------------------------------------------------------//

METHOD LoadDates( nStart, nEnd, dStart, dEnd, cText, cSubject, nIdx, lND, lAplicado, lBloqueoT ) CLASS TCalEx

   local oCalInfo

   WITH OBJECT oCalInfo := TCalInfo():New()
      :nStart    = nStart
      :nEnd      = nEnd
      :dStart    = dStart
      :dEnd      = dEnd
      :cText     = cText
      :cSubject  = cSubject
      :oCalex    = Self
      :nIdx      = nIdx
      :lND       = lND
      :lAplicado = lAplicado
      //:lBloqueoT = lBloqueoT
   END

   hb_HSET( ::hCalInfo, oCalInfo:nId, oCalInfo )

RETURN NIL

//----------------------------------------------------------------------------//

METHOD MoveCalInfo( nSkip ) CLASS TCalEx

   local aInfo, hInfo, oCalInfo

   if ! Empty( ::hDays )

      for each hInfo in ::hDays
#ifdef __XHARBOUR__
         hInfo = hInfo:Value
#endif
         for each aInfo in hInfo //oCalInfo in aInfo
#ifdef __XHARBOUR__
            aInfo = aInfo:Value
#endif
            for each oCalInfo in aInfo
               oCalInfo:Move( oCalInfo:aCoords[ CI_TOP ] - nSkip, , , oCalInfo:aCoords[ CI_BOTTOM ] - nSkip )
            next
         next
      next
   endif

return nil


//-----------------------------------------------------------------//

METHOD MouseMove( nRow, nCol, nKeyFlags ) CLASS TCalEx
//if ::oCalex:oView:IsKindOf( "TMONTHVIEW" )

   ::oView:MouseMove( nRow, nCol, nKeyFlags )

return ::Super:MouseMove( nRow, nCol, nKeyFlags )

//-----------------------------------------------------------------//
/*
METHOD MouseMoveView( nRow, nCol, nKeyFlags ) CLASS TCalEx

   local aRet, oTooltip, cTooltip
   local nTxtWidth := 0, nTxtHeight
   local oFont, aPos, hOldFont

   local nLenToolTip, hWnd, aToolTip

   ::CheckOverPrev( nRow, nCol )

   aRet = ::HitTest( nRow, nCol )
   //if aRet[ HITTEST_PLACE ] == HITTEST_BODY
      //if ::lCaptured
      //   ::nIdReserva := 0     // fjhg 02-04-2013
      //else
*---------  fjhg 02-04-2013 Simula tooltip, muestra la info de la cita en vista DIARIA
         if ::Classname() == "TDAYVIEW" .AND. ::oCalex:oCalInfo != NIL
            //if ( ::oCalex:oCalInfo:aCoords[ CI_RIGHT ] - ::oCalex:oCalInfo:aCoords[ CI_LEFT ] ) < VIEW_MIN .AND. ::nIdReserva <> ::oCalex:oCalInfo:nIdx
               //::nIdReserva := if( ::oCalex:oCalInfo == nil, 0, ::oCalex:oCalInfo:nIdx )

               //::aPos[1] := nRow
               //::aPos[2] := nCol
               cTooltip := ::oCalex:oCalInfo:cSubject
            if cTooltip + Dtoc( ::dDateSelected ) <> ::oToolTip
               ::oToolTip := cToolTip + Dtoc( ::dDateSelected )
               hWnd = CreateToolTip( Self:hWnd, If( ValType( cToolTip ) == "A", cToolTip[ 1 ], cToolTip ),  ;
                                     If( ::lBalloon != nil, ::lBalloon, .t. ) )

               aPos := { nRow, nCol }
                                                       //::oToolTip:hWnd
               nTxtHeight := Max( 14, GetTextHeight( hWnd ) - 2 )

               aToolTip := Array( nLenToolTip := MLCount( cToolTip, 254 ) )
               AEval( aToolTip, {|c, n| aToolTip[ n ] := Trim( MemoLine( cToolTip, 252, n ) ), ;
                      nTxtWidth := Max( nTxtWidth, GetTextWidth( 0, aToolTip[ n ], ::oFont:hFont ) + 7 ) } )

               //::oToolTip:Move( aPos[ 1 ], aPos[ 2 ], nTxtWidth, nTxtHeight * nLenToolTip + 3 )
//               oTooltip:Show()
               //ACTIVATE ::oToolTip
            //else
            //   ::aPosic[ 1 ] := nRow
            //   ::aPosic[ 2 ] := nCol
            endif

            //endif
         else
            ::nIdReserva := 0
            ::oToolTip   := Nil
         endif
      //endif
   //endif

return ::Super:MouseMove( nRow, nCol, nKeyFlags )
*/

METHOD MouseMoveView( nRow, nCol, nKeyFlags ) CLASS TCalEx

   local aRet
   local cToolTip  := ""

   local nTxtWidth := 0
   local nTxtHeight
   local nLenToolTip
   local hWnd
   local aToolTip
   local aPos

   local nDc

   ::CheckOverPrev( nRow, nCol )

   aRet = ::HitTest( nRow, nCol )
   if aRet[ HITTEST_PLACE ] == HITTEST_BODY
      if ::lCaptured
         ::Refresh()
      endif
   endif

   /*
   if Valtype( ::oToolTip ) <> "N" //.and. Valtype( ::oToolTip ) <> "N"
      //::oToolTip   := 99999
      ::oToolTip    := -3
   endif
   */

   if !empty( ::oCalex:oCalInfo )

      cTooltip    := RTrim( ::oCalex:oCalInfo:cSubject ) + CRLF + ::oCalex:oCalInfo:cText
      ::oCalex:cToolTip      := cToolTip
      //nDc := ::oCalex:oCalinFo:GetDC()
      //::oToolTip  := cToolTip + " " + Dtoc( ::dStart ) + " " + AllTrim( STr( ::oCalex:oCalInfo:nStart ) ) + " " + AllTrim( STr( ::oCalex:oCalInfo:nEnd ) )
   endif


   if !empty( cToolTip ) .and. ::nTool = -1//.and. empty( ::oToolTip ) //!empty( ::nAtRow ) // ::nIdReserva = 0 .and. ::oToolTip = Nil
      //if ::lCaptured

      nDc := ::oCalex:oCalinFo:GetDC()

      //? nDc , ::oToolTip
      //if nDc <> ::nTool

         //cToolTip := cToolTip + CRLF + Str( nDc ) + CRLF + Str( ::nTool )

         ::nTool := nDc

         //hWnd := CreateToolTip( Self:hWnd , cToolTip , .T. )
         ::oCalex:ShowToolTip()
/*
#define HH_DISPLAY_TOPIC       0x0000
#define HH_DISPLAY_TOC         0x0001  //same as #define HH_DISPLAY_TOPIC.
#define HH_DISPLAY_INDEX       0x0002
#define HH_DISPLAY_SEARCH      0x0003
#define HH_KEYWORD_LOOKUP      0x000D
#define HH_DISPLAY_TEXT_POPUP  0x000E
#define HH_HELP_CONTEXT        0x000F
#define HH_CLOSE_ALL           0x0012
#define HH_ALINK_LOOKUP        0x0013
*/

       //  HTMLPOP( GetActiveWindow(), nil, 0x000E, cToolTip )//, nil , nil , nRGB( 255, 255, 255 ),  nRGB( 0, 25, 64 )  )
      //endif
//      if ( cTooltip + Dtoc( ::dStart ) + AllTrim( STr( ::oCalex:oCalInfo:nStart ) ) ) <> ::oToolTip
      //if ::oToolTip <> ::nAtRow  .and. ::oToolTip >= 0
         //::oToolTip   := cToolTip + Dtoc( ::dDateSelected ) + AllTrim( STr( ::oCalex:oCalInfo:nStart ) )

         //::nIdReserva := -1

         //HTMLPOP( hWnd, cHelpFile, HH_DISPLAY_TEXT_POPUP, cnHelp, nRow, nCol, nBgColor,nTxColor )
         /*
         HTMLPOP( GetActiveWindow(), nil, 0x000E, ;
                  Dtoc(::dDateSelected ) + CRLF + STr( ::oCalex:oCalInfo:nStart ) + CRLF +;
                  cToolTip + CRLF + Str( ::nRowDown ) + CRLF + Str( ::nAtRow ) + CRLF  ,;
                  nRow , nCol  , nRGB( 0, 25, 64 ), nRGB( 255, 255, 255 ) )
         */
         //      hWnd = CreateToolTip( Self:hWnd, If( ValType( cToolTip ) == "A", cToolTip[ 1 ], cToolTip ), .F. )// ;
                                    // If( ::lBalloon != nil, ::lBalloon, .t. ) )

//               hWnd = CreateToolTip( Self:hWnd, cToolTip , .T. )

               //aPos := { nRow, nCol }
               /*
                                                       //::oToolTip:hWnd
               nTxtHeight := Max( 14, GetTextHeight( hWnd ) - 2 )

               aToolTip   := Array( nLenToolTip := MLCount( cToolTip, 254 ) )
               AEval( aToolTip, {|c, n| aToolTip[ n ] := Trim( MemoLine( cToolTip, 252, n ) ), ;
                      nTxtWidth := Max( nTxtWidth, GetTextWidth( 0, aToolTip[ n ], ::oFont:hFont ) + 7 ) } )
               */


         //::oToolTip   := -1    //::nAtRow
//         ::oToolTip   := cToolTip + Dtoc( ::dStart ) + AllTrim( STr( ::oCalex:oCalInfo:nStart ) )

      //else
         //::nAtRow     := 0
         //::oToolTip     := ::nAtRow    //-1
      //   ::nTool   := -2   // ::nAtRow
      //   ::cToolTip   := nil
      //   ::oCalex:DestroyToolTip()
      //endif
   else
      //::nAtRow     := 0
      //::oToolTip   := 0
      ::nTool   := -1
      ::oCalex:cToolTip   := nil
      ::oCalex:DestroyToolTip()
   endif

 /*
      if ::lCaptured
         ::nIdReserva := 0     // fjhg 02-04-2013
         ::Refresh()
      else
*---------  fjhg 02-04-2013 Simula tooltip, muestra la info de la cita en vista DIARIA exclusivamente
         if ::Classname() == "TDAYVIEW" .AND. ::oCalex:oCalInfo != NIL
            if ( ::oCalex:oCalInfo:aCoords[ CI_RIGHT ] - ::oCalex:oCalInfo:aCoords[ CI_LEFT ] ) < VIEW_MIN .AND. ::nIdReserva <> ::oCalex:oCalInfo:nIdx
               MsgInfo( "No. Reservación: " + ALLTRIM(STR(::oCalex:oCalInfo:nIdx)) + "     " + ;
                        "A las: " + ::oCalex:ConvertTime(::oCalex:oCalInfo:nStart,::oCalex:lAmPm) + "  -  " + ;
                                    ::oCalex:ConvertTime(::oCalex:oCalInfo:nEnd,::oCalex:lAmPm) + CRLF + ;
                        "Información: " + ::oCalex:oCalInfo:cSubject, "Datos de la Reservación ..." )
               ::nIdReserva := ::oCalex:oCalInfo:nIdx
            endif
         else
            ::nIdReserva := 0
         endif
      endif
  */

return nil //::Super:MouseMove( nRow, nCol, nKeyFlags )


//----------------------------------------------------------------------------//
//adds next ::nInterval to last appnmnt time.  Used to calculate left hourly labels
METHOD NextInterval( nTime ) CLASS TCalEx
   local nMinutes := Val( Right( StrZero( nTime, 4 ), 2 ) )
   local nHour    := ( nTime - nMinutes ) / 100

   nMinutes += ::nInterval
   if nMinutes > 59
      nMinutes = 0
      nHour ++
      if nHour > 23
         nHour = 0
      endif
   endif

   nTime := nHour * 100 + nMinutes

RETURN nTime

//----------------------------------------------------------------------------//


METHOD Paint() CLASS TCalEx

   local aInfo := ::DispBegin()
   local oCalInfo

   ::oView:Paint( ::hDC )

   ::DispEnd( aInfo )

return 0

//----------------------------------------------------------------------------//

METHOD PaintCalInfo( hDC ) CLASS TCalEx

   local oCalInfo
   local aInfo
   local hInfo

   for each hInfo in ::hDays
#ifdef __XHARBOUR__
      hInfo = hInfo:Value
#endif
      for each aInfo in hInfo //oCalInfo in aInfo
#ifdef __XHARBOUR__
         aInfo = aInfo:Value
#endif
         for each oCalInfo in aInfo
            oCalInfo:Paint( hDC )
         next
      next
   next

RETURN NIL


//----------------------------------------------------------------------------//
//called from week and daily view to draw left margin hourly lables
//Horizontal Lines
//
METHOD PaintHorzLinesWithLeftLabels( hDC ) CLASS TCalEx
   local nGridWidth  := ::GridWidth()
   local n, nColStep, nRowStep
   local nTop, nBottom
   local aLabelArea
   local cTime := ""
   local nTime

   nRowStep   = ::nRowHeight

   nTime      = ::nStartHour * 100


   for n = 1 to ::nRowCount

      nTop    = ::nTopMargin + ( n * nRowStep ) - ::nVirtualTop

      //Only paint the visibles rows
      if nTop > 0 .and. nTop < ::nHeight + nRowStep
         if nTime % 100 == 0
            ::Line( hDC, nTop - nRowStep,;
                    ::nLeftMargin,;
                    nTop - nRowStep,;
                    nGridWidth + ::nLeftMargin + ::nLeftLabelWidth,;
                    ::nColorGrid )

         //Show Left label

            aLabelArea = { ::nTopMargin + ( ( n - 1 ) * nRowStep ) - ::nVirtualTop, ;
                           ::nLeftMargin, ::nTopMargin + ( n  * nRowStep ) - ::nVirtualTop, ;
                           ::nLeftLabelWidth - 2 }


	          cTime = ::oCalex:ConvertTime( nTime )
            DrawTextTransparent( hDC, cTime , ;
                             aLabelArea, nOR( DT_SINGLELINE, DT_VCENTER, DT_RIGHT ) )
*---------- Agregado fjhg 03-12-2012 pinte los 30 minutos
         elseif nTime %  100 == 30
            ::Line( hDC, nTop - nRowStep,;
                    ::nLeftMargin + ::nLeftLabelWidth + 1,;
                    nTop - nRowStep,;
                    nGridWidth + ::nLeftMargin + ::nLeftLabelWidth,;
                    ::nColorGrid2 )

            ::Line( hDC, nTop - nRowStep,;
                    ::nLeftMargin + ::nLeftLabelWidth / 2,;
                    nTop - nRowStep,;
                    ::nLeftMargin + ::nLeftLabelWidth - 4,;
                    ::nColorGrid )

            aLabelArea = { ::nTopMargin + ( ( n - 1 ) * nRowStep ) - ::nVirtualTop, ;
                           ::nLeftMargin, ::nTopMargin + ( n  * nRowStep ) - ::nVirtualTop, ;
                           ::nLeftLabelWidth - 2 }


*             cTime = STR( nTime % 100,2 )
             cTime = LEFT( ::oCalex:ConvertTime( nTime ), 5 )
            DrawTextTransparent( hDC, cTime , ;
                             aLabelArea, nOR( DT_SINGLELINE, DT_VCENTER, DT_RIGHT ) )
*---------- fin agregado fjhg 03-12-2012
         else
            ::Line( hDC, nTop - nRowStep,;
                    ::nLeftMargin + ::nLeftLabelWidth + 1,;
                    nTop - nRowStep,;
                    nGridWidth + ::nLeftMargin + ::nLeftLabelWidth,;
                    ::nColorGrid2 )

            ::Line( hDC, nTop - nRowStep,;
                    ::nLeftMargin + ::nLeftLabelWidth / 2,;
                    nTop - nRowStep,;
                    ::nLeftMargin + ::nLeftLabelWidth - 4,;
                    ::nColorGrid )

         endif
         if n = ::nRowCount
           ::Line( hDC, nTop,;
                   ::nLeftMargin,;
                   nTop,;
                   nGridWidth + ::nLeftMargin + ::nLeftLabelWidth,;
                   ::nColorGrid )
         endif
      endif
      nTime := ::NextInterval( nTime )

   next

Return NIL

//----------------------------------------------------------------------------//

METHOD RButtonUp( nRow, nCol, nKeyFlags ) CLASS TCalEx

   local nAtColDown
   local aRet
   local nTime := 0, nTimeDown := 0
   local lLaunch := .F.
   local dFirst, dLast


   if ::oView:IsKindOf( "TMONTHVIEW" )
      return ::oView:RButtonUp( nRow, nCol, nKeyFlags )
   endif

   nAtColDown = ::oView:nColDown

   lLaunch = ::oView:bRSelected != nil

   if lLaunch
      if ! ( lLaunch := ::oView:nRowDown > 0 .and. ::oCalInfoSelected == NIL )
         if ( lLaunch := ::oCalInfoSelected != NIL )
            if ( lLaunch := ::oCalInfo != NIL )
               lLaunch   = ::oCalInfo:nID == ::oCalInfoSelected:nID
               dFirst    = ::oCalInfoSelected:dStart
               dLast     = ::oCalInfoSelected:dEnd
               nTimeDown = ::oCalInfoSelected:nStart
               nTime     = ::oCalInfoSelected:nEnd
            endif
         endif
      else
         dFirst = ::oView:GetFirstDateWeek() + nAtColDown - 1
         dLast  = ::oView:GetFirstDateWeek() + ::oView:nAtCol - 1
         if Len( ::oView:aSelectedRow ) > 0
            nTimeDown := ::oView:GetTimeFromRow( ::oView:aSelectedRow[ 1 ][ 1 ] )
            nTime     := ::oView:GetTimeFromRow( ATail( ::oView:aSelectedRow )[ 1 ] + 1 )
         endif
      endif
   endif

   if lLaunch

      Eval( ::oView:bRSelected, nRow, nCol, ::oView, ;
                         dFirst, ;
                         dLast, ;
                         nTimeDown,;
                         nTime )
      ::Refresh()
   endif

return nil

//----------------------------------------------------------------------------//

METHOD SetDayView( dDate, nInterval )  CLASS TCalEx
   DEFAULT dDate := ::oMonthView:GetDateFromPos( ::oMonthView:aDateSelected[ 1 ], ::oMonthView:aDateSelected[ 2 ] )

   // for compatibility with xharbour
   if dDate == NIL
      dDate = CToD( "  /  /  " )
   endif

   ::oDayView:dDateSelected = dDate
   ::oDayView:dStart        = dDate
   ::oDayView:dEnd          = dDate
   ::oDayView:aSelectedRow  = {}
   ::SetView( ::oDayView )

   DEFAULT nInterval := ::oView:nInterval

   ::oDayView:SetInterval( nInterval )



RETURN NIL

//----------------------------------------------------------------------------//

METHOD SelectCalInfo( oCalInfo ) CLASS TCalEx

   if ::oCalInfoSelected != NIL
      ::oCalInfoSelected:lSelected = .F.
   endif

   ::oCalInfoSelected = ::oCalInfo
   ::oCalInfoSelected:lSelected = .T.

RETURN NIL

//----------------------------------------------------------------------------//
// all data shared
METHOD SetDatas( oView ) CLASS TCalEx

   oView:oCalex            = Self
   oView:nTop              = ::nTop
   oView:nLeft             = ::nLeft
   oView:nBottom           = ::nBottom
   oView:nRight            = ::nRight
   oView:oWnd              = ::oWnd
   oView:hNextItem         = ::hNextItem
   oView:hPrevItem         = ::hPrevItem
   oView:hNextItemo        = ::hNextItemo
   oView:hPrevItemo        = ::hPrevItemo
   oView:nClrText          = ::nClrText
   oView:nStyle            = ::nStyle
   oView:aGradCellNormal   = ::aGradCellNormal
   oView:aGradHeaderCel    = ::aGradHeaderCel
   oView:aGradDifMonth     = ::aGradDifMonth
   oView:aGradCellSelected = ::aGradCellSelected
   oView:aGradHeaderCelDay = ::aGradHeaderCelDay
   oView:aGradLeftLabel    = ::aGradLeftLabel
   oView:aGradHeaderMonth  = ::aGradHeaderMonth
   oView:aGradHeaderWeek   = ::aGradHeaderWeek
   oView:lLeftLabel        = ::lLeftLabel
   oView:lOverPrev         = ::lOverPrev
   oView:lOverNext         = ::lOverNext
   oView:lSBVisible        = ::lSBVisible
   oView:nColorGrid        = ::nColorGrid
   oView:nColorGrid2       = ::nColorGrid2
   oView:nColorCellSelected = ::nColorCellSelected
   oView:nColorGridToday   = ::nColorGridToday
   oView:nDNameHeight      = ::nDNameHeight
   oView:nLeftLabelWidth   = ::nLeftLabelWidth
   oView:nLeftMargin       = ::nLeftMargin
   oView:nRightMargin      = ::nRightMargin
   oView:nBottomMargin     = ::nBottomMargin
   oView:nTopMargin        = ::nTopMargin
   oView:nWeek             = ::nWeek
   oView:oFont             = ::oFont
   oView:oFontHeader       = ::oFontHeader
   oView:oFontTop          = ::oFontTop
   oView:oFontLabel        = ::oFontLabel
   oView:oBrush            = ::oBrush
   oView:hWnd              = ::hWnd
   oView:dDate             = ::dDate
   oView:lActive           = ::lActive
   oView:nStartHour        = ::nStartHour
   oView:nEndHour          = ::nEndHour
   oView:oVScroll          = ::oVScroll
   oView:nBmpRows          = ::nBmpRows   // fjhg

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SetInterval( nMin ) CLASS TCalEx

   local aMin := { 5, 10, 15, 20, 30, 60 }
   local nAt, n

   DEFAULT nMin := 60.00

   if ! ::IsKindOf( "TMONTHVIEW" )
      ::aInterval := { 0 }

      if ::nStartHour >= ::nEndHour
         ::nEndHour = 24
      endif

      nAt := AScan( aMin, {| n | nMin <= n } )

      if nAt > 0
         nMin = aMin[ nAt ]
      else
         nMin = 60.00
      endif

      ::nInterval := nMin
*      ::nRowCount := ( ::nEndHour - ::nStartHour - If( ::nInterval == 60, 0 , 1 ) ) / ( ::nInterval / 60 )
      ::nRowCount := ( ( ::nEndHour + 1 ) - ::nStartHour - If( ::nInterval == 60, 0 , 1 ) ) / ( ::nInterval / 60 )   // fjhg porque quitaba 1 hora
      ::CheckScroll()

      for n = 1 to 60 / nMin - 1
         AAdd( ::aInterval, Int( n * ::nInterval ) )
      next
      ::BuildDates()

   endif

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SetScroll() CLASS TCalEx

   ::oVScroll:bGoUp     = {|| ::VScrollSkip( - ::nRowHeight ) }
   ::oVScroll:bGoDown   = {|| ::VScrollSkip( ::nRowHeight ) }
   ::oVScroll:bPageUp   = {|| ::VScrollSkip( - ::oCalex:oView:oVScroll:nPgStep ) }
   ::oVScroll:bPageDown = {|| ::VScrollSkip( ::oCalex:oView:oVScroll:nPgStep ) }
   ::oVScroll:bPos      = {|nPos| ::VScrollSetPos( nPos ) }
   ::oVScroll:bTrack    = {|nPos| ::VScrollSetPos( nPos ) }

return nil


//----------------------------------------------------------------------------//

METHOD SetView( o ) CLASS TCalEx

   local oLastView := ::oView

   local oCalInfo


   if ::oView != NIL
      ::oView:lActive = ! ::oView:lActive
   endif

   o:oVScroll = ::oVScroll
   ::oView := o

   ::oView:lActive = .T.
   if ::oView:IsKindOf( "TMONTHVIEW" )
      ::oView:CheckScroll()
   endif
   ::oView:dDate = o:dDate

   hb_HEVAL( ::hCalInfo, {| k, v, i | v := NIl } )

   ::Reset()

   if ::oView:bSelectView != NIL
      Eval( ::oView:bSelectView, o, oLastView ) // Last View Selected
   endif

   // only set the BuildDates in Month View
   // because in other view is setted in SetInterval
   if ::oView:IsKindOf( "TMONTHVIEW" )
      ::oView:BuildDates()
   endif

   ::oView:SetScroll()

   ::Refresh()



RETURN NIL

//----------------------------------------------------------------------------//

METHOD SetWeekView( dDate, nInterval )  CLASS TCalEx
   DEFAULT dDate := ::oMonthView:GetDateFromPos( ::oMonthView:aDateSelected[ 1 ], ::oMonthView:aDateSelected[ 2 ] )

   DEFAULT nInterval := ::oWeekView:nInterval


   // for compatibility with xharbour
   if dDate == NIL
      dDate = CToD( "  /  /  " )
   endif

   ::oWeekView:dStart = ::GetFirstDateWeek( dDate ) //dDate - DoW( dDate ) + 1
   ::oWeekView:dEnd   = ::oWeekView:dStart + 6

   ::oWeekView:dDateSelected = dDate
   ::oWeekView:aSelectedRow  = {}

   ::SetView( ::oWeekView )

   ::oWeekView:SetInterval( nInterval )


RETURN NIL


//----------------------------------------------------------------------------//
// oCalInfo current object to Verify
// oTempCal oCalInfo objects above created
//----------------------------------------------------------------------------//

METHOD VerifyPos( oCalInfo, oLast ) CLASS TCalEx

   local hInfo
   local aTempInfo
   local oTempCal
   locaL nColStep := Int( ::GridWidth() / ::nDays )
   local nModCol  := ::GridWidth() % ::nDays - 1
   local nAdjCol, nPosCol := 0
   local aCoor    := { NIL, NIL }
   local nTot
   local nDays, nInfo, nTempInfo
   local cStrDay, cStrInterval, lRet := .T.

   static nMaxRow := 0
   static nTopRow := 0

   // first ocalinfo in date
   if oCalInfo == NIL .and. oLast == NIL
      nMaxRow = 0
      nTopRow = 0
      return nil
   endif

   cStrDay = DToS( oCalInfo:dStart )
   hInfo = hb_HGET( ::hDays, cStrDay )
   if nMaxRow == 0
      nMaxRow = oLast:aCoords[ CI_BOTTOM ]
      nTopRow = oLast:aCoords[ CI_TOP ]
   endif

   aCoor[ 1 ] = ::GetCoorFromTime( oCalInfo:nStart, oCalInfo:dStart )
   aCoor[ 2 ] = ::GetCoorFromTime( oCalInfo:nEnd, oCalInfo:dStart )

   if aCoor[ 1 ][ 1 ] < nMaxRow
      if ! ( aCoor[ 1 ][ 1 ] < oLast:aCoords[ CI_BOTTOM ] )
         oCalInfo:BuildDates( aCoor[ 1 ][ 1 ], ;
                              oLast:aCoords[ CI_LEFT ] + 1, ;
                              oLast:aCoords[ CI_RIGHT ] - oLast:aCoords[ CI_LEFT ],;// + If( oCalInfo:dStart == dLastDateWeek, nModCol, 0 ),;
                              Max( ::nRowHeight, aCoor[ 2 ][ 1 ] - aCoor[ 1 ][ 1 ] ) + 1, ::oCalex, nColStep )
         oCalInfo:nFlags = FLAGS_DOWN
         if oCalInfo:aCoords[ CI_BOTTOM ] > nMaxRow
            nMaxRow = oCalInfo:aCoords[ CI_BOTTOM ]
         endif
      else
         nTot := Int( nColStep / ( oLast:aCoords[ CI_RIGHT ] - oLast:aCoords[ CI_LEFT ] ) ) + 1
         nAdjCol = nColStep / nTot

         oCalInfo:BuildDates( aCoor[ 1 ][ 1 ], ;
                              aCoor[ 1 ][ 2 ] + nAdjCol * ( nTot - 1 ), ;
                              nAdjCol,;// + If( oCalInfo:dStart == dLastDateWeek, nModCol, 0 ),;
                              Max( ::nRowHeight, aCoor[ 2 ][ 1 ] - aCoor[ 1 ][ 1 ] ) + 1, ::oCalex, nColStep )
         if oCalInfo:aCoords[ CI_BOTTOM ] > nMaxRow
            nMaxRow = oCalInfo:aCoords[ CI_BOTTOM ]
         endif
         oCalInfo:nFlags = FLAGS_RIGHT
      endif
   else
      oCalInfo:BuildDates( aCoor[ 1 ][ 1 ], ;
                           aCoor[ 1 ][ 2 ], ;
                           nColStep,;// + If( oCalInfo:dStart == dLastDateWeek, nModCol, 0 ),;
                           Max( ::nRowHeight, aCoor[ 2 ][ 1 ] - aCoor[ 1 ][ 1 ] ) + 1, ::oCalex, nColStep )
      nTopRow = oCalInfo:aCoords[ CI_TOP ]
      nMaxRow = oCalInfo:aCoords[ CI_BOTTOM ]
      oCalInfo:nFlags = FLAGS_START
      //oLast:nFlags = nOR( oLast:nFlags, FLAGS_END )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD VScrollSetPos( nPos ) CLASS TCalEx

   local nSkip := nPos - ::nVirtualTop

   ::nVirtualTop := nPos
   ::oVScroll:SetPos( nPos )

   ::Refresh()

   ::MoveCalInfo( nSkip )


RETURN nil

//----------------------------------------------------------------------------//

METHOD VScrollSkip( nSkip ) CLASS TCalEx

   local nHeight := ( ::nVirtualHeight - ::nHeight )
   local nAux

   IF (::nVirtualTop == 0 .And. nSkip < 0) .Or. ;
      (::nVirtualTop == nHeight .And. nSkip > 0)
      RETURN nil
   ENDIF

   nAux = ::nVirtualTop
   ::nVirtualTop += nSkip

   ::nVirtualTop = Min( ::nVirtualHeight - ::nHeight, ::nVirtualTop )

   IF ::nVirtualTop < 0
      ::nVirtualTop := 0
   ELSEIF ::nVirtualTop > nHeight
      ::nVirtualTop := nHeight
   ENDIF
   ::oVScroll:SetPos( ::nVirtualTop )

   ::Refresh()

   if nAux - ::nVirtualTop != -nSkip
      nSkip = -( nAux - ::nVirtualTop )
   endif

   ::MoveCalInfo( nSkip )

RETURN nil

//----------------------------------------------------------------------------//

METHOD ConvertTime( nTime, l24 ) CLASS TCalEx

   local cTime
   local nHour, nMinutes
   local nAdj := 0

   DEFAULT l24 := .F.

   if ! l24
      if nTime > 1259 // 12:59 pm
         nAdj = 1200
      endif
      nHour    := Int( ( nTime - nAdj ) / 100 )
      nMinutes = ( nTime - nAdj ) - ( nHour * 100 )
      cTime    = Str( nHour, 2 ) + ":" + StrZero( nMinutes, 2 ) + " " + If( nTime > 1159, "pm", "am" )
   else
      nMinutes = If( nTime  == 0, 0, Val( Right( StrZero( nTime, 4 ), 2 ) ) )
      nHour    = If( nTime  == 0, 0, ( nTime - nMinutes ) / 100 )
      cTime    = Str( nHour, 2 ) + ":" + StrZero( nMinutes, 2 )
   endif

return cTime

//----------------------------------------------------------------------------//

FUNCTION DrawBox( hDC, aRect, nAdj )
   local aPoints
   DEFAULT nAdj := 0

   aPoints := { { aRect[ 2 ], aRect[ 1 ] },; //start
   	            { aRect[ 4 ], aRect[ 1 ] },; //top
   	            { aRect[ 4 ], aRect[ 3 ] },; //right
   	            { aRect[ 2 ], aRect[ 3 ] },; //Bottom
   	            { aRect[ 2 ], aRect[ 1 ] - nAdj } } //left

   PolyLine(  hDC,  aPoints )

return nil

//----------------------------------------------------------------------------//

FUNCTION DrawSpecialBox( hDC, aRect, nAdj )
   local aPoints
   DEFAULT nAdj := 0

   aPoints := { { aRect[ 2 ], aRect[ 1 ] },; //start
                { aRect[ 4 ], aRect[ 1 ] },; //top
                { aRect[ 4 ], aRect[ 3 ] },; //right
                { aRect[ 2 ] + 10, aRect[ 3 ] },; //Bottom      // fjhg ajustes 10-10-2012
                { aRect[ 2 ] + 10, aRect[ 1 ] + 10 },;
                { aRect[ 2 ], aRect[ 1 ] + 10 },;
                { aRect[ 2 ], aRect[ 1 ] - nAdj } } //left

   PolyLine(  hDC,  aPoints )

return nil

//----------------------------------------------------------------------------//

FUNCTION Calex_SetFirstDate( nFirst )

   local nOldValue

   static nFirstDate := 0

   nOldValue = nFirstDate

   if PCount() > 0
      nFirstDate = Min( Max( 1, nFirst ), 7 ) - 1
   endif

return nOldValue

//----------------------------------------------------------------------------//

METHOD KeyDown( nKey, nFlags ) CLASS TCalEx
Local oCalInf
Local dDato

   do case
      case ::oView:IsKindOf("TMONTHVIEW")
         do case
            case nKey == VK_RETURN
                 ::SetDayView()
            case nKey == VK_UP
                 if ::oMonthView:aDateSelected[ 1 ] = 1
                    ::oMonthView:aDateSelected[ 1 ] := 5
                    ::oMonthView:dDateSelected := ::oMonthView:dDateSelected - 28
                 else
                    ::oMonthView:aDateSelected[ 1 ]--
                    ::oMonthView:dDateSelected := ::oMonthView:dDateSelected - 7
                 endif
                 ::dDateSelected := ::oMonthView:dDateSelected
                 ::Refresh()

            case nKey == VK_DOWN
                 if ::oMonthView:aDateSelected[ 1 ] = 5         // Ojo, màximo numero filas
                    ::oMonthView:aDateSelected[ 1 ] := 1
                    ::oMonthView:dDateSelected := ::oMonthView:dDateSelected + 28
                 else
                    ::oMonthView:aDateSelected[ 1 ]++
                    ::oMonthView:dDateSelected := ::oMonthView:dDateSelected + 7
                 endif
                 ::dDateSelected := ::oMonthView:dDateSelected
                 ::Refresh()

            case nKey == VK_LEFT

                 if ::oMonthView:aDateSelected[ 2 ] = 1
                    // Crear Data para ir a Mes anterior o...
                    ::oMonthView:aDateSelected[ 2 ] := 7
                    ::oMonthView:dDateSelected := ::oMonthView:dDateSelected + 6
                 else
                    ::oMonthView:aDateSelected[ 2 ]--
                    ::oMonthView:dDateSelected--
                 endif
                 ::dDateSelected := ::oMonthView:dDateSelected
                 ::Refresh()


            case nKey == VK_RIGHT
                 if ::oMonthView:aDateSelected[ 2 ] = 7
                    // Crear Data para ir a Mes siguiente o...
                    ::oMonthView:aDateSelected[ 2 ] := 1
                    ::oMonthView:dDateSelected := ::oMonthView:dDateSelected - 6
                 else
                    ::oMonthView:aDateSelected[ 2 ]++
                    ::oMonthView:dDateSelected++
                 endif
                 ::dDateSelected := ::oMonthView:dDateSelected
                 ::Refresh()



            otherwise
                 return ::Super:KeyDown( nKey, nFlags )
         endcase
      case ::oView:IsKindOf("TWEEKVIEW")

         // Ver setDate en esta clase Week y en la anterior Month
         //::oWeekView:aDateSelected := { ::oWeekView:nRowDown, ::oWeekView:nColDown }

         do case
            case nKey == VK_RETURN
                 ::SetDayView()
            case nKey == VK_UP


            case nKey == VK_DOWN

            case nKey == VK_LEFT
                 if ::oWeekView:nColDown = 1
                    ::oWeekView:nColDown := 7
                    ::oWeekView:dDateSelected := ::oWeekView:dDateSelected + 6
                 else
                    ::oWeekView:dDateSelected--
                    ::oWeekView:nColDown--
                 endif
                 ::oWeekView:Refresh()

            case nKey == VK_RIGHT
                 //? ::oWeekView:nAtRow , ::oWeekView:nAtCol
                 //? ::oWeekView:nRowDown, ::oWeekView:nColDown
                 //? ::oWeekView:nRowCount
                 //? ::oWeekView:nLastRow, ::oWeekView:nLastCol
                 //? ::oWeekView:aDateSelected[1], ::oWeekView:aDateSelected[2]

                 //? ::dDateSelected, ::oMonthView:dDateSelected , ::oWeekView:dDateSelected, ::oWeekView:oCalex:dDate
                 /*
                 if ::oWeekView:nColDown = 7
                    ::oWeekView:nColDown := 1
                    ::oWeekView:dDateSelected := ::oWeekView:dDateSelected - 6
                 else
                    ::oWeekView:dDateSelected++
                    ::oWeekView:nColDown++
                 endif
                 ::oWeekView:Refresh()
                 */

            otherwise
                 return ::Super:KeyDown( nKey, nFlags )
         endcase

      case ::oView:IsKindOf("TDAYVIEW")
           do case
               case nKey == VK_UP
                    IF ::oDayView:nRowDown > 1
                       ::oDayView:aSelectedRow:= {}
                       ::oDayView:nRowDown-= 1.0001
                       AAdd( ::oDayView:aSelectedRow, { ::oDayView:nRowDown, ::oDayView:nColDown } )
                       ::Refresh()
                    ENDIF
                    *
               case nKey == VK_DOWN
                    IF ::oDayView:nRowDown < ::oDayView:nRowCount
                       ::oDayView:aSelectedRow:= {}
                       ::oDayView:nRowDown+= 1.0001
                       AAdd( ::oDayView:aSelectedRow, {::oDayView:nRowDown , ::oDayView:nColDown } )
                       ::Refresh()
                    ENDIF
                    *
               case nKey == VK_PRIOR 
                      *
                      ::oDayView:GoNext()
                      *
               case nKey == VK_NEXT 
                      *
                      ::oDayView:GoPrev()
                      *
            endcase
         

   endcase

return 0

// Apuntes del Metodo Keydown
                 //
                 //? ::oMonthView:GetPosFromDate( ::dDate )[1], ::oMonthView:GetPosFromDate( ::dDate )[2]
                 //? ::oMonthView:dDateSelected, ::oMonthView:dDate
                 //? ::oMonthView:nAtRow, ::oMonthView:nAtCol
                 //? ::oMonthView:aDateSelected[1], ::oMonthView:aDateSelected[2]
                 //? ::nAtRow, ::nAtCol
                 //
                 /*
                 ::oMonthView:nAtRow  := ::oMonthView:GetPosFromDate( ::oMonthView:dDate )[1]
                 ::oMonthView:nAtCol  := ::oMonthView:GetPosFromDate( ::oMonthView:dDate )[2]
                 if ::oMonthView:nAtRow = 7
                    ::oMonthView:nAtRow := 1
                 else
                    ::oMonthView:nAtRow++
                 endif
                 */
                 //? ::oMonthView:GetPosFromDate( oView:dDateSelected )[1]
                 //? ::oMonthView:GetPosFromDate( oView:dDateSelected )[2]
                 //? ::oMonthView:nAtRow, ::oMonthView:nAtCol
                 /*
                 cDate = DToS( dDate )

                 if( hb_HHASKEY( ::hDays, cDate ) )
                     aInfo = hb_HGET( ::hDays, cDate )
                     for each oCalInfo in aInfo
                         if oCalInfo:aCoords[ CI_TOP ] < nRow .and. oCalInfo:aCoords[ CI_BOTTOM ] > nRow ;
                            .and. oCalInfo:aCoords[ CI_LEFT ] < nCol .and. oCalInfo:aCoords[ CI_RIGHT ] > nCol
                            oCalInfo:lSelected           = .T.
                            ::oCalex:oCalInfo            = oCalInfo
                         endif
                     next
                 endif
                 */
                 /*
                 //? Valtype( ::oCalInfo ), Valtype( ::oCalInfoSelected )
                 //? Valtype( ::hDays )
                 //                   O                    H                     0
                 //? Valtype( ::oMonthView:oCalex ), Valtype( ::hCalInfo ), Len( ::hCalInfo )
                 ? Valtype( ::oMonthView:oCalex ), Valtype( ::oMonthView:hDays ), Len( ::oMonthview:hDays )
                 ? Valtype( ::oMonthView:aDateSelected ), ::oMonthView:aDateSelected[1], ::oMonthView:aDateSelected[2]
                 ? hb_HHASKEY( ::oMonthView:hDays , DTos( dDato ) )
                 //? hb_HVALUEAT( ::oMonthView:hDays , 1 )[1]    ---> Devuelve TCALINFO
                 ? Valtype( hb_HVALUEAT(::oMonthView:hDays , 1 )[1] )
                 oCalinf := hb_HVALUEAT(::oMonthView:hDays , 1 )[1]
                 //? Valtype( ::oMonthView:hCalInfo )//, Len( ::oMonthview:hCalInfo )
                 //? hb_HHASKEY( ::oMonthView:hCalinfoSelected , oCalInf )
                 ? oCalInf:lSelected, oCalInf:dStart
                 */
                 //::oMonthView:lSelected = .F.
                 //::oMonthView:oCalInf:Refresh()
                 //dDato := ::oMonthView:GetDateFromPos( ::oMonthView:aDateSelected[ 1 ], ::oMonthView:aDateSelected[ 2 ] )
                 //? dDato, ::oMonthView:aDateSelected[ 1 ], ::oMonthView:nAtRow, ::oMonthView:nAtCol


//---------------------------------------------------------------------------//
//---------------------------------------------------------------------------//
