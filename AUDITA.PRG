#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** AUDITORIA
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE AUDITA(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"auditoria WHERE fecha = CURDATE() ORDER BY fecha ")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Auditoria" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010         
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Auditoria"  ;
            ACTION oBrw:Report("Reporte de Auditoria",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar auditoria"  ;
            ACTION Filt();
            PROMPT "Filtrar" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "id","descripcion","fecha","hora","usuario";
              HEADERS "Id","Descripcion","Fecha","Hora","Usuario";
              SIZES 50,400,90,90,90;
              ID 111 OF oDlg AUTOSORT 
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,5) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN



*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
oQry:End()
RELEASE oQry
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.



****************************************FILTRADO**********************
STATIC FUNCTION FILT( )
   LOCAL oGet:=ARRAY(12), oBot:=ARRAY(2), Vdesde := DATE(),Vhasta := DATE(),;         
         oForm, cWhere, aCor,lRta := .F.,;
         aTipo:={"TODOS","ELIMINACION","MODIFICACION","BORRADO EN VENTA","CANCELACION DE VENTA",;
                 "CIERRE DE TURNO","DESCUENTO","FORMA DE PAGO DISTINTA"},nTipo:=1


DEFINE DIALOG oForm TITLE "Filtrado de Auditoria"  FROM 05,15 TO 15,65 OF oWnd1

   @ 07, 05 SAY "Desde Fecha:"           OF oForm PIXEL SIZE 45,20 RIGHT
   @ 22, 05 SAY "Hasta Fecha"            OF oForm PIXEL SIZE 45,20 RIGHT
   @ 37, 05 SAY "Tipo:"                  OF oForm PIXEL SIZE 45,20 RIGHT
   
  

   @ 05, 55 GET oGet[1] VAR Vdesde PICTURE "@D"    OF oForm PIXEL    
   @ 20, 55 GET oGet[2] VAR Vhasta PICTURE "@D"    OF oForm PIXEL 
   @ 35, 55 COMBOBOX oGet[3] VAR nTipo ITEMS aTipo OF oForm PIXEL SIZE 100,12

   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Filtrar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER 

    IF !lRta
       RETURN nil
    ENDIF    

    nTipo:= nTipo-1

    cWhere = " 1=1 " ;
      + " AND fecha >=" + ClipValue2SQL(vdesde) ; 
      + " AND fecha <=" + ClipValue2SQL(vhasta) ;
      + IF(nTipo=0,""," AND tipo = "+ClipValue2SQL(nTipo))
      

oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil


**************************************************************************************************
*** cargar datos de auditoria 
FUNCTION Auditar(nTipo,cDetalle)
LOCAL aTipo:={"ELIMINACION","MODIFICACION","BORRADO EN VENTA","CANCELACION DE VENTA",;
              "CIERRE DE TURNO","DESCUENTO","FORMA DE PAGO DISTINTA"}
DEFAULT cDetalle := ""
oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"auditoria (tipo,descripcion,fecha,hora,usuario)"+;
                     "VALUES("+ClipValue2Sql(nTipo)+","+ClipValue2Sql(aTipo[nTipo]+cDetalle)+",CURDATE(),CURTIME(),"+;
                               ClipValue2Sql(oApp:usuario)+")")
RETURN nil

**************************************************************************************************
*** Aviso si se cobra con una forma de pago con distinto incremento/descuento que la forma con la
*** que se calcularon los precios. Lo usan VENTAS, FACREM, FACT y FACT_multi.
*** Pregunta si sigue: devuelve .F. si el operador quiere volver a corregir el cobro.
*** En cDetalle (por referencia) deja el texto para Auditar(7,...), o "" si no hay diferencia.
FUNCTION AvisoFormaDistinta(nCodPrecio,aCodPago,cDetalle)
LOCAL oQry, cCods := "", i, lTabDesc, cNomPre := "", nIncPre := 0, nRanPre := 0, cDistintas := ""
cDetalle := ""
IF EMPTY(nCodPrecio) .or. EMPTY(aCodPago)
   RETURN .t.
ENDIF
FOR i := 1 TO LEN(aCodPago)
    cCods := cCods + "," + ClipValue2Sql(aCodPago[i])
NEXT i
lTabDesc := oApp:oServer:TableExist('ge_'+oApp:cId+"forpag_desc")
oQry := oApp:oServer:Query("SELECT f.codigo, f.nombre, f.incremento, "+;
        IF(lTabDesc,"(SELECT COUNT(*) FROM ge_"+oApp:cId+"forpag_desc d WHERE d.codfor = f.codigo)","0")+" AS rangos "+;
        "FROM ge_"+oApp:cId+"forpag f WHERE f.codigo IN ("+ClipValue2Sql(nCodPrecio)+cCods+")")
DO WHILE !oQry:Eof()
   IF oQry:codigo = nCodPrecio
      cNomPre := ALLTRIM(oQry:nombre)
      nIncPre := oQry:incremento
      nRanPre := oQry:rangos
   ENDIF
   oQry:Skip()
ENDDO
IF EMPTY(cNomPre)
   RETURN .t.
ENDIF
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF oQry:codigo <> nCodPrecio .and. (oQry:incremento <> nIncPre .or. oQry:rangos > 0 .or. nRanPre > 0)
      cDistintas := cDistintas + IF(EMPTY(cDistintas),"",", ") + ALLTRIM(oQry:nombre) + " (" + TextoIncremento(oQry:incremento,oQry:rangos) + ")"
   ENDIF
   oQry:Skip()
ENDDO
IF EMPTY(cDistintas)
   RETURN .t.
ENDIF
IF !MsgNoYes("Los precios se calcularon con " + cNomPre + " (" + TextoIncremento(nIncPre,nRanPre) + ")" + CHR(10) +;
             "y se esta cobrando con: " + cDistintas + CHR(10) + CHR(10) +;
             "Desea grabar igual?","Forma de pago distinta")
   RETURN .f.
ENDIF
cDetalle := LEFT(" Precio: " + cNomPre + " / Cobro: " + cDistintas,60)
RETURN .t.

STATIC FUNCTION TextoIncremento(nInc,nRangos)
RETURN IF(nInc > 0,"+","") + ALLTRIM(STR(nInc,6,2)) + "%" + IF(nRangos > 0," + desc. por monto","")