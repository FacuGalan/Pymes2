#include "FiveWin.ch"
#include "xbrowse.ch"
#include "tdolphin.ch"
MEMVAR oApp
FUNCTION buscar(base, oWnd, oGet1, oGet2, uValor, cCampoFiltro,uValor2, cCampoFiltro2, xnombre_codigo)
LOCAL oDlg1, oBot1:=ARRAY(1), cFiltro,cFiltro2, oLbx, n := VAL(oGet1:cText), oQr1, oQryPun,nRows, aSizes, i
DEFAULT xnombre_codigo := 'codigo'
IF uValor <> nil
   cFiltro := cCampoFiltro + " = "+uValor
   ELSE
   cFiltro := " TRUE "
ENDIF
IF uValor2 <> nil
   cFiltro2 := cCampoFiltro2 + " LIKE '%"+uValor2+"%'"
   ELSE
   cFiltro2 := " TRUE "
ENDIF
//base:SetOrder("codigo",.T.)
//base:GoTop()
//IF LEN(ALLTRIM(STR(n,13))) >= 11
//   nRows:= base:Locate({n},{"codigo"})
//ELSE
//   nRows:= base:Seek(n,"codigo")
//ENDIF
//IF nRows > 0
base:SetNewFilter(SET_WHERE,if('a.'$base:cQuery,'a.codigo',xnombre_codigo) +"="+ oGet1:cText +  " AND " + cFiltro+" AND "+cFiltro2,.t.)
IF base:nRecCount > 0
      IF oGet2 <> nil
         oGet2:cText := base:nombre
         oGet2:Refresh()
      ENDIF
   RETURN .t. 
/*base:SetNewFilter(SET_WHERE,"codigo = " + oGet1:cText +  " AND " +cFiltro,.t.)
IF base:nRecCount > 0
   IF oGet2 <> nil
      oGet2:cText := base:nombre
      oGet2:Refresh()
   ENDIF
   RETURN .t. */
   ELSE
   base:SetNewFilter(SET_WHERE,cFiltro+" AND "+cFiltro2,.t.)
   base:SetOrder("nombre",.T.)
   base:GoTop()
   aSizes := {}
   FOR i:= 1 TO base:FCount()
       AADD(aSizes,base:FieldLen(i))
   NEXT i 
   //oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2Sql(oApp:cIp))
   DEFINE DIALOG oDlg1 RESOURCE "BUSCAR" TITLE "Busqueda" OF oWnd 
     oDlg1:lHelpIcon := .f.
*     REDEFINE XBROWSE oLbx DATASOURCE base;
*              COLUMNS "Codigo","Nombre";
*              SIZES   100,500;
*              ID 111 OF oDlg1 AUTOSORT ON DBLCLICK oDlg1:End()
     REDEFINE XBROWSE oLbx DATASOURCE base;
              ID 111 OF oDlg1 AUTOSORT ON DBLCLICK oDlg1:End()
     REDEFINE SAY oLbx:oSeek PROMPT "" ID 102 OF oDlg1
     base:bOnChangePage := {|| oLbx:Refresh() }
     oLbx:bKeyDown := {|nKey| IF(nKey==13,oDlg1:End(),.t.) }
     PintaBrw(oLbx,0)
     oLbx:nMarqueeStyle := MARQSTYLE_HIGHLROWMS
   REDEFINE BUTTON oBot1[1] ID 103 OF oDlg1 ACTION oDlg1:end() CANCEL
   ACTIVATE DIALOG oDlg1 ON INIT (ResizeCols(oLbx,aSizes,base),oLbx:SetFocus()) CENTER
  SendMessage( FindWindow( 0, "Teclado en pantalla" ), WM_CLOSE )
   oGet1:cText := base:codigo
   IF oGet2 <> nil
      oGet2:cText := base:nombre
      oGet2:Refresh()
   ENDIF
   *base:SetOrder("codigo",.T.)
ENDIF
RETURN .t.


FUNCTION buscarArt(base, oWnd, oGet1, oGet2, uValor, cCampoFiltro,uValor2, cCampoFiltro2,lViejo)
LOCAL oDlg1, oBot1:=ARRAY(1), cFiltro,cFiltro2, oLbx, n := VAL(oGet1:cText), oQr1, oQryPun,nRows,;
      oGetSeek, cSeek := SPACE(50), aSizes, i
DEFAULT lViejo:=.t.
IF uValor <> nil
   cFiltro := cCampoFiltro + " = "+uValor
   ELSE
   cFiltro := " TRUE "
