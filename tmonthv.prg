//TMonthV.prg

#include "fivewin.ch"
#include "calex.ch"
#include "InKey.ch"


CLASS TMonthView FROM TCalex

   DATA oCalex
   DATA nWks                          // Total week in month
   DATA nInfoHeight

   METHOD New()

   METHOD BuildDates()

   METHOD CheckChildren() VIRTUAL
   METHOD CheckScroll() INLINE SetScrollRangeX( ::hWnd, 1, 0, 0 )

   METHOD GetCoorFromPos( nAtRow, nAtCol )
   METHOD GetStrInterval( nStart ) VIRTUAL
   METHOD GetPosition ( nRow, nCol )
   METHOD GetDateFromPos( nAtRow, nAtCol ) INLINE ::dStart + ( ( nAtRow - 1 ) * 7 ) + nAtCol - 1

   METHOD GetPosFromDate( dDate )
   METHOD GoNextMonth()
   METHOD GoPrevMonth()

   //METHOD KeyDown( nKey, nFlags )

   METHOD HitTest( nRow, nCol ) VIRTUAL

   METHOD LButtonDown( nRow, nCol, nKeyFlags )
   METHOD LButtonUp( nRow, nCol, nKeyFlags )
   METHOD LDblClick( nRow, nCol, nKeyFlags ) INLINE ::oCalex:SetDayView()

   METHOD MouseMove( nRow, nCol, nKeyFlags )
   METHOD MoveCalInfo() VIRTUAL

   METHOD Paint( hDC )
   METHOD PaintCalInfo( hDC )
   METHOD PaintCell( hDC, nRow, nCol )
   METHOD PaintHeader( hDC )

   METHOD RButtonUp( nRow, nCol, nKeyFlags ) VIRTUAL
   METHOD Refresh() INLINE ::oCalex:Refresh()

   METHOD Resize( nType, nWidth, nHeight )
   METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos ) VIRTUAL

   METHOD SetDate( dDate )
   METHOD SetInterval() VIRTUAL
   METHOD SetLabels()


ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oCalex ) CLASS TMonthView

   oCalex:SetDatas( Self )

   ::nInfoHeight = 20

   ::SetDate( oCalex:dDate )
   ::nStartHour = 0
   ::nEndHour   = 24
   ::nVirtualTop = 0

   ::GetPosFromDate( oCalex:dDate )             // Añadido Cnl 28/03/2013 [¿?]



RETURN Self

//----------------------------------------------------------------------------//

METHOD BuildDates() CLASS TMonthView

   local oCalInfo, oCal
   local cStrDay, aInfo
   local aPos, aCoor
   local nAdj, n
   local lMore := .F.

   ::hDays = hb_HASH()

   //fill and sort dates by day
   for each oCalInfo in ::oCalex:hCalInfo
      aInfo = {}
#ifdef __XHARBOUR__
      oCalInfo = oCalInfo:Value
#endif

      if oCalInfo:dStart >= ::dStart .and. oCalInfo:dStart <= ::dEnd
         cStrDay = DToS( oCalInfo:dStart )
         if hb_HHASKEY( ::hDays, cStrDay )
            aInfo = hb_HGET( ::hDays, cStrDay )
         endif

         AAdd( aInfo, oCalInfo )
         ASort( aInfo, , ,{| o1, o2 | o1:nStart < o2:nStart } )
         hb_HSET( ::hDays, cStrDay, aInfo )
      endif

   next

      for each aInfo in ::hDays
#ifdef __XHARBOUR__
         aInfo = aInfo:Value
#endif
      nAdj = ::nDNameHeight

      if Len( aInfo ) > 0
         aPos  = ::GetPosFromDate( aInfo[ 1 ]:dStart )
         aCoor = ::GetCoorFromPos( aPos[ 1 ] , aPos[ 2 ] )
      endif
      for each oCalInfo in aInfo
         oCalInfo:BuildDates( aCoor[ 1 ] + nAdj + 2, ;
                              aCoor[ 2 ] + 10, ;
                              aCoor[ 3 ] - 20, ;
                              ::nInfoHeight, ::oCalex )
         nAdj += ::nDNameHeight + 2
         if nAdj + ::nInfoHeight > aCoor[ 4 ]
            oCalInfo:Hide()
         endif
      next
   next

