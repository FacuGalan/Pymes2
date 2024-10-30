#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** Pagos a proveedores - ordenes de pago
*************************************************
MEMVAR oApp
STATIC oGet, oDlg, oBot, mefectivo, mfecha, mtarjeta, mcheques, mpagado, manticipo, macuenta, mcodpro, mentrega,;
       oBrw, oBrwDet, oQry, oQryDet, mtotal1, mtotal, lEdita, oQryCue, oQryBan, oQryPro, oQryChe
PROCEDURE ordpag
LOCAL oFont, oFo1,  oSay1, mnompro,  mobserva, mrta := .f., aObserva := {}
oGet := ARRAY(12)
oBot := ARRAY(07)
manticipo := 0
mentrega  := 0
mtotal1 := 0
mtotal  := 0
mcodpro := 0
lEdita := .t.
mfecha  := DATE()
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_ordpag` ("+;
                           "`ticomp` VARCHAR(2) NOT NULL,"+;
                           "`letra` VARCHAR(1) NOT NULL,"+;
                           "`numcomp` VARCHAR(13) NOT NULL,"+;
                           "`fecha` DATE NOT NULL,"+;
                           "`saldo` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`pagado` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`saldonue` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "PRIMARY KEY (ticomp,numcomp) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_ordpag")
oApp:oServer:NextResult()
oQryPro:= oApp:oServer:Query("SELECT codigo,nombre,saldo FROM provee")
oQryCue := oApp:oServer:Query("SELECT codigo,nombre FROM cuentas")
oQryBan := oApp:oServer:Query("SELECT codigo,nombre FROM bancos")
oQryDet:= oApp:oServer:Query("SELECT e.codpro AS codpro, e.numfac AS numfac, e.letra AS letra, e.tipocomp AS tipocomp, "+;
                             " e.codart AS codart,a.nombre AS detart, e.cantidad AS cantidad, "+;
                             "       e.pcosto AS preciouni, e.pcosto * e.cantidad AS preciotot "+;
                             "  FROM compradet e LEFT JOIN articu a ON e.codart = a.codigo LIMIT 0")
DO WHILE .T.
   oQry:= oApp:oServer:Query("SELECT * FROM transi_ordpag")
   DEFINE FONT oFont NAME "ARIAL" SIZE 12,-16 BOLD
   DEFINE FONT oFo1  NAME "COURIER NEW" SIZE 08,-10
   DEFINE DIALOG oDlg RESOURCE "PAGOS" OF oApp:oWnd TITLE "Ordenes de pago"
    oDlg:lHelpIcon := .f.
    REDEFINE SAY oSay1 PROMPT "Proveedor:" ID 111 OF oDlg
    REDEFINE GET oGet[1] VAR mcodpro  ID 112 OF oDlg PICTURE "99999";
             VALID(Buscar(oQryPro,oDlg,oGet[01],oGet[02]));
             ACTION (oGet[01]:cText:= 0, Buscar(oQryPro,oDlg,oGet[01],oGet[02])) BITMAP "BUSC1" WHEN(lEdita)
    REDEFINE GET oGet[2] VAR mnompro  ID 113 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[3] VAR mfecha ID 114 OF oDlg PICTURE "@D" 
    REDEFINE GET oGet[6] VAR mentrega  ID 116 OF oDlg PICTURE "99999999.99" WHEN(lEdita) VALID(mentrega>=0)
    REDEFINE GET oGet[5] VAR manticipo ID 117 OF oDlg PICTURE "99999999.99" WHEN((oGet[5]:cText := oQryPro:saldo)=SPACE(10))
    REDEFINE BUTTON oBot[1] ID 115 OF oDlg ACTION Mostrar() WHEN(lEdita)
    REDEFINE BUTTON oBot[6] ID 106 OF oDlg WHEN(.f.)
    REDEFINE BUTTON oBot[7] ID 107 OF oDlg WHEN(.f.)
    REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "ticomp","letra","numcomp","fecha","saldo","pagado","saldonue";
              HEADERS "Tipo","L","Nro. Compr.","Fecha","Saldo","Pagado","Nuevo Saldo" FOOTERS;
              SIZES 60,20,130,100,100,95,95 ID 120 OF oDlg ON CHANGE Actuali()       
    oBrw:aCols[5]:nFooterType := AGGR_SUM
    oBrw:aCols[6]:nFooterType := AGGR_SUM
    oBrw:aCols[7]:nFooterType := AGGR_SUM
    PintaBrw(oBrw,0)            
    REDEFINE XBROWSE oBrwDet DATASOURCE oQryDet;
              COLUMNS "codart","detart","cantidad","preciouni","preciotot";
              HEADERS "Codigo","Detalle","Cant","P.Unit","P.Total";
              PICTURE "99999999","@!","999999.999","99999999.99","9999999999.99";
              SIZES 60,275,90,90,90 ID 105 OF oDlg 
    PintaBrw(oBrwDet,0)           
    REDEFINE GET oGet[10] VAR mtotal  ID 121 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "99999999.99" WHEN(.F.)
    REDEFINE GET oGet[12] VAR mtotal1 ID 122 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "99999999.99" WHEN(.F.)
    REDEFINE BUTTON oBot[2] ID 102 OF oDlg ACTION IF(graba(),oDlg:End(),.T.) WHEN(oQry:nRecCount>0 .AND. !lEdita)
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg ACTION Cancela()
    REDEFINE BUTTON oBot[4] ID 104 OF oDlg ACTION (oDlg:End(),mrta:=.f.) CANCEL
   ACTIVATE DIALOG oDlg CENTER ON INIT (oBot[6]:Hide(),oBot[7]:Hide())
   IF !mrta
      EXIT
   ENDIF
ENDDO
Cerrar(oGet[1],oDlg)
oQryPro:End()
oFont:End()
oFo1:End()
RETURN

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (oGet,oWnd)
LOCAL j, i, aNueva := {}
oGet:SetFocus()
oWnd:Refresh()
oQry:End()
RETURN .t.

*****************************************
** Grabar
STATIC FUNCTION Graba()
LOCAL  mrta, oError, nNumero, oRep
IF oBrw:aCols[5]:nTotal <= 0
   MsgStop("No marco ninguna factura para pagar","Atencion")   
   RETURN .f.
ENDIF
IF !formapag()
   RETURN .f.
ENDIF

TRY 
   oApp:oServer:BeginTransaction()
   nNumero := oApp:oServer:GetAutoIncrement("ordpag")
   ** Actualizo saldos de facturas
   oQry:GoTop()
   DO WHILE !oQry:Eof()
      oApp:oServer:Execute("UPDATE compras SET saldo = " + ClipValue2Sql(oQry:saldonue) + ;
                              " WHERE tipocomp = " + ClipValue2Sql(oQry:ticomp) +;
                              " AND   letra    = " + ClipValue2Sql(oQry:letra) +;
                              " AND   numfac   = " + ClipValue2Sql(oQry:numcomp) +;
                              " AND   codpro   = " + ClipValue2Sql(mcodpro) )      
      oQry:Skip()
   ENDDO
   ** Agrego pago 
   oApp:oServer:Execute("INSERT INTO ordpag " + ;
                        " (provee, total, fecha, caja, efectivo, cheques, tarjeta, anticipo) VALUES "+;
                        " ("+ClipValue2Sql(mcodpro)+","+ClipValue2Sql(mefectivo+mtarjeta+mcheques)+","+;
                            ClipValue2Sql(mfecha)+","+;
                            ClipValue2Sql(oApp:prefijo)+","+;
                            ClipValue2Sql(mefectivo)+","+;
                            ClipValue2Sql(mcheques)+","+;
                            ClipValue2Sql(mtarjeta)+","+;
                            ClipValue2Sql(manticipo)+;
                              ") " )   
   oApp:oServer:NextResult()
   ** Actualizo saldo de proveedores si tiene a favor
   oApp:oServer:Execute("UPDATE provee  SET saldo = " + ClipValue2Sql(ABS(macuenta)) )
   oApp:oServer:NextResult()   
   ***** Agrego cheques propios
   oApp:oServer:Execute("INSERT INTO chepro (numban,numche,fecemi,fecvto,importe,orden,codpro) "+;
                        " ( SELECT numban,numche,fecemi,fecvto,importe," +;
                                 ClipValue2Sql(nNumero) + "," + ClipValue2Sql(mcodpro) +;
                                  " FROM transi_cheque WHERE tipo = 1)")
   ***** Modifico cheques de tercero
   oQryChe:GoTop()
   DO WHILE !oQryChe:Eof()
      IF oQryChe:tipo = 2
         oApp:oServer:Execute("UPDATE cheter SET orden = " + ClipValue2Sql(nNumero) + ;
                              ", codpro = " +  ClipValue2Sql(mcodpro) + ;
                              " WHERE numban = " + ClipValue2Sql(oQryChe:numban) +;
                              " AND   numche = " + ClipValue2Sql(oQryChe:numche) )
      ENDIF
      oQryChe:Skip()
   ENDDO
   oApp:oServer:CommitTransaction()
   CATCH oError
   ValidaError(oError)
   RETURN .f.
END TRY




mrta := MsgYesNo("Desea Imprimir la Orden Pagada","Atencion")
IF mrta   
   oQry:GoTop()
   REPORT oRep TITLE "Detalle del pago";
          HEADER " "," ","Documento no valido como factura",;
                 "Nro de O.Pago:" + STR(nNumero),;
                 "Fecha de operacion:" + DTOC(mfecha) ,;
                 "Proveedor:" + STR(mcodpro,6) + "  " + oQryPro:nombre,;
                 "Anticipo:" + STR(manticipo,14,2),;
                 "Efectivo:" + STR(mefectivo,14,2),;
                 "Tarjetas:" + STR(mtarjeta,14,2),;
                 "Cheques:" + STR(mcheques,14,2),;
                 "A Cta. :" + STR(ABS(macuenta),14,2),;
                 "Saldo anterior:" + STR(mtotal1,14,2),;
                 "Nuestro Pago:" + STR(mefectivo+mtarjeta+mcheques,14,2),;
                 "Nuestro Saldo:" + STR(oBrw:aCols[7]:nTotal,14,2) LEFT ;
          PREVIEW CAPTION  "Orden de pago"
   COLUMN TITLE "Tipo"    DATA oQry:ticomp    SIZE 04 GRID
   COLUMN TITLE "Nro"     DATA oQry:numcomp   SIZE 16 GRID
   COLUMN TITLE "Fecha"   DATA oQry:fecha     SIZE 10 GRID
   COLUMN TITLE "Deuda"   DATA oQry:saldo     SIZE 10 GRID
   COLUMN TITLE "Cancela" DATA oQry:pagado    SIZE 10 TOTAL GRID
   COLUMN TITLE "Saldo"   DATA oQry:saldonue  SIZE 10 TOTAL GRID
   oRep:bInit := {|| oQry:GoTop() }
   oRep:bSkip := {|| oQry:Skip() }
   END REPORT
   // Activo el reporte
   ACTIVATE REPORT oRep WHILE !oQry:Eof() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",1.5,.5)
ENDIF
Cancela()
RETURN .t.

*****************************************
** Cancelar
STATIC FUNCTION Cancela()
oQry:Zap()
Actuali()
oBrw:Refresh()
oBrwDet:Refresh()
lEdita := .t.
oGet[1]:SetFocus()
RETURN nil

*****************************************
** Cargar deuda
STATIC FUNCTION Mostrar()
LOCAL mentre := mentrega + manticipo
oQry:Zap()
oApp:oServer:Execute("INSERT INTO transi_ordpag (ticomp,letra,numcomp,fecha,saldo,pagado,saldonue) "+;
                     "SELECT c.tipocomp AS ticomp,c.letra AS letra,c.numfac AS numcomp, c.fecfac AS fecha, "+;
                     " c.saldo * IF(c.tipocomp = 'NC', -1,1) AS saldo, "+;
                     " 0 as pagado, c.saldo * IF(c.tipocomp = 'NC', -1,1) AS saldonue  "+;
                     "FROM compras c "+;
                     "WHERE c.codpro = " + ClipValue2Sql(mcodpro) + " AND " +;
                     " c.saldo > 0 ")
oApp:oServer:NextResult()
oQry:Refresh()
DO WHILE !oQry:Eof()
   IF oQry:ticomp = "NC"
      oQry:pagado   := oQry:saldo
      oQry:saldonue := 0
      mentre := mentre + ABS(oQry:saldo)
      oQry:Save()
   ENDIF   
   oQry:Skip()
ENDDO
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF oQry:ticomp <> "NC" .and. mentre > 0
      IF mentre > oQry:saldo
         mentre := mentre - oQry:saldo
         oQry:pagado := oQry:saldo
         oQry:saldonue := 0
         oQry:Save()
         ELSE
         oQry:pagado := mentre
         oQry:saldonue := oQry:saldo - oQry:pagado
         mentre := 0
         oQry:Save()
      ENDIF   
   ENDIF
   oQry:Skip()
ENDDO
oQry:GoTop()
oBrw:Refresh()
oBrw:MakeTotals()
mtotal := oBrw:aCols[5]:nTotal
mtotal1:= oBrw:aCols[5]:nTotal - oGet[5]:Value
Actuali()
IF oQry:nRecCount = 0
   MsgInfo("Proveedor sin deuda pendiente","Atencion")
   ELSE
   lEdita := .f.
ENDIF
oGet[12]:Refresh()
oGet[10]:Refresh()   
oBrw:SetFocus()
RETURN nil 


***********************************************
** Busca los articulos vendidos en cada factura
STATIC FUNCTION Actuali()
LOCAL cWhere
cWhere := "codpro = " + ClipValue2Sql(mcodpro) + " AND numfac = " +;
          ClipValue2Sql(oQry:numcomp) + " AND tipocomp = " + ClipValue2Sql(oQry:ticomp) +;
          " AND letra = " + ClipValue2Sql(oQry:letra)
oQryDet:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrwDet:Refresh()
RETURN .t.


***********************************************
** Forma de pago
STATIC FUNCTION formapag()
LOCAL oGet1 := ARRAY(7), oBrw2, oBot := ARRAY(4),;
      oDlg2, mrta := .f.
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_cheque` ("+;
                           "`tipo` int(1) NOT NULL DEFAULT 1,"+;
                           "`NUMBAN` int(6) NOT NULL DEFAULT 1,"+;
                           "`NUMCHE` int(10) NOT NULL DEFAULT 0,"+;
                           "`FECEMI` date DEFAULT NULL,"+;
                           "`FECVTO` date DEFAULT NULL,"+;
                           "`IMPORTE` decimal(12,2) DEFAULT 0,"+;
                           "`ORDEN` int(8) DEFAULT 0,"+;
                           "`CODPRO` int(8) DEFAULT 0, "+;
                           "`ESTADO` varchar(1) DEFAULT ' ',"+;
                           "`CODCLI` int(8) DEFAULT 0,"+;
                           "`RECIBO` int(8) DEFAULT 0,"+;
                           "PRIMARY KEY (tipo,numban,numche) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_cheque")
