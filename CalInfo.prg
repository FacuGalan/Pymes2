//calinfo.prg


#include "fivewin.ch"
#include "calex.ch"

static nID := 0

CLASS TCalInfo FROM TControl

   DATA nID AS NUMERIC

   DATA Cargo

   DATA aGradColor
   DATA aGradColorND             //color para no disponible fjhg 28-09-2012
   DATA aGradColorAp             //color para cita aplicada fjhg 29-09-2012
   DATA aGradColorBT             //color para bloqueo/descanso terapeutas fjhg 03-12-2012
   DATA aCoords

   DATA nStart                   //Start Time
   DATA nEnd                     //End Time. Default to nStart.
   DATA dStart                   //Start Date
   DATA dEnd                     //End Date.  Default to dStart
   DATA cText                    //Body Text
   DATA cSubject                 //Subject date
   DATA nIdx                     //Custom index
   DATA lND                      //no disponible para cabinas fjhg  28-09-2012
   DATA lAplicado                //cita aplicada a cobro fjhg 28-09-2012
   DATA lBloqueoT                //cita con bloqueo del terapueta fjhg 03-12-2012

   DATA lSelected
   DATA lCreated
   DATA lVisible

   DATA nClrText                //color del texto

   DATA oCalex
   DATA oLast                  // LastCalInfo included
   DATA nFlags
   DATA oFont

   METHOD New()

   METHOD BuildDates( nTop, nLeft, nWidth, nHeight, oWnd )

   METHOD GetNewId()

   METHOD Hide() INLINE ::lVisible := .F.

   METHOD Move( )

   METHOD Paint( hDC )
   METHOD PaintOnMonth( hDC )
   METHOD PaintOnWeek( hDC ) INLINE ::PaintOnMonth( hDC )

   METHOD Show()  INLINE ::lVisible := .T.

   METHOD LButtonDown( nRow, nCol )



ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oCalex, nStart, nEnd, dStart, dEnd, cText, cSubject, ;
            nClrText, aGradColor, aGradColorND, lND, lAplicado, lBloqueoT, aGradColorAp ) CLASS TCalInfo

   DEFAULT nEnd   := nStart,;
           dStart := CToD( "  /  /  " ),;
           dEnd   := dStart,;
           nClrText := 0,;
           aGradColor := aGradColor,;
           aGradColorND := aGradColor,;
           aGradColorAp := aGradColor,;
           lND := .F.,;
           lAplicado := .f.,;
           lBloqueoT := .f.

   ::nStart    = nStart
   ::nEnd      = nEnd
   ::dStart    = dStart
   ::dEnd      = dEnd
   ::cText     = cText
   ::cSubject  = cSubject
   ::nClrText  = nClrText
   ::lND       = lND
   ::lAplicado = lAplicado
   ::lBloqueoT = lBloqueoT

   ::lSelected = .F.
   ::lCreated  = .F.
   ::lVisible  = .f.

   ::oCalex   = oCalex

   ::aGradColor   = { { 1, nRGB( 225, 255, 255 ), nRGB( 181, 202, 230 ) } }     // 181, 202, 230

   *::aGradColorND = { { 1, nRGB( 255, 125, 125 ), nRGB( 157, 000, 000 ) } }
   ::aGradColorND = ::aGradColor
   *::aGradColorAp = { { 1, nRGB( 193, 255, 125 ), nRGB( 159, 255, 053 ) } }
   ::aGradColorAp = { { 1, nRGB( 255, 125, 125 ), nRGB( 159, 255, 053 ) } }

   ::aGradColorBT = { { 1, nRGB( 155, 155, 155 ), nRGB( 030, 030, 030 ) } }

   ::aCoords = Array( 4 )

   ::nID  = ::GetNewID()
   ::nIdx = 0

return Self

//----------------------------------------------------------------------------//

METHOD BuildDates( nTop, nLeft, nWidth, nHeight, oWnd ) CLASS TCalInfo

   ::Move( nTop , nLeft - 1, Max( nLeft, nLeft + nWidth ) - 1, nTop + nHeight - 1)    // original
   ::oFont = ::oCalex:oFont
   ::lCreated = .T.
   ::lVisible  = .T.

RETURN NIL

//----------------------------------------------------------------------------//

METHOD GetNewId() CLASS TCalInfo

   nID++

   if nID > 10000
      nID = 1
   endif

return nID

//----------------------------------------------------------------------------//