RETURN NIL

//----------------------------------------------------------------------------//

METHOD GetCoorFromPos( nAtRow, nAtCol ) CLASS TMonthView

   local aCoor       := Array( 4 )
   local nColStep, nRowStep
   local nModCol, nModRow
   local nGridWidth  := ::GridWidth()
   local nGridHeight := ::GridHeight()
   local nAdjRow     := 2


   nColStep = Int( nGridWidth / 7 )
   nModCol  = nGridWidth % 7

   nRowStep = Int( ( nGridHeight - ::nTopMargin ) / ::nWks )
   nModRow  = ( nGridHeight - ::nTopMargin ) % ::nWks

   aCoor[ 1 ] = ::nTopMargin + 1 + If( nAtRow > 1, ( nRowStep * ( nAtRow - 1 ) ), 0 )
   aCoor[ 2 ] = ::nLeftLabelWidth + ( nColStep * ( nAtCol - 1 ) ) + 3
   aCoor[ 3 ] = nColStep - 1 + If( nAtCol == 7, nModCol, 0 )
   aCoor[ 4 ] = Max( nRowStep - nAdjRow, ::nDNameHeight ) + If( nAtRow == ::nWks, nModRow, 0 )

RETURN aCoor


//----------------------------------------------------------------------------//

METHOD GetPosition( nRow, nCol ) CLASS TMonthView

   local nAtCol := 0, nAtRow := 0
   local nLMar := ::nLeftMargin + ::nLeftLabelWidth
   local nTMar := ::nTopMargin
   local nGridWidth  := ::GridWidth()
   local nGridHeight := ::GridHeight()
   local nColStep, nRowStep
   local nModCol

   nColStep = Int( nGridWidth / 7 )
   nModCol = nGridWidth % 7

   nRowStep = Int( ( nGridHeight - ::nTopMargin ) / ::nWks )

   if nCol > nLMar
      nAtCol = Min( Int( ( nCol - nLMar ) / nColStep ) + 1, 7 )
   endif

   if nRow > nTMar .and. nRow < nGridHeight + nTMar
      nAtRow = Int( ( nRow - nTMar ) / nRowStep ) + 1
   endif

return { nAtRow, nAtCol }

//----------------------------------------------------------------------------//

METHOD GetPosFromDate( dDate ) CLASS TMonthView

   local nMod, aPos := { 0, 0 }

   if dDate >= ::dStart .and. dDate <= ::dEnd

      if ( nMod := Mod( ( dDate - ::dStart + 1 ), 7 ) ) > 0
         aPos = { Int( ( dDate - ::dStart + 1 ) / 7 ) + 1, nMod }
      else
         aPos = { Int( ( dDate - ::dStart + 1 ) / 7 ), 7 }
      endif

      ::nAtRow  := aPos[ 1 ]
      ::nAtCol  := aPos[ 1 ]

   endif

return aPos

//----------------------------------------------------------------------------//

METHOD GoNextMonth() CLASS TMonthView

   local nMonth, nDay, nYear, dDate

   nMonth := Month( ::dDate )
   nDay   := 1
   nYear  := Year( ::dDate )
   if nMonth == 12
      nMonth := 1
      nYear++
   else
      nMonth++
   endif
   dDate := SToD( StrZero( nYear, 4 ) + StrZero( nMonth, 2 ) + StrZero( nDay, 2 ) )

return dDate

//----------------------------------------------------------------------------//

