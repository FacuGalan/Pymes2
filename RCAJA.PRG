#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** Retiro de caja
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana, oQryPun
PROCEDURE RCAJA(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"retiros "+;
         IF(oApp:usua_es_supervisor," WHERE checkeado = FALSE "," WHERE checkeado = FALSE AND caja = "+str(oApp:prefijo)) +;
         " ORDER BY fecha ")
oQryPun := oApp:oServer:Query( "SELECT caja as codigo, nombre FROM ge_"+oApp:cId+"punto WHERE caja <> "+str(oApp:prefijo))

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Movimientos de caja" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Movimientos de caja",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "TRANSF" OF oBar ;
            TOOLTIP "Emitir Comprobante Movimientos"  ;
            ACTION PrintRetiro(oQry:id);
            PROMPT "Reimprime" TOP 
         DEFINE BUTTON RESOURCE "BACKU" OF oBar ;
            TOOLTIP "Transferencia entre cajas"  ;
            ACTION (Transferir(),oBrw:Refresh());
            PROMPT "Transferir" WHEN("A"$cPermisos .and. oQryPun:nRecCount > 0) TOP 
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Registros"  ;
            ACTION (Filt(), oBrw:Refresh());
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
              COLUMNS "fecha","importe","caja","tipo","observa";
              HEADERS "Fecha","Importe","N° Caja","Tipo","Observaciones";
              SIZES 80,120,100,40,200;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,5) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,5)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(5), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,poriva, oQryPun,;
      lSuper:=.f.,aTipo:={"Ingreso","Retiro"},cTipo, nId, nImp, cTip
      
oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2SQl(oApp:cIp))
IF lAlta
   IF !ValidarTurno(oWnd1)
      RETURN nil 
   ENDIF
   base := oQry:GetBlankRow()
   base:fecha := DATE()
   base:caja:= oQryPun:caja
   base:usuario:= oApp:usuario
   cTipo:="Ingreso"
   ELSE
   IF oQry:checkeado
       MsgStop("No puede modificar un movimiento ya consolidadado en un cierre","Error") 
       RETURN nil 
   ENDIF   
   base := oQry:GetRowObj()
   cTip := base:tipo
   nImp := base:importe
   IF base:tipo="I"
      cTipo:="Ingreso"
   ELSE 
      cTipo:="Retiro"
   ENDIF
ENDIF
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Retiro de caja";
       FROM 05,15 TO 19,80 OF oWnd1
   
   @ 07, 05 SAY "Fecha:"        OF oForm PIXEL SIZE 35,20 RIGHT
   @ 22, 05 SAY "Importe:"      OF oForm PIXEL SIZE 35,20 RIGHT
   @ 37, 05 SAY "Caja:"         OF oForm PIXEL SIZE 35,20 RIGHT
   @ 52, 05 SAY "Motivo:"       OF oForm PIXEL SIZE 35,20 RIGHT
   @ 67, 05 SAY "Tipo:"         OF oForm PIXEL SIZE 40,20 RIGHT   
  
   @ 05, 50 GET oGet[1] VAR base:fecha   PICTURE "@D"  OF oForm PIXEL CENTER 
   @ 20, 50 GET oGet[2] VAR base:importe PICTURE "99999999.99"    OF oForm PIXEL RIGHT;
                VALID(base:importe>0)
   @ 35, 50 GET oGet[3] VAR base:caja    PICTURE "999" OF oForm PIXEL RIGHT WHEN(lSuper);
                VALID(base:caja>0)
   @ 50, 50 GET oGet[4] VAR base:observa OF oForm PIXEL SIZE 200,12
   @ 65, 50 COMBOBOX oGet[5] VAR cTipo   ITEMS aTipo OF oForm PIXEL SIZE 40,12

   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:importe <= 0
   MsgStop("Valores no válidos","Error")
   LOOP
ENDIF   
IF lAlta
   oQry:GetBlankRow()
   base:observa:= LEFT(oApp:oServer:Query("SELECT CURTIME() as hora"):hora,5) + " " + ALLTRIM(base:observa)
   ELSE
   IF nImp <> base:importe
      Auditar(2," Mov. de caja: Antes $"+alltrim(STR(oQry:importe,12,2))+" Caja "+STR(oQry:caja,4))
   ENDIF
   IF cTip <> LEFT(cTipo,1)
      Auditar(2," Mov. de caja: Cambio de Tipo ("+cTip+" a "+LEFT(cTipo,1)+") $"+alltrim(STR(base:importe,12,2))+" Caja "+STR(oQry:caja,4))
   ENDIF   
ENDIF
base:tipo:= LEFT(cTipo,1)
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh(.t.)
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
IF lAlta
   nId := oApp:oServer:LastInsertID()
   lRta := MsgYesNo("Desea imprimir el movimiento?","Atención")
   IF lRta
      PrintRetiro(nId)
   ENDIF