oApp:oServer:NextResult()      
oQryChe := oApp:oServer:Query("SELECT * FROM transi_cheque")
mefectivo := IF(manticipo < oBrw:aCols[6]:nTotal, oBrw:aCols[6]:nTotal - manticipo,0)
mtarjeta := 0
mcheques := 0
macuenta := 0
mpagado  := mentrega + manticipo
DEFINE DIALOG oDlg2 RESOURCE "FORMAPAG" OF oDlg
    oDlg2:lHelpIcon := .f.
    REDEFINE GET oGet1[1] VAR mpagado   ID 110 OF oDlg2 PICTURE "9999999.99" WHEN(.F.)
    REDEFINE GET oGet1[2] VAR manticipo ID 111 OF oDlg2 PICTURE "9999999.99" WHEN(.f.)
    REDEFINE GET oGet1[3] VAR mefectivo ID 112 OF oDlg2 PICTURE "9999999.99"
    REDEFINE GET oGet1[4] VAR mtarjeta  ID 113 OF oDlg2 PICTURE "9999999.99"
    REDEFINE GET oGet1[7] VAR mcheques  ID 114 OF oDlg2 PICTURE "9999999.99" WHEN(.F.)
    REDEFINE GET oGet1[6] VAR macuenta  ID 115 OF oDlg2 PICTURE "9999999.99";
                    WHEN((oGet1[6]:cText := mpagado - (manticipo+mefectivo+;
                                      mtarjeta+mcheques)) = "-9999999")
    REDEFINE BUTTON oBot[1] ID 116 OF oDlg2 ACTION ;
               (AddCheq(oBot[1]),oBrw2:Refresh(),oBrw2:MakeTotals(),;
                                oGet1[7]:cText := oBrw2:aCols[6]:nTotal,oGet1[7]:Refresh())
    REDEFINE XBROWSE oBrw2  ID 120  OF oDlg2 DATASOURCE oQryChe ;
              COLUMNS "tipo","numban","numche","fecemi","fecvto","importe";
              HEADERS "Tipo","Banco","Numero","Emision","Vto.","Importe" FOOTERS;
              SIZES 30,45,55,70,70,70
    oBrw2:bKeyDown := { | nKey, nFlags |;
       IF(nKey==46,IF(MsgNoYes("Borra el cheque?"),;
                     (oQryChe:Delete(),oBrw2:Refresh(),oBrw2:MakeTotals(),;
                      oGet1[7]:cText := oBrw2:aCols[6]:nTotal, oGet1[7]:Refresh(), oGet1[3]:SetFocus()),;
                     .f.),.f.)}      
    oBrw2:aCols[6]:nFooterType := AGGR_SUM
    PintaBrw(oBrw2,0)        
    REDEFINE BUTTON oBot[2] ID 102 OF oDlg2 ACTION (mrta:=.t.,oDlg2:End()) WHEN(macuenta <=0)
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg2 ACTION oDlg2:End()
ACTIVATE DIALOG oDlg2 CENTER
oDlg:Refresh()
RETURN mrta