METHOD LButtonDown( nRow, nCol ) CLASS TCalInfo

   if ::oCalex:oCalInfo == NIL
      ::oCalex:oCalInfo = Self
   endif

   ::oCalex:oCalInfo:lSelected = .F.
   ::oCalex:oCalInfo:Refresh()

   ::oCalex:oCalInfo = Self

   ::lSelected = .T.
   ::Refresh()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD Move( nTop, nLeft, nRight, nBottom ) CLASS TCalInfo

   DEFAULT nTop    := ::aCoords[ CI_TOP    ]
   DEFAULT nLeft   := ::aCoords[ CI_LEFT   ]
   DEFAULT nBottom := ::aCoords[ CI_BOTTOM ]
   DEFAULT nRight  := ::aCoords[ CI_RIGHT  ]

   ::aCoords[ CI_TOP    ] = nTop
   ::aCoords[ CI_LEFT   ] = nLeft
   ::aCoords[ CI_BOTTOM ] = nBottom
   ::aCoords[ CI_RIGHT  ] = nRight

   //only paint the visible object
   ::lVisible = nBottom > ::oCalex:nTopMargin .and. nTop < ::oCalex:nHeight

RETURN NIL

//----------------------------------------------------------------------------//

METHOD Paint( hDC ) CLASS TCalInfo

   local cFrom := ::oCalex:oView:ClassName()

   ::PaintOnMonth( hDC )

return nil

//----------------------------------------------------------------------------//

METHOD PaintOnMonth( hDC ) CLASS TCalInfo

   local hBrush, hOldBrush
   local hOldFont, nTextWidth
   local cTime, nOldClr
   local hPen, hOldPen
   local nAdj := 0
   local cFrom := ::oCalex:oView:ClassName()
   local bPaint
   local aRen[5]
   local oFnt
   local nPos


   if ! ::lVisible
      return nil
   endif


   AFILL( aRen, "" )

*--------  Agregado para separar por lineas el asunto fjhg 30-11-2012
   aRen[1] := SUBSTR( ::cSubject, 1, AT("-",::cSubject) - 1 )
   aRen[2] := SUBSTR( ::cSubject, AT("-",::cSubject) + 2, ( AT("(",::cSubject) - 1 ) - AT("-",::cSubject) - 2 )
//   aRen[3] := UPPER( SUBSTR( ::cSubject, AT("(",::cSubject), AT(")",::cSubject) - AT("(",::cSubject) + 2 ) )     // con paerntesis
   aRen[3] := UPPER( SUBSTR( ::cSubject, AT("(",::cSubject) + 2, AT(")",::cSubject) - AT("(",::cSubject) - 2 ) )  // sin parentesis
   aRen[4] := SUBSTR( ::cSubject, AT("/",::cSubject) + 2, ( AT("*",::cSubject) - 1 ) - AT("/",::cSubject) - 1 )
   IF ( nPos := AT("*",::cSubject) ) > 0
      IF ! EMPTY( SUBSTR( ::cSubject, nPos + 2, 1 ) )
         aRen[5] := SUBSTR( ::cSubject, AT("*",::cSubject) + 1, LEN(ALLTRIM(::cSubject)) - AT("*",::cSubject) )
      ENDIF
   ENDIF
*--------  fin del agregado

   if cFrom == "TMONTHVIEW"
         bPaint = {| hDC, aCoords | DrawBox( hDC, aCoords ) }
         //DEFINE FONT oFnt NAME "Segoe UI LIGHT" SIZE 0,-8
         DEFINE FONT oFnt NAME "Arial" SIZE 0,-8      // fjhg 30-11-2012
   else
         bPaint = {| hDC, aCoords | DrawSpecialBox( hDC, aCoords ) }
         DEFINE FONT oFnt NAME "Arial" SIZE 0,-9      // fjhg 30-11-2012
   endif

   if ::lND     // fjhg 28-09-2012

   hBrush = GradientBrush( hDC, ::aCoords[ 1 ], ;
                                ::aCoords[ 2 ], ;
                                ::aCoords[ 4 ], ;
                                ::aCoords[ 3 ], if( ! ::lND .AND. ! ::lAplicado .AND. ! ::lBloqueoT, ::aGradColor, ;
                                                    if( ::lAplicado, ::aGradColorAp, if( ::lBloqueoT, ::aGradColorBT, ::aGradColorND ))))

   else

   hBrush = GradientBrush( hDC, ::aCoords[ 1 ], ;
                                ::aCoords[ 2 ], ;
                                ::aCoords[ 4 ], ;
                                ::aCoords[ 3 ], ::aGradColor )
   endif

   hPen = CreatePen( PS_NULL, 0, 0 )

   hOldPen = SelectObject( hDC, hPen )

   hOldBrush = SelectObject( hDC, hBrush )

   BeginPath( hDC )

   Eval( bPaint, hDC, ::aCoords )

   EndPath( hDC )

   StrokeAndFillPath( hDC )

   SelectObject( hDC, hOldPen )
   DeleteObject( hPen )

   if ! ::lSelected
      hPen = CreatePen( PS_SOLID, 1, ::oCalex:nColorGrid )
   else
      //hPen = CreatePen( PS_SOLID, 2, if( ! ::lND .AND. ! ::lAplicado .AND. ! ::lBloqueoT, ::oCalex:nColorCellSelected, CLR_BLACK ) )    // fjhg 28-09-2012
      hPen = CreatePen( PS_SOLID, 2, ::oCalex:nColorCellSelected )    // fjhg 28-09-2012
      nAdj = 1
   endif

   hOldPen = SelectObject( hDC, hPen )

   Eval( bPaint, hDC, ::aCoords )