ENDIF
EXIT
ENDDO
RETURN nil

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

***********************************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError
IF oQry:checkeado
   MsgStop("No puede borrar un movimiento ya consolidadado en un cierre","Error") 
   RETURN nil 
ENDIF
mrta := MsgNoYes("¿Seguro de eliminar?","Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  Auditar(1," Mov. de caja: $"+alltrim(STR(oQry:importe,12,2))+" Caja "+STR(oQry:caja,4))
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


************************************************************
** Imprimir Retiro 
STATIC FUNCTION PrintRetiro(n)
LOCAL oPrn, oFont, oFont1, config, oQryP,;
      nRow, nRow1, oQryI      
oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))
config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")

oQryI := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"retiros WHERE id =" +ClipValue2Sql(n))
IF oQryP:imprimeTic   
      IF config:fon > 25 
        config:fon := config:fon /3
      ENDIF      
      DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5 BOLD
      DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon,config:fon*3.5 BOLD
      IF !oQryP:tick80
         PRINT oPrn TO ALLTRIM(oQryP:impresorat)
          PAGE
          oPrn:Say( oApp:tamlet*1,1, "DOCUMENTO NO VALIDO",oFont)
          oPrn:Say( oApp:tamlet*2,1, "  COMO FACTURA",oFont)             
             
          oPrn:Say( oApp:tamlet*3,1, "Puesto:"+STR(oQryI:caja,4),oFont)
          oPrn:Say( oApp:tamlet*4,1, DTOC(oQryI:fecha),oFont)
          oPrn:Say( oApp:tamlet*5,1, IF(oQryI:tipo="I","INGRESO A CAJA","RETIRO DE CAJA"),oFont1)
          oPrn:Say( oApp:tamlet*6,1, "Importe:"+STR(oQryI:importe,12,2),oFont)
          oPrn:Say( oApp:tamlet*7,1, oQryI:observa,oFont)
          oPrn:Say( oApp:tamlet*9,1, "____________________________",oFont)
          oPrn:Say( oApp:tamlet*10,1,"    Firma y aclaración",oFont)
          oPrn:Say( oApp:tamlet*12,1, "...",oFont)
          ENDPAGE
       ENDPRINT
      ELSE
       PRINT oPrn TO ALLTRIM(oQryP:impresorat)
          oPrn:oFont := oFont
          nRow := .5
          PAGE

          @ nRow, 00 PRINT TO oPrn TEXT "DOCUMENTO NO VALIDO" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "COMO FACTURA" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"             
          @ nRow, 00 PRINT TO oPrn TEXT  "Caja N°:"+STR(oQryI:caja,4) ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow  ALIGN "C"        
          @ nRow, 00 PRINT TO oPrn TEXT  "Fecha de operación:"+DTOC(oQryI:fecha);
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  IF(oQryI:tipo="I","INGRESO A CAJA","RETIRO DE CAJA") ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  oQryI:observa ;
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow
          nRow1 := nRow + .5
          @ nRow1, 00 PRINT TO oPrn TEXT "Importe: $ "+STR(oQryI:importe,12,2);
                      SIZE 5.5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"          
          nRow1 := nRow + .5
          @ nRow1, 00 PRINT TO oPrn TEXT "Firma :____________________________";
                      SIZE 5.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
          
          @ nRow, 00 PRINT TO oPrn TEXT  "...";
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow                                       
          ENDPAGE
       ENDPRINT 
   ENDIF
   ELSE 
   DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5 BOLD
   DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon,config:fon*3.5 BOLD
   PRINT oPrn PREVIEW
          oPrn:oFont := oFont
          nRow := .5
          PAGE

          @ nRow, 00 PRINT TO oPrn TEXT "DOCUMENTO NO VALIDO" ;
                                  SIZE 20,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "COMO FACTURA" ;
                                  SIZE 20,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"             
          @ nRow, 00 PRINT TO oPrn TEXT  "Caja N°:"+STR(oQryI:caja,4) ;
                  SIZE 20,.5 CM FONT oFont1 LASTROW nRow  ALIGN "C"        
          @ nRow, 00 PRINT TO oPrn TEXT  "Fecha de operación:"+DTOC(oQryI:fecha);
                  SIZE 20,.5 CM FONT oFont LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  IF(oQryI:tipo="I","INGRESO A CAJA","RETIRO DE CAJA") ;
                  SIZE 20,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  ALLTRIM(oQryI:observa) ;
                  SIZE 20,1 CM FONT oFont LASTROW nRow ALIGN "C"
          nRow1 := nRow + .5
          @ nRow1, 00 PRINT TO oPrn TEXT "Importe: $ "+STR(oQryI:importe,12,2);
                      SIZE 20,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"          
          nRow1 := nRow + .5
          @ nRow1, 00 PRINT TO oPrn TEXT "Firma :____________________________";
                      SIZE 20,.5 CM FONT oFont LASTROW nRow ALIGN "C"
          
          @ nRow, 00 PRINT TO oPrn TEXT  "...";
                  SIZE 20,.5 CM FONT oFont LASTROW nRow ALIGN "C"
          ENDPAGE
       ENDPRINT    