METHOD GoPrevMonth() CLASS TMonthView

   local nMonth, nDay, nYear, dDate

   nMonth := Month( ::dDate )
   nDay   := 1 //Day( ::dDate )
   nYear  := Year( ::dDate )
   if nMonth == 1
      nMonth := 12
      nYear--
   else
      nMonth--
   endif

   dDate := SToD( StrZero( nYear, 4 ) + StrZero( nMonth, 2 ) + StrZero( nDay, 2 ) )

   do while( Empty( DToS( dDate ) ) )
      dDate := SToD( StrZero( nYear, 4 ) + StrZero( nMonth, 2 ) + StrZero( --nDay, 2 ) )
   enddo

return dDate

//----------------------------------------------------------------------------//

METHOD LButtonDown( nRow, nCol, nKeyFlags ) CLASS TMonthView

   local dDate
   local cDate
   local oCalInfo
   local aInfo


   ::aDateSelected = ::GetPosition( nRow, nCol )
   dDate := ::GetDateFromPos( ::aDateSelected[ 1 ], ::aDateSelected[ 2 ] )
   ::nBtnPushed := If( ::lOverPrev, PUSHEDPREV, If( ::lOverNext, PUSHEDNEXT, 0 ) )

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

return nil


//----------------------------------------------------------------------------//

METHOD LButtonUp( nRow, nCol, nKeyFlags ) CLASS TMonthView

   local nPushed := If( ::lOverPrev, PUSHEDPREV, If( ::lOverNext, PUSHEDNEXT, 0 ) )
   local dDateTemp
   local aInfo, oCalInfo

   dDateTemp = ::GetDateFromPos( ::aDateSelected[ 1 ], ::aDateSelected[ 2 ] )
   if ::aDateSelected[ 1 ] > 0 .and. ::aDateSelected[ 2 ] > 0 .and. nPushed == 0
      dDateTemp = ::GetDateFromPos( ::aDateSelected[ 1 ], ::aDateSelected[ 2 ] )
      ::dDateSelected = dDateTemp
      if ::bSelected != NIL
         Eval( ::bSelected, Self, dDateTemp )
      endif
   elseif ::nWeek > 0 .and. ::lLeftLabel
      ::dDateSelected = dDateTemp + 1
      if ::oCalex:oWeekView != NIL
         ::oCalex:SetWeekView()
         ::oCalex:oView:dDateSelected = ::dDateSelected
      endif
      if ::bSelectedWeek != NIL
         Eval( ::bSelectedWeek, Self, ::nWeek, dDateTemp + 1 ) //Self, Week, First Day week
      endif
   elseif nPushed == ::nBtnPushed
      if nPushed == PUSHEDPREV
         dDateTemp := ::GoPrevMonth()
         ::dDateSelected = dDateTemp
         ::SetDate( dDateTemp )
         if ::bOnPrev != NIL
            Eval( ::bOnPrev, Self, dDateTemp )
         endif
         ::BuildDates()
         ::Refresh()
      elseif nPushed == PUSHEDNEXT
         dDateTemp = ::GoNextMonth()
         ::dDateSelected = dDateTemp
         ::SetDate( dDateTemp )
         if ::bOnNext != NIL
            Eval( ::bOnNext, Self, dDateTemp )
         endif
         ::BuildDates()
         ::Refresh()
      endif
   endif

return nil


//-----------------------------------------------------------------//

METHOD MouseMove( nRow, nCol, nKeyFlags ) CLASS TMonthView

   local aPos := ::GetPosition( nRow, nCol )

   ::nAtRow = aPos[ 1 ]
   ::nAtCol = aPos[ 2 ]

   if aPos[ 1 ] > 0 .and. aPos[ 2 ] == 0
      ::nWeek = aPos[ 1 ]
   else
      ::nWeek = 0
      ::CheckOverPrev( nRow, nCol )
      ::Refresh()
   endif

return nil //Super:MouseMove( nRow, nCol, nKeyFlags )  //nil


//----------------------------------------------------------------------------//