//   hOldFont = SelectObject( hDC, ::oFont:hFont )
   hOldFont = SelectObject( hDC, oFnt:hFont )      // fjhg 30-11-2012

   cTime = ::oCalex:ConvertTime( ::nStart, ::oCalex:lAmPm )

   //SetTextColor( hDC, if( ! ::lND, ::nClrText, CLR_YELLOW ) )  // fjhg 28-09-2012
   SetTextColor( hDC, ::nClrText )  // fjhg 28-09-2012
   if cFrom == "TMONTHVIEW"
      IF ::lBloqueoT
         SetTextColor( hDC, CLR_WHITE )
      ENDIF
      DrawTextTransparent( hDC, Space(1) + cTime + Space(1) + ::cSubject , ;
                           { ::aCoords[ 1 ], ::aCoords[ 2 ] + 8, ::aCoords[ 3 ], ::aCoords[ 4 ] - 8 }, nOR( DT_SINGLELINE, DT_VCENTER ) )

   else     //  de aqui a abajo agregado fjhg 30-11-2012 para despliegue de lineas y colores del asunto

      IF ::lBloqueoT
         SetTextColor( hDC, CLR_WHITE )
      ENDIF
      DrawTextTransparent( hDC, Space(1) + cTime + Space(1) + aRen[1] , ;
                           { ::aCoords[ 1 ] + 10, ::aCoords[ 2 ] + 10, ::aCoords[ 3 ], ::aCoords[ 4 ] - 8 }, nOR( DT_SINGLELINE ) )

      DrawTextTransparent( hDC, Space(1) + Space(1) + aRen[2] , ;
                           { ::aCoords[ 1 ] + 22, ::aCoords[ 2 ] + 10, ::aCoords[ 3 ], ::aCoords[ 4 ] - 8 }, nOR( DT_SINGLELINE ) )

      IF ::lBloqueoT
         SetTextColor( hDC, CLR_HGRAY )
      ELSE
         SetTextColor( hDC, CLR_HRED )
      ENDIF
      DrawTextTransparent( hDC, Space(1) + Space(1) + aRen[3] , ;
                           { ::aCoords[ 1 ] + 34, ::aCoords[ 2 ] + 10, ::aCoords[ 3 ], ::aCoords[ 4 ] - 8 }, nOR( DT_SINGLELINE ) )

      SetTextColor( hDC, CLR_HBLUE )
      DrawTextTransparent( hDC, Space(1) + Space(1) + aRen[4] , ;
                           { ::aCoords[ 1 ] + 46, ::aCoords[ 2 ] + 10, ::aCoords[ 3 ], ::aCoords[ 4 ] - 8 }, nOR( DT_SINGLELINE ) )

      SetTextColor( hDC, nOldClr )
      IF ! EMPTY( aRen[5] )
         DrawTextTransparent( hDC, Space(1) + Space(1) + ALLTRIM(aRen[5]) , ;
                              { ::aCoords[ 1 ] + 58, ::aCoords[ 2 ] + 10, ::aCoords[ 3 ], ::aCoords[ 4 ] - 8 }, nOR( DT_SINGLELINE ) )
      ENDIF
   endif

   SetTextColor( hDC, nOldClr )

   SelectObject( hDC, hOldFont )
   SelectObject( hDC, hOldBrush )

   SelectObject( hDC, hOldPen )
   DeleteObject( hPen )

   DeleteObject( hBrush )
   DeleteObject( oFnt )    // fjhg 30-11-2012


return 0

//----------------------------------------------------------------------------//