*************************************************
** Elegir que tipo de cheque agregar
STATIC FUNCTION AddCheq(oWnd)
LOCAL oMen, oMenI
MENU oMen POPUP
     MENUITEM oMenI PROMPT "Cheque Propio" ACTION ;
              AddCheqP(oWnd)
     MENUITEM oMenI PROMPT "Cheque Tercero" ACTION ;
              AddCheqT(oWnd)
ENDMENU
ACTIVATE POPUP oMen OF oWnd
RETURN nil


*************************************************
** Agregar cheques de propio
STATIC FUNCTION AddCheqP(oWnd)
LOCAL oGet2 := ARRAY(12), oBot2 := ARRAY(2) , oDlg3, cNomCue := SPACE(30), cNomPro := SPACE(30),;
      mrta := .f., aCor, oQryChe1, base, oError, oFont
DO WHILE .T.
base := oQryChe:GetBlankRow()
base:tipo  := 1
base:orden := oApp:oServer:GetAutoIncrement("ordpag")
base:importe := IF(macuenta>0,macuenta,0)
base:codpro  := mcodpro
base:fecemi  := DATE()
base:fecvto  := DATE()
cNomPro      := oQryPro:nombre
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DEFINE DIALOG oDlg3 TITLE "Alta de Cheques propios" FROM 05,15 TO 23,66 OF oWnd FONT oFont
   acor := AcepCanc(oDlg3)
   @ 07, 05 SAY "Cuenta:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Numero:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Entregado a:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "En Orden:"      OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Emision:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 82, 05 SAY "Vencimiento:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 97, 05 SAY "Importe:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet2[1] VAR base:numban  PICTURE "999" OF oDlg3 PIXEL SIZE 25,12 RIGHT;
                VALID(Buscar(oQryCue,oDlg3,oGet2[1],oGet2[2]) );
                ACTION (oGet2[1]:cText:= 0, Buscar(oQryCue,oDlg3,oGet2[1],oGet2[2])) BITMAP "BUSC1"         
   @ 05, 80 GET oGet2[2] VAR cNomCue OF oDlg3 PIXEL PICTURE "@!" WHEN(.F.)   
   @ 20, 50 GET oGet2[3] VAR base:numche  PICTURE "9999999999"  OF oDlg3 PIXEL ;
                VALID(base:numche > 0) RIGHT
   @ 35, 50 GET oGet2[4] VAR base:codpro OF oDlg3  PICTURE "999999" PIXEL RIGHT WHEN(.F.)
   @ 35, 80 GET oGet2[5] VAR cNomPro OF oDlg3 SIZE 110,12  PIXEL WHEN(.F.)
   @ 50, 50 GET oGet2[6] VAR base:orden PICTURE "99999999" PIXEL OF oDlg3 RIGHT WHEN(.F.)
   @ 65, 50 GET oGet2[7] VAR base:fecemi   PICTURE "@D" PIXEL OF oDlg3 CENTER
   @ 80, 50 GET oGet2[8] VAR base:fecvto   PICTURE "@D" PIXEL OF oDlg3 VALID(base:fecvto >= base:fecemi) CENTER
   @ 95, 50 GET oGet2[9] VAR base:importe  PICTURE "99999999.99" PIXEL OF oDlg3 RIGHT VALID(base:importe>0)
   @ acor[1],acor[2] BUTTON oBot2[1] PROMPT "&Grabar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg3:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2[2] PROMPT "&Cancelar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg3:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg3 CENTER ON INIT oGet2[1]:SetFocus()