ENDIF
IF uValor2 <> nil
   cFiltro2 := cCampoFiltro2 + " LIKE '%"+uValor2+"%'"
   ELSE
   cFiltro2 := " TRUE "
ENDIF
//base:SetOrder("codigo",.T.)
//base:GoTop()
//IF LEN(ALLTRIM(STR(n,13))) >= 11
//   nRows:= base:Locate({n},{"codigo"})
//ELSE
//   nRows:= base:Seek(n,"codigo")
//ENDIF

base:SetNewFilter(SET_WHERE,if('a.'$base:cQuery,'a.codigo','codigo') +"="+ str(n) +  " AND " + cFiltro+" AND "+cFiltro2,.t.)
//IF nRows > 0
IF base:nRecCount > 0
      IF oGet2 <> nil
         oGet2:cText := base:nombre
         oGet2:Refresh()
      ENDIF
   RETURN .t.    
/*base:SetNewFilter(SET_WHERE,"codigo = " + oGet1:cText +  " AND " +cFiltro,.t.)
IF base:nRecCount > 0
   IF oGet2 <> nil
      oGet2:cText := base:nombre
      oGet2:Refresh()
   ENDIF
   RETURN .t. */
   ELSE
   base:SetNewFilter(SET_LIMIT,"1000",.t.)
   base:SetNewFilter(SET_WHERE,cFiltro+" AND "+cFiltro2,.t.)
   base:SetOrder(if('a.'$base:cQuery,'a.nombre','nombre'),.T.)
   base:GoTop()
   aSizes := {}
   FOR i:= 1 TO base:FCount()
       AADD(aSizes,base:FieldLen(i))
   NEXT i     
   //oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2Sql(oApp:cIp))
   DEFINE DIALOG oDlg1 RESOURCE "BUSCARART" TITLE "Busqueda" OF oWnd 
     oDlg1:lHelpIcon := .f.
*     REDEFINE XBROWSE oLbx DATASOURCE base;
*              COLUMNS "Codigo","Nombre";
*              SIZES   100,500;
*              ID 111 OF oDlg1 AUTOSORT ON DBLCLICK oDlg1:End()
     REDEFINE XBROWSE oLbx DATASOURCE base;
              ID 111 OF oDlg1 AUTOSORT ON DBLCLICK oDlg1:End()             
     REDEFINE GET oGetSeek VAR cSeek ID 102 OF oDlg1
     base:bOnChangePage := {|| oLbx:Refresh() }
     //oGetSeek:bKeyDown := { |nKey,nFlag| FiltraArt(base, oGetSeek, oLbx, nKey, cFiltro+" AND "+cFiltro2) }
     oGetSeek:bKeyDown := { |nKey,nFlag| IF(lViejo,FiltraArt(base, oGetSeek, oLbx, nKey, cFiltro+" AND "+cFiltro2) ,;
                                                   FiltraArt_nuevo(base, oGetSeek, oLbx, nKey,cFiltro,cFiltro2)) }
     oLbx:bKeyDown := {|nKey| IF(nKey==13,oDlg1:End(),.t.) }
     PintaBrw(oLbx,0)
     oLbx:nMarqueeStyle := MARQSTYLE_HIGHLROWMS
   REDEFINE BUTTON oBot1[1] ID 103 OF oDlg1 ACTION oDlg1:end() CANCEL WHEN(base:nRecCount>0)
   ACTIVATE DIALOG oDlg1 ON INIT (ResizeCols(oLbx,aSizes,base),oGetSeek:SetFocus()) CENTER
   oGet1:cText := base:codigo
   IF oGet2 <> nil
      oGet2:cText := base:nombre
      oGet2:Refresh()
   ENDIF
   //base:SetOrder("codigo",.T.)	   
ENDIF
RETURN .t.

STATIC FUNCTION ResizeCols(oLbx,aSizes,base)
LOCAL i
FOR i:= 1 TO base:FCount()
    IF(aSizes[i] >= 100) 
      oLbx:aCols[i]:nWidth := IF(oLbx:aCols[i]:nWidth *.25>300,250,oLbx:aCols[i]:nWidth *.25)
      ELSE 
      oLbx:aCols[i]:nWidth := oLbx:aCols[i]:nWidth *.70
    ENDIF  
NEXT i     
RETURN nil

