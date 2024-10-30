#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"


************************************************************************************************
** VALES
************************************************************************************************
MEMVAR oApp

*************************************************
** Menu Vales
FUNCTION Vales( nRow, nCol, oDlg , lCerrar, oWnd)
   local oMenu
   DEFAULT lCerrar := .f.
   MENU oMenu POPUP      
      MENUITEM "Generar Vale"       ACTION GenVale(oDlg)
      MENUITEM "Cancelar Vale"      ACTION CanVale(oDlg,lCerrar,oWnd)  
      MENUITEM "Salir"              
   ENDMENU   
   ACTIVATE POPUP oMenu WINDOW oDlg AT nRow, nCol   
return nil

*************************************************
** Generar un vale
STATIC FUNCTION GenVale()
LOCAL oBot1, oBot2, oDlg1,oGet:=ARRAY(6), oError, ;
      mrta := .f., aCor, oQryPun, cFecha:=DATE(),;
      oFont, nCodcli:=0, cNomCli:=SPACE(50), oQryCli, nImporte:=0, nNumero
  
IF oApp:cierre_turno
  IF !ValidarTurno(oApp:oWnd)
    RETURN nil
  ENDIF
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")
oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIp))
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Generar un vale para clientes" ;
       FROM 05,15 TO 17,85 OF oApp:oWnd ICON oApp:oIco FONT oFont
   oDlg1:lHelpIcon := .f.
   acor := AcepCanc(oDlg1)
   
   @ 07, 05 SAY "Cliente:"     OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Nombre:"      OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Importe:"     OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Fecha:"       OF oDlg1 PIXEL SIZE 40,12 RIGHT

   @ 05, 50 GET oGet[1] VAR nCodcli  PICTURE "99999999" RIGHT OF oDlg1 SIZE 35,12 PIXEL;
                VALID(Buscar(oQryCli,oDlg1,oGet[1],oGet[2]));
                ACTION (oGet[1]:cText:= 0, Buscar(oQryCli,oDlg1,oGet[1],oGet[2])) BITMAP "BUSC1" 
   @ 20, 50 GET oGet[2] VAR cNomCli    PICTURE "@!" OF oDlg1 PIXEL 
   @ 35, 50 GET oGet[3] VAR nImporte   PICTURE "99999999.99" OF oDlg1 PIXEL RIGHT    
   @ 50, 50 GET oGet[5] VAR cFecha     OF oDlg1 PIXEL PICTURE "@D" CENTER WHEN(.f.)
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar (F9)" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot1:Click,.f.)}

ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet[1]:SetFocus()

IF !mrta
   RETURN nil
ENDIF
IF EMPTY(cNomCli) .or. nImporte <= 0
   MsgStop("Complete datos de cliente e importe","Error")
   LOOP
ENDIF   
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"vales (codcli,importe,fecemi,usuario,nombre,caja) VALUES "+;
                        "("+ClipValue2Sql(nCodcli)+","+ClipValue2Sql(nImporte)+","+ClipValue2Sql(cFecha)+","+;
                        ClipValue2Sql(oApp:usuario)+","+ClipValue2Sql(cNomCli)+","+Clipvalue2sql(oQryPun:caja)+")")  
  nNumero:= oApp:oServer:Query("SELECT MAX(numero) AS ultimo FROM ge_"+oApp:cId+"vales"):ultimo
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"retiros (caja,fecha,importe,observa,usuario,tipo) VALUES "+;
                           "("+ClipValue2Sql(oQryPun:caja)+","+ClipValue2Sql(cFecha)+","+;
                            ClipValue2Sql(nImporte)+",'Emisión de Vale N° "+ALLTRIM(STR(nNumero,8))+" a "+cNomCli+"',"+;
                            Clipvalue2sql(oApp:usuario)+",'I')")
  oApp:oServer:CommitTransaction()
  mrta := MsgYesNo("Desea imprimir el Vale?","Atención")
  IF mRta
     PrintVale(nNumero)
  ENDIF
CATCH oError
  ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil 

*******************************************
** Cancelar Vales
STATIC FUNCTION CanVale(oWnd,lCerrar,oWnd2)
LOCAL oQry, oQryPun, oWnd1, oBrw, oBar, oDlg
oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"vales WHERE feccan IS NULL ORDER BY nombre ")
oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIp))
IF lCerrar
   oWnd2:End()