IF !mRta
   RETURN nil
ENDIF
oQryChe1 := oApp:oServer:Query("SELECT * FROM chepro WHERE numban = " + ClipValue2Sql(base:numban) +;
                               " AND numche = " + ClipValue2Sql(base:numche) )
IF oQryChe1:nRecCount > 0
   MsgStop("Cheque ya existe", "Error")
   LOOP
ENDIF   
oQryChe:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryChe:Save()
  oQryChe:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

*************************************************
** Agregar cheques de tercero al pago
STATIC FUNCTION AddCheqT(oWnd)
LOCAL oGet2 := ARRAY(12), oBot2 := ARRAY(2) , oDlg3, cNomCue := SPACE(30), cNomPro := SPACE(30),;
      mrta := .f., aCor, oQryChe1, base, oError, oFont
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
base := oQryChe:GetBlankRow()
base:tipo  := 2
base:orden := oApp:oServer:GetAutoIncrement("ordpag")
base:importe := IF(macuenta>0,macuenta,0)
base:codpro  := mcodpro
cNomPro      := oQryPro:nombre

DEFINE DIALOG oDlg3 TITLE "Alta de Cheques de terceros" FROM 05,15 TO 27,75 OF oWnd FONT oFont
   acor := AcepCanc(oDlg3)
   @ 07, 05 SAY "Banco:"         OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Numero:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Entregado a:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "En Orden:"      OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Emision:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 82, 05 SAY "Vencimiento:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 97, 05 SAY "Importe:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @112, 05 SAY "Recibido de:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @127, 05 SAY "En Recibo:"     OF oDlg3 PIXEL SIZE 40,12 RIGHT
   
   @ 05, 50 GET oGet2[1] VAR base:numban  PICTURE "999" OF oDlg3 PIXEL SIZE 25,12 RIGHT;
                VALID(Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2]) );
                ACTION (oGet2[1]:cText:= 0, Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2])) BITMAP "BUSC1"         
   @ 05, 85 GET oGet2[2] VAR cNomCue OF oDlg3 PIXEL PICTURE "@!" WHEN(.F.)   
   @ 20, 50 GET oGet2[3] VAR base:numche  PICTURE "9999999999"  OF oDlg3 PIXEL ;
                VALID(BusChe(base:numban,base:numche,oGet2)) RIGHT
   @ 35, 50 GET oGet2[5] VAR cNomPro   OF oDlg3 PIXEL WHEN(.F.)
   @ 50, 50 GET oGet2[6] VAR base:orden    PICTURE "99999999" PIXEL OF oDlg3 RIGHT WHEN(.F.)
   @ 65, 50 GET oGet2[7] VAR base:fecemi   PICTURE "@D" PIXEL OF oDlg3 CENTER WHEN(.f.)
   @ 80, 50 GET oGet2[8] VAR base:fecvto   PICTURE "@D" PIXEL OF oDlg3 CENTER WHEN(.f.)
   @ 95, 50 GET oGet2[9] VAR base:importe  PICTURE "99999999.99" PIXEL OF oDlg3 RIGHT WHEN(.f.)
   @110, 50 GET oGet2[10] VAR base:codcli  PICTURE "99999" OF oDlg3 PIXEL RIGHT WHEN(.f.)
   @125, 50 GET oGet2[12] VAR base:recibo  PICTURE "99999999" PIXEL OF oDlg3 RIGHT WHEN(.f.)
   @ acor[1],acor[2] BUTTON oBot2[1] PROMPT "&Grabar" OF oDlg3 SIZE 30,10 ACTION ((mrta := .t.), oDlg3:End()) PIXEL
   @ acor[3],acor[4] BUTTON oBot2[2] PROMPT "&Cancelar" OF oDlg3 SIZE 30,10 ACTION ((mrta := .f.), oDlg3:End() ) PIXEL