METHOD Paint( hDC ) CLASS TMonthView

   local cDay, nDay, n, j, dDate, nColStep, nRowStep
   local dTmpDate, nMonth := 0, nLeftCol := 0
   local nGridWidth := ::GridWidth()
   local nGridHeight := ::GridHeight()
   local nModRow, nModCol, nTextWidth, nTextHeight
   local nAdjRow := 2
   local hOldFont, nOldClr
   local aLabelArea
   local cLabel, hNext, hPrev
   local cTop, aCoor


   FillRect( hDC, GetClientRect( ::hWnd ), ::oBrush:hBrush )

   WndBox2007( hDC, ::nTopMargin - (GetTextHeight() + 9),;    // fjhg + 9 para que complete el pintado del cuadro superior del dia de la semana
               ::nLeftMargin + ::nLeftLabelWidth, ;
               nGridHeight, ;
               nGridWidth + ( ::nLeftMargin + ::nLeftLabelWidth ), ;
               ::nColorGrid )

   nColStep = Int( nGridWidth / 7 )
   nModCol = nGridWidth % 7

   //Vertical lines
   for n = 1 to 6
      ::Line( hDC, ::nTopMargin - (::nDNameHeight + 5),;    // fjhg + 2 completa linea hasta el cuadro superior del dia de la semana
              ::nLeftMargin + ::nLeftLabelWidth + ( n * nColStep ),;
              nGridHeight,;
              ::nLeftMargin + ::nLeftLabelWidth + ( n * nColStep ),;
              ::nColorGrid )
   next

   nRowStep = Int( ( nGridHeight - ::nTopMargin ) / ::nWks )
   nModRow = ( nGridHeight - ::nTopMargin ) % ::nWks
   ::Line( hDC, ::nTopMargin + ::nDNameHeight,;
           ::nLeftMargin + ::nLeftLabelWidth,;
           ::nTopMargin + ::nDNameHeight,;
           nGridWidth + ::nLeftMargin + ::nLeftLabelWidth,;
           ::nColorGrid )

   //Horizontal Lines

   for n = 1 to ::nWks - 1
      ::Line( hDC, ::nTopMargin + ( n * nRowStep ),;
              ::nLeftMargin + ::nLeftLabelWidth,;
              ::nTopMargin + ( n * nRowStep ),;
              nGridWidth + ::nLeftMargin + ::nLeftLabelWidth,;
              ::nColorGrid )
   next

   for n = 1 to ::nWks //Row
      for j = 1 to 7 //Columns
         ::PaintCell( hDC, n, j, ::GetCoorFromPos( n, j ) )
      next

   next

   ::PaintHeader( hDC )

   // Paint Left Label
   if ::lLeftLabel
      for n = 1 to ::nWks
         cLabel = ::aLabelText[ n ]
         aCoor = ::GetCoorFromPos( n, 1 )
         aLabelArea = { aCoor[ 1 ] + ::nDNameHeight,;
                          ::nLeftMargin, ;
                          aCoor[ 4 ] + aCoor[ 1 ], ;
                          ::nLeftMargin + ::nLeftLabelWidth }

         GradientFill( hDC, aLabelArea[ 1 ], aLabelArea[ 2 ], aLabelArea[ 3 ], aLabelArea[ 4 ], ::aGradLeftLabel )   // ::aGradCellSelected ) fjhg

         WndBox2007( hDC, aLabelArea[ 1 ], aLabelArea[ 2 ], aLabelArea[ 3 ], aLabelArea[ 4 ], ::nColorGrid )

         hOldFont = SelectObject( hDC, ::oFontLabel:hFont )
         nTextWidth = GetTextWidth( hDC, cLabel, ::oFontLabel:hFont )
         nTextHeight = GetTextHeight()
         DrawTextTransparent( hDC, cLabel , ;
                              { aLabelArea[ 1 ],;
                                aLabelArea[ 2 ],;
                                aLabelArea[ 3 ] + nTextWidth + nTextHeight,;
                                aLabelArea[ 4 ] + nTextWidth - nTextHeight }, nOR( DT_SINGLELINE, DT_VCENTER, DT_CENTER ) )
         SelectObject( hDC, hOldFont )

      next
   endif

   if ::lOverNext
      hNext = ::hNextItemo
   else
      hNext = ::hNextItem
   endif

   if ::lOverPrev
      hPrev = ::hPrevItemo
   else
      hPrev = ::hPrevItem
   endif

   DrawTransparent( hDC, hNext, ROWITEM - ::nBmpRows, COLNEXT )   // fjhg

   DrawTransparent( hDC, hPrev, ROWITEM - ::nBmpRows, COLPREV )   // fjhg

   cTop = CMonth( ::dDate ) + " " + Str( Year( ::dDate ) )
   hOldFont = SelectObject( hDC, ::oFontTop:hFont )
   nOldClr  = SetTextColor( hDC, ::nClrText )
   DrawTextTransparent( hDC, cTop, ;
                       { 1, COLNEXT + BMPITEMW + 10, ROWITEM + GetTextHeight(), ::nWidth }, nOR( DT_SINGLELINE, DT_VCENTER ) )
   SelectObject( hDC, hOldFont )
   SetTextColor( hDC, nOldClr )

   ::PaintCalInfo( hDC )