ENDIF
RETURN NIL


***************************************
** Transferir Saldo
STATIC FUNCTION Transferir ()
LOCAL oGet := ARRAY(6), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,nId,;
      cCaja := SPACE(30), nHacia := oQryPun:codigo, mobserva := SPACE(50)
      
   base := oQry:GetBlankRow()
   base:fecha := DATE()
   base:caja:= oApp:prefijo
   base:usuario:= oApp:usuario
   base:tipo := 'R'
   base:observa := "TRANS. A CAJA "
DO WHILE .T.
DEFINE DIALOG oForm TITLE "Transferir Saldo a otra caja";
       FROM 05,15 TO 19,80 OF oWnd1
   
   @ 07, 05 SAY "Fecha:"        OF oForm PIXEL SIZE 35,20 RIGHT
   @ 22, 05 SAY "Importe:"      OF oForm PIXEL SIZE 35,20 RIGHT
   @ 37, 05 SAY "Desde Caja:"   OF oForm PIXEL SIZE 35,20 RIGHT
   @ 52, 05 SAY "Hacia Caja:"   OF oForm PIXEL SIZE 35,20 RIGHT
   @ 67, 05 SAY "Detalle:"      OF oForm PIXEL SIZE 35,20 RIGHT
   
  
   @ 05, 50 GET oGet[1] VAR base:fecha   PICTURE "@D"  OF oForm PIXEL CENTER WHEN(.F.)
   @ 20, 50 GET oGet[2] VAR base:importe PICTURE "99999999.99"    OF oForm PIXEL RIGHT;
                VALID(base:importe>0)
   @ 35, 50 GET oGet[3] VAR base:caja    PICTURE "999" OF oForm PIXEL RIGHT WHEN(.f.)
   @ 50, 50 GET oGet[4] VAR nHacia PICTURE "9999" RIGHT SIZE 25,12  PIXEL;
            VALID(Buscar(oQryPun,oForm,oGet[4],oGet[5]));
            ACTION ((oGet[4]:cText := 0,Buscar(oQryPun,oForm,oGet[4],oGet[5]))) BITMAP "BUSC1" 
   @ 50, 90 GET oGet[5] VAR cCaja PICTURE "@!"  OF oForm PIXEL SIZE 90,12;
                WHEN((oGet[5]:cText := oQryPun:nombre) = SPACE(30))
   @ 65, 50 GET oGet[6] VAR mobserva OF oForm PIXEL

   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF nHacia = base:caja 
   MsgStop("Debe transferir una caja distinta que la propia","Error")
   LOOP
ENDIF
base:observa:= LEFT(oApp:oServer:Query("SELECT CURTIME() as hora"):hora,5)+" "+ALLTRIM(base:observa)+" "+STR(nHacia,3)+" "+mobserva
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:GetBlankRow()
  base:tipo := "I"  
  base:observa := LEFT(oApp:oServer:Query("SELECT CURTIME() as hora"):hora,5)+" "+"TRANS. DE CAJA " +STR(base:caja,3)+" "+mobserva
  base:caja := nHacia
  oQry:oRow := base
  oQry:Save()
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY

nId := oApp:oServer:LastInsertID()
lRta := MsgYesNo("Desea imprimir el retiro?","Atención")
IF lRta
  PrintRetiro(nId-1)
ENDIF

EXIT
ENDDO
RETURN nil

******************************************

STATIC FUNCTION FILT( )

LOCAL CWHERE, vdesde := CTOD("01/01/1990"), vhasta := CTOD("31/12/2500"), nEstado := 1 
LOCAL oGet1, oGet2, oGet3, oBot1, oBot2,oDlg1,base,oError, ;
      mrta := .f., aCor, aEstado := {"Todos","Ingresos","Retiros"} 


DEFINE DIALOG oDlg1 TITLE "FILTRADO de Saldos de Caja" FROM 05,10 TO 14,60 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Tipo:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT
   
   @ 05, 70 GET oGet1 VAR vdesde PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR vhasta PICTURE "@D"  OF oDlg1 PIXEL 
   @ 35, 70 COMBOBOX oGet3 VAR nEstado  ITEMS aEstado SIZE 80,80 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " fecha >=" + ClipValue2SQL(vdesde) +;
      + "  and fecha <= " + ClipValue2SQL(vhasta) ;
     + "  and " + IF(nEstado = 1," TRUE ", IF(nEstado = 2, " tipo = 'I'"," tipo = 'R'")) ;
     + IF(oApp:usua_es_supervisor,"", " AND caja = "+str(oApp:prefijo))
oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Maketotals()
oBrw:Refresh()
RETURN nil