FUNCTION FiltraArt(base, oG, oLbx, nKey, cCampoFiltro,cAlias)
LOCAL cFiltro, cText, cNombre := if('a.'$base:cQuery,'a.nombre','nombre'),;
      cCodigo := if('a.'$base:cQuery,'a.codigo','codigo')
DEFAULT cCampoFiltro := '',cAlias:=''
IF LEN(cAlias) > 0
    cNombre := ALLTRIM(cAlias)+'.nombre'
    cCodigo := ALLTRIM(cAlias)+'.codigo'
ENDIF
/*
      cCodigo := if('a.'$base:cQuery,'a.codigo','codigo'),;
      cAlias := if(base:FieldPos('alias')>0,'alias','')
DEFAULT cCampoFiltro := '' 
*/
oG:Assign()
IF nKey = 38 .or. nKey = 40
   oLbx:SetFocus()
   RETURN nil 
ENDIF
IF nKey >= 32 .AND. nKey <= 122 
   IF nKey >= 96 .and. nKey <= 105
      nKey := nKey - 48
   ENDIF
   cText := LEFT(oG:cText,oG:nPos-1) + CHR(nKey)
   ELSE
   cText := ALLTRIM(oG:cText)
ENDIF
cText := STRTRAN(cText,"a.","a ")
cText := STRTRAN(cText,"'","")
cText := STRTRAN(cText,"%","")
cText := STRTRAN(cText," ","%' and "+cNombre+" like '%") 
IF !EMPTY(cCampoFiltro)
   cFiltro := cCampoFiltro  + " AND ( "+cNombre+" LIKE '%"+ cText +"%' OR " +;
              cCodigo + " LIKE '%"+ cText +"%')" 
              /*
   IF !EMPTY(cAlias)
      cFiltro := cCampoFiltro  + " AND ( "+cNombre+" LIKE '%"+ cText +"%' OR " +;
                cCodigo + " LIKE '%"+ cText +"%' OR " +cAlias+" LIKE '%"+ cText +"%')"
      ELSE
      cFiltro := cCampoFiltro  + " AND ( "+cNombre+" LIKE '%"+ cText +"%' OR " +;
                cCodigo + " LIKE '%"+ cText +"%')"          
   ENDIF
   */
   ELSE 
   cFiltro := cNombre+" LIKE '%"+ cText +"%' OR " + cCodigo + " LIKE '%"+ cText +"%'"
   /*
   IF !EMPTY(cAlias)
      cFiltro := cNombre+" LIKE '%"+ cText +"%' OR " + cCodigo + " LIKE '%"+ cText +"%' OR " + cAlias + " LIKE '%"+ cText +"%'"
      ELSE
      cFiltro := cNombre+" LIKE '%"+ cText +"%' OR " + cCodigo + " LIKE '%"+ cText +"%'"
   ENDIF
   */
ENDIF
base:SetNewFilter(SET_WHERE,cFiltro,.t.)
// Se refresca el listbox
oLbx:refresh()
RETURN .T. 

FUNCTION FiltraArt_nuevo(base, oG, oLbx, nKey,cFiltro1,cFiltro2)
LOCAL cFiltro, cText,cText2,i, lSimple := !"JOIN"$base:cQuery, oErr
oG:Assign()
IF nKey = 38 .or. nKey = 40
   oLbx:SetFocus()
   RETURN nil 
ENDIF
IF nKey >= 32 .AND. nKey <= 122 
   IF nKey >= 96 .and. nKey <= 105
      nKey := nKey - 48
   ENDIF
   cText := LEFT(oG:cText,oG:nPos-1) + CHR(nKey)
   ELSE
   cText := ALLTRIM(oG:cText)
ENDIF
cText := STRTRAN(cText,"'","")
cText := STRTRAN(cText,"%","")
cFiltro:= '(FALSE'
cText2:= cText
FOR i := 1 TO LEN(base:aStructure)
   cText := STRTRAN(cText2," ","%'^and^"+IF(!lSimple,"a.","")+base:FieldName(i)+"^like^'%")
   cFiltro := cFiltro+"^OR^"+IF(!lSimple,"a.","")+base:FieldName(i)+"^LIKE^'%"+ cText +"%'^"
NEXT i
cFiltro := STRTRAN(cFiltro,"^"," ")
cFiltro := cFiltro+")"+" AND "+cFiltro1+" AND "+cFiltro2

TRY 
   base:SetNewFilter(SET_WHERE,cFiltro,.t.)
CATCH oErr
   //MsgInfo(base:cQuery)   
END
// Se refresca el listbox
oLbx:refresh()
RETURN .T. 