return 0

//----------------------------------------------------------------------------//

METHOD PaintCalInfo( hDC ) CLASS TMonthView

   local oCalInfo
   local aInfo

   for each aInfo in ::hDays//::oCalex:hCalInfo
#ifdef __XHARBOUR__
      aInfo = aInfo:Value
#endif
      for each oCalInfo in aInfo
         if oCalInfo:lCreated
            oCalInfo:Paint( hDC )
         endif
      next
   next

RETURN NIL

//----------------------------------------------------------------------------//

METHOD PaintCell( hDC, nRow, nCol, aCellCoor ) CLASS TMonthView

   local aDataArea
   local aHeadArea
   local dNextDay
   local cText, hOldFont
   local aGradHead, aGradCel
   local nOldClr


   aDataArea = { aCellCoor[ 1 ] + ::nDNameHeight,;
                 aCellCoor[ 2 ],;
                 aCellCoor[ 4 ] + aCellCoor[ 1 ] ,;
                 aCellCoor[ 3 ] + aCellCoor[ 2 ] }

   aHeadArea = { aCellCoor[ 1 ],;
                 aCellCoor[ 2 ],;
                 aCellCoor[ 1 ] + ::nDNameHeight - 1,;
                 aCellCoor[ 3 ] + aCellCoor[ 2 ] }


   if ::aDateSelected[ 1 ] == nRow .and. ::aDateSelected[ 2 ] == nCol
      aGradCel = ::aGradCellSelected
   else
      if Month( ::GetDateFromPos( nRow, nCol ) ) != Month( ::dDate )
         aGradCel = ::aGradDifMonth
      else
         aGradCel = ::aGradCellNormal
      endif
   endif

   GradientFill( hDC, aDataArea[ 1 ], aDataArea[ 2 ], aDataArea[ 3 ], aDataArea[ 4 ], aGradCel )

   if ::aTodayPos[ 1 ] == nRow .and. ::aTodayPos[ 2 ] == nCol
      aGradHead = ::aGradHeaderCelDay
      WndBox2007( hDC, aHeadArea[ 1 ] - 1, aHeadArea[ 2 ] - 1, aDataArea[ 3 ], aDataArea[ 4 ], ::nColorGridToday )
   else
      aGradHead = ::aGradHeaderCel
   endif

   GradientFill( hDC, aHeadArea[ 1 ], aHeadArea[ 2 ], aHeadArea[ 3 ], aHeadArea[ 4 ], aGradHead )


   //Paint Header cell

   dNextDay = ::dStart + ( ( nRow - 1 ) * 7 ) + nCol - 1
   cText = " " + Str( Day( dNextDay ), 2 )
   if ( nRow = 1 .and. nCol = 1 .and. Month( dNextDay ) != Month( ::dDate ) ) ;
      .or. Day( dNextDay ) == 1 .or. ( Day( dNextDay ) == 1 .and. Month( dNextDay ) != Month( ::dDate ) )