ACTIVATE DIALOG oDlg3 CENTER 
IF !mrta
   RETURN nil
ENDIF
oQryChe:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryChe:Save()
  oQryChe:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


***************************************************
** Busca el cheque de tercero
STATIC FUNCTION BusChe(mcodban,mnumero,oGet)
LOCAL oQryChe1
oQryChe1 := oApp:oServer:Query("SELECT * FROM cheter WHERE numban = " + ClipValue2Sql(mcodban) +;
                               " AND numche = " + ClipValue2Sql(mnumero) )
IF oQryChe1:nRecCount = 0
   MsgStop("Cheque no existe","Error")
   oGet[7]:cText := CTOD("  /  /    ")
   oGet[8]:cText := CTOD("  /  /    ")
   oGet[9]:cText := 0
   oGet[10]:cText := 0
   oGet[12]:cText := 0
   RETURN .f.
ENDIF    
IF oQryChe1:orden <> 0
   MsgInfo("Cheque no esta en cartera, Usado en Orden "+STR(oQryChe1:orden),"Atencion")
   RETURN .f.
ENDIF
oGet[07]:cText := oQryChe1:fecing
oGet[08]:cText := oQryChe1:fecvto
oGet[09]:cText := oQryChe1:importe
oGet[10]:cText := oQryChe1:codcli
oGet[12]:cText := oQryChe1:recibo
RETURN .t.