
//--------------------------------------//

PROCEDURE SetDolphin( oBrw, oQry, lAddCols )

   LOCAL xField    := NIL
   LOCAL cHeader   := ""
   LOCAL cCol      := ""
   LOCAL aFldNames, oCol
   
   IF lAddCols == NIL 
      lAddCols = .T.
   ENDIF

   WITH OBJECT oBrw
      :bGoTop    := {|| If( oQry:LastRec() > 0, oQry:GoTop(), NIL ) }
      :bGoBottom := {|| If( oQry:LastRec() > 0, oQry:GoBottom(), nil )  }
      IF oQry:lPagination
         :bSkip     := {| n | If ( n != NIL, If( n + oQry:nRecNo < 1 .AND. oQry:nCurrentPage > 1,;
                              ( oQry:PrevPage(, .T. ), oBrw:GoBottom(), 0 ), ;
                              If( n + oQry:nRecNo > oQry:nRecCount .AND. oQry:nCurrentPage < oQry:nTotalRows,;
                                 ( oQry:NextPage( , .T. ), oBrw:GoTop(), 0 ), oQry:Skip( n ) ) ), oQry:Skip( n ) )  }
      ELSE 
         :bSkip     := {| n | oQry:Skip( n ) }
      ENDIF
      :bBof      := {|| oQry:Bof() }
      :bEof      := {|| oQry:Eof() }
      :bBookMark := {| n | If( n == nil,;
                           If( oQry:LastRec() > 0, oQry:RecNo(), 0 ), ;
                           If( oQry:LastRec() > 0, oQry:goto( n ), 0 ) ) }
      :bKeyNo    := {| n | If( n == nil, ;
                           If( oQry:LastRec() > 0, oQry:RecNo(), 0 ), ;
                           If( oQry:LastRec() > 0, oQry:Goto( n ), 0 ) ) }
      :bKeyCount := {|| oQry:LastRec() }
   END

   oBrw:nDataType         := DATATYPE_USER
   oQry:Cargo = oQry:aStructure[ 1 ][ 1 ]
   


   IF lAddCols

      aFldNames := oQry:aStructure

      FOR EACH xField IN aFldNames
         cCol    := xField[ 1 ]
         cHeader := xField[ 1 ]
         oCol = SetColFromMySQL( cCol, cHeader, oQry, oBrw )
         //set order
         oCol:bLClickHeader = Build_CodeBlock_Order( oQry )
      NEXT

      oBrw:bSeek  := { | c | DolphinSeek( c, oQry ) }

   ENDIF

RETURN 

//--------------------------------------//

FUNCTION Build_CodeBlock_Order( oQry )
RETURN {| nMRow, nMCol, nFlags, oCol | SetOrderDolphin( oCol, oQry ) }

//--------------------------------------//

FUNCTION DolphinSeek( c, oQry )

   LOCAL nStart
   LOCAL uData, nNum
   
   STATIC aLastRec := {}
   
   IF Len( aLastRec ) < Len( c )
      IF Len( aLastRec ) == 0 
         nStart = 1
      ELSE 
         nStart = oQry:RecNo()
      ENDIF
      AAdd( aLastRec, nStart )
   ELSE 
      ADel( aLastRec, Len( aLastRec ) )
      ASize( aLastRec, Len( aLastRec ) - 1 )
      IF Len( aLastRec ) == 0
         nStart = 1 
      ELSE 
         nStart = ATail( aLastRec )
      ENDIF
   ENDIF
   
   oQry:Seek( c, oQry:Cargo, nStart, oQry:LastRec(), .T., .T. )
   
RETURN .T.


//--------------------------------------//

FUNCTION SetColFromMySQL( cnCol, cHeader, oQry , oBrw ) 

   LOCAL nType, cType, nLen, nDec, cName
   LOCAL oCol, nCol
   
   IF ValType( cnCol ) == "C"
      nCol               := oQry:FieldPos( cnCol )
   ENDIF

   cName                 := oQry:FieldName( nCol )
   DEFAULT ;
   nCol                  := cnCol
   oCol                  := oBrw:AddCol()
   oCol:cHeader          := cHeader
   cType                 := oQry:FieldType( nCol )
   nLen                  := 0
   nDec                  := 0

   DO CASE
   CASE cType       == 'N'
      nLen               := oQry:FieldLen( nCol )
      nDec               := oQry:FieldDec( nCol )
      oCol:cEditPicture  := NumPict( nLen, nDec, .F., .f. )

   CASE cType       == 'C'
      nLen               := MIN( 100, oQry:FieldLen( nCol ) )

   CASE cType       == 'M'
      nLen               := MIN( 100, Len(AllTrim(oQry:FieldGet( nCol ))) )
      nLen               := IF(nLen < 30, 30, nLen )

   CASE cType       == 'D'
      oCol:nHeadStrAlign := 2
      oCol:nDataStrAlign := 0

   CASE cType       == NIL
      oCol:bEditValue    := { || "..." }

   OTHERWISE
      // just in case.  this will not be executed
      oCol:bEditValue    := { || "..." } 

   ENDCASE

   oCol:bEditValue       := { || oQry:FieldGet( nCol ) }
   oCol:cDataType        := If( cType == nil, 'C', cType )
   oCol:bOnPostEdit      := { |o,x,n| If( n == VK_RETURN, oBrw:onedit( o, x, n, cType, nCol ), NIL ) }

RETURN oCol

//--------------------------------------//

PROCEDURE SetOrderDolphin( oCol, oQry )

   LOCAL aToken 
   LOCAL cType, cOrder
      
   aToken := HB_ATokens( oQry:cOrder, " " )

   IF Len( aToken ) == 1 
      AAdd( aToken, "ASC" )
   ENDIF

   cOrder = AllTrim( Lower( aToken[ 1 ] ) )
   cType = aToken[ 2 ]
   
   AEval( oCol:oBrw:aCols, {| o | o:cOrder := " " } )
   IF oQry:aStructure[ oCol:nCreationOrder ][ 1 ] == cOrder
      IF Upper( cType ) == "ASC"
         cType = "DESC"
         oCol:cOrder = "D"
      ELSE 
         cType = "ASC"
         oCol:cOrder = "A"
      ENDIF
   ELSE 
      cOrder = oQry:aStructure[ oCol:nCreationOrder ][ 1 ]
      cType = "ASC"
      oCol:cOrder = "A"
   ENDIF 
   oQry:SetOrder( cOrder + " " + cType )
   oCol:oBrw:Refresh()

RETURN 