*      cText = " " + SubStr( CMonth( dNextDay ), 1, 3 ) + " " + cText
      cText = " " + SubStr( CMonth( dNextDay ), 1, 3 ) + cText
   endif
   hOldFont = SelectObject( hDC, ::oFontHeader:hFont )
*-----  fjhg para los numeros de dia del Domingo en rojo
   if nCol == 1
      nOldClr := SetTextColor( hDC, nRGB(200,0,0) )
   else
      nOldClr := SetTextColor( hDC, ::nClrText )
   endif
*----- fin fjhg

   DrawTextTransparent( hDC, cText , aHeadArea, nOR( DT_SINGLELINE, DT_VCENTER ) )
   SelectObject( hDC, hOldFont )
   SetTextColor( hDC, nOldClr )  // fjhg


return nil

//----------------------------------------------------------------------------//
// all header will be painted over nTopMargin ( nTopMargin - nDNameHeight )
//
// ***************** > Header
// ----------------- > TopMargin
//
METHOD PaintHeader( hDC ) CLASS TMonthView

   local dFirstDateWeek := ::GetFirstDateWeek( ::dDate ) //::dDate - DoW( ::dDate ) + 1
   local n, nStyle, hOldFont
   local aArea := Array( 4 )  // fjhg
   local cText, nOldClr
   local aCoor
   local nColStep, nModCol
   local nGridWidth := ::GridWidth()
   local aGradHead, dTemp
   local dFecha := Date()   //FechaServer()    // fjhg sustituye a Date()


   nColStep = Int( nGridWidth / 7 )
   nModCol  = nGridWidth % 7

   nStyle = nOR( DT_SINGLELINE, DT_CENTER, DT_VCENTER )
//::oWnd:oWnd:oWnd:cTitle = DToC( dFirstDateWeek )
   hOldFont = SelectObject( hDC, ::oFont:hFont )   // fjhg

   for n = 0 to 6
*------- inicio fjhg
      aArea[ 1 ] = ::nTopMargin - (::nDNameHeight + 5)      // fjhg + 2 para que cuadre con el box
      aArea[ 2 ] = n * nColStep + ::nLeftMargin + ::nLeftLabelWidth + 1
      aArea[ 3 ] = ::nTopMargin
      aArea[ 4 ] = aArea[ 2 ] + nColStep + If( n == 6, nModCol, 0 ) - 1
      dTemp = dFirstDateWeek + n
      if dTemp == dFecha      // fjhg
         aGradHead := ::aGradHeaderCelDay
      else
         aGradHead := ::aGradHeaderMonth //::aGradHeaderCel
      endif

      GradientFill( hDC, Max( 1, aArea[ 1 ] + 1 ), aArea[ 2 ], aArea[ 3 ] - 1, aArea[ 4 ], aGradHead )

      aArea := {}
*------- fin fjhg

      aCoor = ::GetCoorFromPos( 1, n + 1 )
      aArea = { ::nTopMargin - (::nDNameHeight + 5), aCoor[ 2 ], ::nTopMargin, aCoor[ 2 ] + aCoor[ 3 ] }
      cText = OEMtoANSI(CDoW( dFirstDateWeek + n ))
      if aCoor[ 3 ] < 100
      	cText = SubStr( cText, 1, 3 )
     	endif

*-----  fjhg para pintar el Domingo en rojo
      if ALLTRIM(UPPER(LEFT(cText,1))) == "D"
         nOldClr := SetTextColor( hDC, nRGB(200,0,0) )
      else
         nOldClr := SetTextColor( hDC, ::nClrText )
      endif
*----- fin fjhg
      DrawTextTransparent( hDC, cText, aArea, nStyle )
      SetTextColor( hDC, nOldClr )

   next

   SelectObject( hDC, hOldFont ) // fjhg

return nil


//-----------------------------------------------------------------//

METHOD Resize( nType, nWidth, nHeight ) CLASS TMonthView

   local aInfo, aPos, aCoor
   local nAdj
   local oCalInfo
   local nTop, nLeft, nBottom, nRight

   for each aInfo in ::hDays