ENDIF   

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Cancelacion de Vales" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Cancelar Vales"  ;
            ACTION (Baja(oQry, oQryPun:caja ),oBrw:Refresh());
            PROMPT "Cancelar" TOP WHEN(oQry:RecCount()>0)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Reimprimir Vale"  ;
            ACTION PrintVale(oQry:numero);
            PROMPT "Reimprime" TOP WHEN(oQry:RecCount()>0)  
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Vales",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0)         
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "numero","fecemi","importe","nombre";
              HEADERS "Numero","Fecha","Importe","Cliente/Observaciones";
              SIZES 80,80,120,100,200;
              ID 111 OF oDlg AUTOSORT 
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,4) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQry))
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ( oQry)
LOCAL aNueva := {}, i, j
oQry:End()
RELEASE oQry
RETURN .t.

***********************************
** Baja de registro
STATIC FUNCTION Baja ( oQry , nCaja )
LOCAL mrta := .f., oError

mrta := MsgNoYes("¿Seguro de Cancelar el Vale?","Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"vales SET feccan = CURDATE() WHERE numero = "+ClipValue2Sql(oQry:numero)) 

  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"retiros (caja,fecha,importe,observa,usuario,tipo) VALUES "+;
                           "("+ClipValue2Sql(ncaja)+",CURDATE(),"+;
                            ClipValue2Sql(oQry:importe)+",'Cancelacion de Vale N° "+ALLTRIM(STR(oQry:numero,8))+" a "+oQry:nombre+"',"+;
                            Clipvalue2sql(oApp:usuario)+",'R')")
  oApp:oServer:CommitTransaction() 
  oQry:Refresh() 
CATCH oError
  ValidaError(oError)
END TRY
RETURN nil


************************************************************
** Imprimir Retiro 
STATIC FUNCTION PrintVale(n)
LOCAL oPrn, oFont, oFont1, config, oQryP,;
      nRow, nRow1, oQryI      
oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))
config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")

oQryI := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vales WHERE numero =" +ClipValue2Sql(n))

IF config:fon > 25
  config:fon := config:fon /3
ENDIF

DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon*1.5,config:fon*4 BOLD

IF !empty(ALLTRIM(oQryP:impresorat))   
      IF !oQryP:tick80
         PRINT oPrn TO ALLTRIM(oQryP:impresorat)
          nRow := .5
          PAGE

          @ nRow, 00 PRINT TO oPrn TEXT "DOCUMENTO NO VALIDO" ;
                                  SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "COMO FACTURA" ;
                                  SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "VALE Nro:" + STR(oQryI:numero,8) ;
                                  SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"             
          @ nRow, 00 PRINT TO oPrn TEXT  "Caja N°:"+STR(oQryI:caja,4) ;
                  SIZE 5,.5 CM FONT oFont1 LASTROW nRow  ALIGN "C"        
          @ nRow, 00 PRINT TO oPrn TEXT  "Fecha de operación:"+DTOC(oQryI:fecemi);
                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  "VALE DE CLIENTES" ;
                  SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  oQryI:nombre ;
                  SIZE 5,.5 CM FONT oFont LASTROW nRow
          nRow1 := nRow + .5
          @ nRow1, 00 PRINT TO oPrn TEXT "Importe: $ "+STR(oQryI:importe,12,2);
                      SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"          
          nRow1 := nRow + .5
          @ nRow1, 00 PRINT TO oPrn TEXT "Firma :____________________________";
                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
          
          @ nRow, 00 PRINT TO oPrn TEXT  "...";
                  SIZE 5,.5 CM FONT oFont LASTROW nRow                                       
          ENDPAGE
       ENDPRINT
      ELSE
       PRINT oPrn TO ALLTRIM(oQryP:impresorat)
          nRow := .5
          PAGE

          @ nRow, 00 PRINT TO oPrn TEXT "DOCUMENTO NO VALIDO" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "COMO FACTURA" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "VALE Nro:" + STR(oQryI:numero,8) ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"             
          @ nRow, 00 PRINT TO oPrn TEXT  "Caja N°:"+STR(oQryI:caja,4) ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow  ALIGN "C"        
          @ nRow, 00 PRINT TO oPrn TEXT  "Fecha de operación:"+DTOC(oQryI:fecemi);
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  "VALE DE CLIENTES" ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  oQryI:nombre ;
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
   PRINT oPrn PREVIEW
          oPrn:oFont := oFont
          nRow := .5
          PAGE

          @ nRow, 00 PRINT TO oPrn TEXT "DOCUMENTO NO VALIDO" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "COMO FACTURA" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"    
          @ nRow, 00 PRINT TO oPrn TEXT "VALE Nro:" + STR(oQryI:numero,8) ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"          
          @ nRow, 00 PRINT TO oPrn TEXT  "Caja N°:"+STR(oQryI:caja,4) ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow  ALIGN "C"        
          @ nRow, 00 PRINT TO oPrn TEXT  "Fecha de operación:"+DTOC(oQryI:fecha);
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  "VALE DE CLIENTES" ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT  oQryI:nombre ;
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
RETURN NIL