#ifdef __XHARBOUR__
         aInfo = aInfo:Value
#endif
      nAdj = ::nDNameHeight
      if Len( aInfo ) > 0
         aPos  = ::GetPosFromDate( aInfo[ 1 ]:dStart )
         aCoor = ::GetCoorFromPos( aPos[ 1 ] , aPos[ 2 ] )
      endif
      for each oCalInfo in aInfo

         nTop    = aCoor[ 1 ] + nAdj + 2
         nLeft   = aCoor[ 2 ] + 10
         nRight  = nLeft + aCoor[ 3 ] - 20
         nBottom = nTop + ::nInfoHeight

         oCalInfo:Move( nTop, nLeft, nRight, nBottom )

         nAdj += ::nDNameHeight + 2
         if nAdj + ::nInfoHeight > aCoor[ 4 ]
            oCalInfo:Hide()
         elseif ! oCalInfo:lVisible
            oCalInfo:Show()
         endif
         ::Refresh()
      next
   next

RETURN nil

//-----------------------------------------------------------------//

METHOD SetDate( dDate ) CLASS TMonthView

   local dDay_1 := dDate - Day( dDate )
   local nDayWeek
   local dFecha := Date()  //FechaServer()    // fjhg sustituye a Date()

   ::dDate  = dDate
   nDayWeek := DoW( dDay_1 ) + _GFD

   if nDayWeek  == 7      
      if Month( dDay_1 ) == Month( dDate )         
         ::dStart = ::dDate      
         else         
         if dow(dDay_1 + 1) == 1  //Si el primer día del mes es domingo, la semana debe
                                  // comenzar 5 dias antes            
            ::dStart := dDay_1 - 5         
            else            
            ::dStart = dDay_1 + 1         
         endif     
      endif   
      else      
      ::dStart = ::GetFirstDateWeek( dDay_1 )   
   endif
   /*if nDayWeek	== 7
      if Month( dDay_1 ) == Month( dDate )
         ::dStart = ::dDate
      else
         ::dStart = dDay_1 + 1
      endif
   else
      ::dStart = ::GetFirstDateWeek( dDay_1 )

   endif*/
   ::dEnd   = ::dStart + 34
   ::nWks = 5
   if Month( ::dEnd + 1 ) == Month( ::dDate )
      ::dEnd += 7
      ::nWks = 6
   endif

   ::dDateSelected = ::dDate

   if Month( dDate ) == Month( dFecha ) .and. Year( dDate ) == Year( dFecha )
      ::dDate = dFecha
      ::aTodayPos = ::GetPosFromDate( ::dDate )
   else
      ::aTodayPos = { 0, 0 }
   endif

   ::aDateSelected = ::GetPosFromDate( ::dDateSelected )

   ::SetLabels()

   //Update date other views
   if ::oCalex:oWeekView != NIL
      ::oCalex:oWeekView:dDate = ::dDate
      ::oCalex:oDayView:dDate = ::dDate
   endif

return nil

//-----------------------------------------------------------------//

METHOD SetLabels() CLASS TMonthView

   local n, dFirst, dLast, clabel

   ::aLabelText = {}

   for n = 1 to ::nWks
      dFirst = ::dStart + ( n - 1 ) * 7
      dLast = dFirst + 6

      if Month( dFirst ) != Month( dLast )
         cLabel = SubStr( CMonth( dFirst ), 1, 3 ) +  " " + Str( Day( dFirst ), 2 ) + " - " + ;
                  SubStr( CMonth( dLast ), 1, 3 ) +  " " + Str( Day( dLast ), 2 )
      else
         cLabel = SubStr( CMonth( dFirst ), 1, 3 ) +  " " + Str( Day( dFirst ), 2 ) + " - " + Str( Day( dLast ), 2 )
      endif

      AAdd( ::aLabelText, cLabel )
   next

return nil

//-----------------------------------------------------------------//
/*
METHOD KeyDown( nKey, nFlags ) CLASS TMonthView
       ? nKey
Return nil
*/
//---------------------------------------------------------------------------//
