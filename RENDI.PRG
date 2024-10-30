#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "Report.ch"
************************************************************************************************
** POS
************************************************************************************************
MEMVAR oApp
STATIC oDlg1, nCodVen, oBrwResu, oQryResu,;
       nEfectivo, nCheque, nDescuento, nEfectivoE, nChequeE, nFalta, mnomcli,;
       oGet, oDlg, oBot, mefectivo, mfecha, mtarjeta, mcheques, mpagado, manticipo, macuenta, mcodcli, mentrega,;
       oBrw, oBrwDet, oQry, oQryDet, mtotal1, mtotal, lEdita, oQryBan, oQryCli, oQryChe, oQryPun
PROCEDURE RENDI() 
LOCAL oGet1:=ARRAY(40),oBot1:=ARRAY(10), cNomVen:=SPACE(30), dFecha:=DATE(), lRta:=.f.,;      
      oQryVen, oError

//TABLAS TRANSITORIA NECESARIAS
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_ventas` ("+;
                           "`codcli` INT(8) NOT NULL,"+;
                           "`ticomp` VARCHAR(2) NOT NULL,"+;                           
                           "`numcomp` VARCHAR(14) NOT NULL,"+;
                           "`saldo` DECIMAL(10,2) DEFAULT 0 NOT NULL, "+;
                           "PRIMARY KEY (ticomp,numcomp) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_ventas")
oApp:oServer:NextResult()

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_det` ("+;
                           "`numero`  INT(3) NOT NULL,"+;                           
                           "`cliente` INT(8) NOT NULL,"+;
                           "`total` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "`fecha` DATE NOT NULL,"+;
                           "`CAJA` INT(4) NOT NULL,"+;
                           "`efectivo` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "`cheques` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "`tarjeta` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "`anticipo` DECIMAL(10,2) DEFAULT 0 NOT NULL) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_det")
oApp:oServer:NextResult()

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_saldos` ("+;
                           "`codcli` INT(8) NOT NULL,"+;
                           "`saldo` DECIMAL(10,2) DEFAULT 0 NOT NULL) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_saldos")
oApp:oServer:NextResult()
                                
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_cheter` ("+;
                             "`numban`  INT(6) NOT NULL,"+;
                             "`numche`  INT(6) NOT NULL,"+;
                             "`fecing` DATE NOT NULL,"+;
                             "`fecvto` DATE NOT NULL,"+;
                             "`importe` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                             "`recibo`  INT(8) NOT NULL,"+;
                             "`codcli`  INT(8) NOT NULL) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_cheter")
oApp:oServer:NextResult()
                            
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_comision` ("+;
                              "`vendedor`  INT(8) NOT NULL,"+;
                              "`codcli`  INT(8) NOT NULL,"+;
                              "`factura` VARCHAR(16) NOT NULL,"+;
                              "`fechafc` DATE NOT NULL,"+;
                              "`fecha` DATE NOT NULL,"+;
                              "`importe` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                              "`comision` DECIMAL(6,2) DEFAULT 0 NOT NULL,"+;
                              "`comipesos` DECIMAL(10,2) DEFAULT 0 NOT NULL) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_comision")
oApp:oServer:NextResult()


oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS temp_Resu ";
    +"("; 
    +"`codcli`   INT(8) NOT NULL ,";
    +"`nombre`   VARCHAR(50) NOT NULL,";
    +"`pagado`  DECIMAL(10,2) DEFAULT '0.00') ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE temp_Resu")
oApp:oServer:NextResult()

//CONSULTAS INICIALES
oQryVen:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedor")
oQryResu:= oApp:oServer:Query("SELECT * FROM temp_Resu")



nCodVen:=0
nEfectivo:=0
nCheque:=0
nDescuento:=0
nEfectivoE:=0
nChequeE:=0
nFalta:=0




   DEFINE DIALOG oDlg1 RESOURCE "RENDI" OF oApp:oWnd 
   oDlg1:lHelpIcon := .f.
   
   REDEFINE GET oGet1[01] VAR nCodVen       ID 101 OF oDlg1;
                VALID(Buscar(oQryVen,oDlg1,oGet1[01],oGet1[02]));
                ACTION(oGet1[01]:cText:= 0, Buscar(oQryVen,oDlg1,oGet1[01],oGet1[02])) BITMAP "BUSC1"
   REDEFINE GET oGet1[02] VAR cNomVen       ID 102 OF oDlg1 WHEN(.F.)
   REDEFINE GET oGet1[03] VAR dFecha        ID 103 OF oDlg1 
   REDEFINE GET oGet1[04] VAR nEfectivo     ID 104 OF oDlg1 PICTURE "999999999.99";
                          VALID((oGet1[09]:cText:= nEfectivo + nCheque - nEfectivoE - nChequeE) <> "xxx")
   REDEFINE GET oGet1[05] VAR nCheque       ID 105 OF oDlg1 PICTURE "999999999.99";
                          VALID((oGet1[09]:cText:= nEfectivo + nCheque - nEfectivoE - nChequeE) <> "xxx")
   REDEFINE GET oGet1[06] VAR nDescuento    ID 106 OF oDlg1 PICTURE "999999999.99"
   REDEFINE GET oGet1[07] VAR nEfectivoE    ID 108 OF oDlg1 PICTURE "999999999.99" WHEN(.F.)
   REDEFINE GET oGet1[08] VAR nChequeE      ID 109 OF oDlg1 PICTURE "999999999.99" WHEN(.F.)
   REDEFINE GET oGet1[09] VAR nFalta        ID 110 OF oDlg1 PICTURE "999999999.99" WHEN(.F.)



    //Detalle de pagos de clientes
     REDEFINE XBROWSE oBrwResu DATASOURCE oQryResu;
                COLUMNS "codcli","nombre","Pagado";
                HEADERS "Codigo","Cliente","Pagado";
                FOOTERS;
                SIZES 100,350,135 ID 107 OF oDlg1
    PintaBrw(oBrwResu,0)
    oBrwResu:aCols[3]:nFooterTypE := AGGR_SUM
    oBrwResu:MakeTotals()
    
    REDEFINE BUTTON oBot1[1] ID 201 OF oDlg1 ACTION (cobran(oGet1))
    REDEFINE BUTTON oBot1[2] ID 202 OF oDlg1 ACTION (lRta := .t.,oDlg1:End());
                    WHEN(nEfectivo = nEfectivoE .and. nCheque = nChequeE)
    REDEFINE BUTTON oBot1[3] ID 203 OF oDlg1 ACTION (Reiniciar(oGet1))
    REDEFINE BUTTON oBot1[4] ID 204 OF oDlg1 ACTION (lRta := .f.,oDlg1:End()) CANCEL
                   
                      
   ACTIVATE DIALOG oDlg1 CENTER  //VALID(oQryDet:RecCount() = 0)
   IF !lRta    
      RETURN
   ENDIF
   
   TRY 
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas v LEFT JOIN transi_ventas tv ON v.ticomp = tv.ticomp "+;                              
                                                             "AND   v.numcomp  = tv.numcomp "+;
                                                             "AND   v.codcli = tv.codcli "+;
                       "SET v.saldo = tv.saldo "+;
                       "WHERE v.ticomp = tv.ticomp "+;                              
                       "AND   v.numcomp  = tv.numcomp "+;
                       "AND   v.codcli = tv.codcli")  
   oApp:oServer:NextResult()
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagos " + ;
                        " (numero,cliente, total, fecha, caja, efectivo, cheques, tarjeta, anticipo) "+;
                        " (SELECT numero,cliente,total,fecha,caja,efectivo,cheques,tarjeta,anticipo FROM transi_det)")
   oApp:oServer:NextResult() 
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes c LEFT JOIN transi_saldos s ON c.codigo = s.codcli "+;
                        "SET c.saldo =  s.saldo "+;
                        "WHERE c.codigo = s.codcli")
   oApp:oServer:NextResult() 
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"cheter (numban,numche,fecing,fecvto,importe,recibo,codcli) "+;
                        " ( SELECT numban,numche,fecing,fecvto,importe,recibo,codcli FROM transi_cheter)")   
   oApp:oServer:NextResult()
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"comision (vendedor,codcli,factura,fechafc,fecha,importe,comision,comipesos) "+;
                        " ( SELECT vendedor,codcli,factura,fechafc,fecha,importe,comision,comipesos FROM transi_comision)")  
   oApp:oServer:NextResult()
      oApp:oServer:CommitTransaction()
   CATCH oError
   ValidaError(oError)
  RETURN 
END TRY
RETURN

***************************************************************************************************
******************
STATIC FUNCTION Reiniciar(oGet1)
oGet1[01]:cText:= 0
oGet1[02]:cText:= ""
oGet1[04]:cText:= 0
oGet1[05]:cText:= 0
oGet1[06]:cText:= 0
oGet1[07]:cText:= 0
oGet1[08]:cText:= 0 
oGet1[09]:cText:= 0

oApp:oServer:Execute("TRUNCATE transi_ventas")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_det")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_saldos")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_cheter")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_comision")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE temp_Resu")
oApp:oServer:NextResult()
oQryResu:Refresh()
oBrwResu:Refresh()
oGet1[01]:SetFocus()
RETURN nil

****************************************************************************************************
****************************************
STATIC FUNCTION cobran(oGet1)
LOCAL oFont, oFo1,  oSay1,  mobserva, mrta := .f., aObserva := {}, oQryValida
oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2Sql(oApp:cIP))
IF oQryPun:nRecCount = 0
   MsgStop("Terminal no autorizada!!")   
   RETURN nil
   ELSE
   IF !oQryPun:recibo
      MsgStop("Esta terminal no permite cobranzas!!")            
      RETURN nil
   ENDIF
   IF oQryPun:recibot <> 2 .and. oQryPun:recibot <> 3
      MsgStop("Esta terminal no permite cobranzas de Distribucion!!")            
      RETURN nil
   ENDIF
ENDIF  
oQryValida:= oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"clientes WHERE tipocli = '2' AND vendedor = " +;
                                 ClipValue2Sql(nCodVen))
IF oQryValida:RecCount() = 0
   MsgStop("El vendedor seleccionado no tiene clientes asignados!")
   oGet1[01]:SetFocus()
   RETURN nil
ENDIF
oGet := ARRAY(12)
oBot := ARRAY(07)
manticipo := 0
mentrega  := 0
mtotal1 := 0
mtotal  := 0
mcodcli := 0
lEdita := .t.
mfecha  := DATE()

//TEMPORAL DE PAGOS DEL CLIENTE
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_pagos1` ("+;
                           "`ticomp` VARCHAR(2) NOT NULL,"+;                           
                           "`numcomp` VARCHAR(14) NOT NULL,"+;
                           "`fecha` DATE NOT NULL,"+;
                           "`saldo` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "`pagado` DECIMAL(10,2) DEFAULT 0 NOT NULL, "+;
                           "`saldonue` DECIMAL(10,2) DEFAULT 0 NOT NULL, "+;
                           "`vendedor` INT(4) DEFAULT 0 NOT NULL, "+;
                           "`comision` DECIMAL(6,2) DEFAULT 0 NOT NULL, "+;
                           "PRIMARY KEY (ticomp,numcomp) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_pagos1")
oApp:oServer:NextResult()


//CONSULTAS INICIALES
oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ")
oQryBan := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"bancos")
oQryDet:= oApp:oServer:Query("SELECT s.codcli AS codcli, s.numfac AS numfac, s.bultos AS bultos, "+;
                             " s.codart AS codart,s.detart AS detart, s.cantidad AS cantidad, "+;
                             "       s.punit AS preciouni, s.importe AS preciotot "+;
                             "  FROM ge_"+oApp:cId+"ventadet s LIMIT 0")
DO WHILE .T.
   oQry:= oApp:oServer:Query("SELECT * FROM transi_pagos1")
   DEFINE FONT oFont NAME "ARIAL" SIZE 12,-16 BOLD
   DEFINE FONT oFo1  NAME "COURIER NEW" SIZE 08,-10
   DEFINE DIALOG oDlg RESOURCE "PAGOS" OF oDlg1 TITLE "Recibos de cobros"
    oDlg:lHelpIcon := .f.
    REDEFINE SAY oSay1 PROMPT "Cliente:" ID 111 OF oDlg
    REDEFINE GET oGet[1] VAR mcodcli  ID 112 OF oDlg PICTURE "99999";
             VALID(Buscar(oQryCli,oDlg,oGet[01],oGet[02],"2","tipocli",ClipValue2Sql(nCodVen),"vendedor"));
             ACTION (oGet[01]:cText:= 0, Buscar(oQryCli,oDlg,oGet[01],oGet[02],;
                     "2","tipocli",ClipValue2Sql(nCodVen),"vendedor")) BITMAP "BUSC1" WHEN(lEdita)
    REDEFINE GET oGet[2] VAR mnomcli  ID 113 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[3] VAR mfecha ID 114 OF oDlg PICTURE "@D" 
    REDEFINE GET oGet[6] VAR mentrega  ID 116 OF oDlg PICTURE "999999.99" WHEN(lEdita) VALID(mentrega>=0)
    REDEFINE GET oGet[5] VAR manticipo ID 117 OF oDlg PICTURE "999999.99" WHEN((oGet[5]:cText := oQryCli:saldo)=SPACE(10))
    REDEFINE BUTTON oBot[1] ID 115 OF oDlg ACTION Mostrar() WHEN(lEdita)
    REDEFINE BUTTON oBot[6] ID 106 OF oDlg ACTION(POS1(nil,mcodcli,"NC")) WHEN(oQry:RecCount()=0 .and. mcodcli<>0)
    REDEFINE BUTTON oBot[7] ID 107 OF oDlg ACTION(POS1(nil,mcodcli,"FC")) WHEN(oQry:RecCount()=0 .and. mcodcli<>0)
    REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "ticomp","numcomp","fecha","saldo","pagado","saldonue";
              HEADERS "Tipo","Nro. Compr.","Fecha","Saldo","Pagado","Nuevo Saldo" FOOTERS;
              SIZES 63,135,105,105,100,95 ID 120 OF oDlg ON CHANGE Actuali();
              ON DBLCLICK ImpRem()
    oBrw:aCols[4]:nFooterType := AGGR_SUM
    oBrw:aCols[5]:nFooterType := AGGR_SUM
    oBrw:aCols[6]:nFooterType := AGGR_SUM
    PintaBrw(oBrw,0)            
    oBrw:MakeTotals()
    REDEFINE XBROWSE oBrwDet DATASOURCE oQryDet;
              COLUMNS "codart","detart","bultos","cantidad","preciouni","preciotot";
              HEADERS "Codigo","Detalle","Bultos","Cant","P.Unit","P.Total";
              PICTURE "99999999","@!","9999","999999.999","99999999.99","9999999999.99";
              SIZES 60,200,75,90,90,90 ID 105 OF oDlg 
    PintaBrw(oBrwDet,0)           
    REDEFINE GET oGet[10] VAR mtotal  ID 121 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "99999999.99" WHEN(.F.)
    REDEFINE GET oGet[12] VAR mtotal1 ID 122 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "99999999.99" WHEN(.F.)
    REDEFINE BUTTON oBot[2] ID 102 OF oDlg ACTION IF(graba(oGet1),oDlg:End(),.T.) WHEN(oQry:nRecCount>0 .AND. !lEdita)
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg ACTION Cancela()
    REDEFINE BUTTON oBot[4] ID 104 OF oDlg ACTION (oDlg:End(),mrta:=.f.) CANCEL
    oDlg:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBrw:Report("Estado de deuda de " + mnomcli),.f.) }
   ACTIVATE DIALOG oDlg CENTER 
   IF !mrta
      EXIT
   ENDIF
ENDDO
Cerrar(oGet[1],oDlg)
oQryCli:End()
oFont:End()
oFo1:End()
RETURN nil

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
STATIC FUNCTION Graba(oGet1)
LOCAL  mrta, oError, nNumero, oRep
IF oBrw:aCols[5]:nTotal <= 0
   MsgStop("No marco ninguna factura para cobrar","Atencion")   
   RETURN .f.
ENDIF
IF !formapag()
   RETURN .f.
ENDIF

TRY 
   oApp:oServer:BeginTransaction()
   nNumero := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")
   ** Actualizo saldos de facturas
   oQry:GoTop()
   DO WHILE !oQry:Eof()
        oApp:oServer:Execute("INSERT INTO transi_ventas (saldo,codcli,ticomp,numcomp) "+;
                             "VALUES (+"+;
                                 ClipValue2Sql(oQry:saldonue)+","+;
                                 ClipValue2Sql(mcodcli) +","+;
                                 ClipValue2Sql(oQry:ticomp) +","+;
                                 ClipValue2Sql(oQry:numcomp)+")")
       oQry:Skip()
   ENDDO
  ** Agrego pago 
    oApp:oServer:Execute("INSERT INTO transi_det " + ;
                        " (numero,cliente, total, fecha, caja, efectivo, cheques, tarjeta, anticipo) VALUES "+;
                        " ("+;
                            ClipValue2Sql(nNumero)+","+;
                            ClipValue2Sql(mcodcli)+","+;
                            ClipValue2Sql(mefectivo+mtarjeta+mcheques)+","+;
                            ClipValue2Sql(mfecha)+","+;
                            ClipValue2Sql(oApp:prefijo)+","+;
                            ClipValue2Sql(mefectivo)+","+;
                            ClipValue2Sql(mcheques)+","+;
                            ClipValue2Sql(mtarjeta)+","+;
                            ClipValue2Sql(manticipo)+;
                              ") " )   
   oApp:oServer:NextResult()
 
   ** Actualizo saldo de clientes si tiene a favor
   oApp:oServer:Execute("INSERT INTO transi_saldos (codcli,saldo) " + ;
                        " VALUES ( "+ ClipValue2Sql(mcodcli)+","+ClipValue2Sql(ABS(macuenta))+")")
   oApp:oServer:NextResult()
   ***** Agrego cheques de tercero
   oApp:oServer:Execute("INSERT INTO transi_cheter (numban,numche,fecing,fecvto,importe,recibo,codcli) "+;
                        " ( SELECT numban,numche,fecemi,fecvto,importe," +;
                                 ClipValue2Sql(nNumero) + "," + ClipValue2Sql(mcodcli) +;
                                  " FROM transi_cheque WHERE tipo = 1)")
   oApp:oServer:NextResult()                                
   ***** Agrego comisiones
   oApp:oServer:Execute("INSERT INTO transi_comision (vendedor,codcli,factura,fechafc,fecha,importe,comision,comipesos) "+;
                        " ( SELECT vendedor,"+ ClipValue2Sql(mcodcli) +",CONCAT(ticomp,numcomp),fecha,"+;
                            ClipValue2Sql(DATE()) +", pagado, comision, pagado * comision /100 " +;                                 
                        " FROM transi_pagos1 WHERE pagado <> 0)")      
   oApp:oServer:NextResult()          
   oApp:oServer:CommitTransaction()
   CATCH oError
   ValidaError(oError)
  RETURN .f.
END TRY


            

mrta := MsgYesNo("Desea Imprimir el Recibo cobrado","Atencion")
IF mrta   
   oQry:GoTop()
   REPORT oRep TITLE "Detalle del pago";
          HEADER " "," ","Documento no valido como factura",;
                 "Nro de Recibo:" + STR(nNumero),;
                 "Fecha de operacion:" + DTOC(mfecha) ,;
                 "Cliente:" + STR(mcodcli,6) + "  " + oQryCli:nombre,;
                 "Anticipo:" + STR(manticipo,10,2),;
                 "Efectivo:" + STR(mefectivo,10,2),;
                 "Tarjetas:" + STR(mtarjeta,10,2),;
                 "Cheques:" + STR(mcheques,10,2),;
                 "A Cta. :" + STR(ABS(macuenta),10,2),;
                 "Saldo anterior:" + STR(mtotal1,10,2),;
                 "Su Pago:" + STR(mefectivo+mtarjeta+mcheques,10,2),;
                 "Su Saldo:" + STR(oBrw:aCols[6]:nTotal-ABS(macuenta),10,2) LEFT ;
          PREVIEW CAPTION  "Recibo de cobro"
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
*Cancela()   

nEfectivoE:= nEfectivoE+mefectivo+mtarjeta
nChequeE:= nChequeE + mcheques
nFalta:= nEfectivo + nCheque - nEfectivoE - nChequeE
oGet1[07]:Refresh()
oGet1[08]:Refresh()
oGet1[09]:Refresh()
oApp:oServer:Execute("INSERT INTO temp_resu (codcli,nombre,pagado) "+;
                     "VALUES ("+ClipValue2Sql(mcodcli)+","+;
                         ClipValue2Sql(mnomcli)+","+;
                         ClipValue2Sql(oBrw:aCols[5]:nTotal)+")")
oApp:oServer:NextResult() 
oQryResu:Refresh()
oBrwResu:Refresh()
oBrwResu:MakeTotals()
               
                       
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
LOCAL mentre := mentrega + manticipo, oQryValid
oQryValid:= oApp:oServer:Query("SELECT nombre FROM temp_resu WHERE codcli = "+ClipValue2Sql(mcodcli))
IF oQryValid:RecCount() > 0
   msgstop("El cliente ya esta en rendicion!!")
   oGet[01]:SetFocus()
   RETURN nil
ENDIF
oQry:Zap()
oApp:oServer:Execute("INSERT INTO transi_pagos1 (ticomp,numcomp,fecha,saldo,pagado,saldonue,vendedor,comision) "+;
                     "SELECT v.ticomp AS ticomp,v.numcomp AS numcomp, v.fecha AS fecha, "+;
                     " v.saldo * IF(v.ticomp = 'NC', -1,1) AS saldo, "+;
                     " 0 as pagado, v.saldo * IF(v.ticomp = 'NC', -1,1) AS saldonue,  "+;
                     "v.vendedor AS vendedor, v.comision AS comision "+;
                     "FROM ge_"+oApp:cId+"ventas v "+;
                     "WHERE v.codcli = " + ClipValue2Sql(mcodcli) + " AND " +;
                     " v.saldo > 0 ")
oApp:oServer:NextResult()
oQry:Refresh()
DO WHILE !oQry:Eof()
   IF oQry:ticomp = "NC" .or. oQry:ticomp = "DE"
      oQry:pagado   := oQry:saldo
      oQry:saldonue := 0
      mentre := mentre + ABS(oQry:saldo)
      oQry:Save()
   ENDIF   
   oQry:Skip()
ENDDO
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF oQry:ticomp <> "NC" .and. oQry:ticomp = "DE" .and. mentre > 0
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
mtotal := oBrw:aCols[4]:nTotal
mtotal1:= oBrw:aCols[4]:nTotal - oGet[5]:Value
Actuali()
IF oQry:nRecCount = 0
   MsgInfo("Cliente sin deuda pendiente","Atencion")
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
cWhere := "numfac = " + ClipValue2Sql(oQry:ticomp+oQry:numcomp) 
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
                           "`IMPORTE` decimal(10,2) DEFAULT 0,"+;
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
*mefectivo := IF(manticipo < oBrw:aCols[5]:nTotal, oBrw:aCols[5]:nTotal - manticipo,0)
mefectivo := mentrega
mtarjeta := 0
mcheques := 0
macuenta := 0
mpagado  := oBrw:aCols[5]:nTotal 
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
               (AddCheqT(oBot[1]),oBrw2:Refresh(),oBrw2:MakeTotals(),;
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
** Agregar cheques de Tercero
STATIC FUNCTION AddCheqT(oWnd)
LOCAL oGet2 := ARRAY(12), oBot2 := ARRAY(2) , oDlg3, cNomCue := SPACE(30), cNomPro := SPACE(30),;
      mrta := .f., aCor, oQryChe1, base, oError, oFont
DO WHILE .T.
base := oQryChe:GetBlankRow()
base:tipo  := 1
base:recibo  := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")
base:importe := IF(macuenta>0,macuenta,0)
base:codcli  := mcodcli
base:fecemi  := DATE()
base:fecvto  := DATE()
cNomPro      := oQryCli:nombre
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DEFINE DIALOG oDlg3 TITLE "Alta de Cheques de Tercero" FROM 05,15 TO 23,66 OF oWnd FONT oFont
   acor := AcepCanc(oDlg3)
   @ 07, 05 SAY "Banco:"         OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Numero:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Entregado por:" OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "En recibo:"     OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Emision:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 82, 05 SAY "Vencimiento:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 97, 05 SAY "Importe:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet2[1] VAR base:numban  PICTURE "999" OF oDlg3 PIXEL SIZE 25,12 RIGHT;
                VALID(Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2]) );
                ACTION (oGet2[1]:cText:= 0, Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2])) BITMAP "BUSC1"         
   @ 05, 80 GET oGet2[2] VAR cNomCue OF oDlg3 PIXEL PICTURE "@!" WHEN(.F.)   
   @ 20, 50 GET oGet2[3] VAR base:numche  PICTURE "9999999999"  OF oDlg3 PIXEL ;
                VALID(base:numche > 0) RIGHT
   @ 35, 50 GET oGet2[4] VAR base:codcli OF oDlg3  PICTURE "999999" PIXEL RIGHT WHEN(.F.)
   @ 35, 80 GET oGet2[5] VAR cNomPro OF oDlg3 SIZE 110,12  PIXEL WHEN(.F.)
   @ 50, 50 GET oGet2[6] VAR base:recibo PICTURE "99999999" PIXEL OF oDlg3 RIGHT WHEN(.F.)
   @ 65, 50 GET oGet2[7] VAR base:fecemi   PICTURE "@D" PIXEL OF oDlg3 CENTER
   @ 80, 50 GET oGet2[8] VAR base:fecvto   PICTURE "@D" PIXEL OF oDlg3 VALID(base:fecvto >= base:fecemi) CENTER
   @ 95, 50 GET oGet2[9] VAR base:importe  PICTURE "9999999.99" PIXEL OF oDlg3 RIGHT VALID(base:importe>0)
   @ acor[1],acor[2] BUTTON oBot2[1] PROMPT "&Grabar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg3:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2[2] PROMPT "&Cancelar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg3:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg3 CENTER ON INIT oGet2[1]:SetFocus()
IF !mRta
   RETURN nil
ENDIF
oQryChe1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cheter WHERE numban = " + ClipValue2Sql(base:numban) +;
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

*******************************************
** Impresion de Remito
STATIC FUNCTION ImpRem()
LOCAL aiva := {"Inscripto     ","No inscripto  ","No responsable",;
               "Excento       ","Monotributo   ","Consu. Final  "}, ;
      mivades, i, y, oPrn, mtot := 0, nRow, oFont, mrta := 3,;
      mfact, marchi := "factvent", x, mbul, muni, mxper, myper, auxil, config, oQry1
   auxil  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"auxil")   
   config := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   mrta  := Alert("Elija Opcion",{"Remito","Factura","Cancelar"})
   IF mrta = 3
      RETURN nil
   ENDIF
   mxper    := auxil:xper
   myper    := auxil:yper
   auxil:End()   
   IF mrta = 1      
      ** FACTURACION CON FORMATO PARA REMITO
      DEFINE FONT oFont NAME "COURIER NEW" SIZE config:fon/4,config:fon/2
      mivades  := aiva[oQryCli:coniva]
      PRINT oPrn NAME "Remito" PREVIEW MODAL
      FOR x := 1 TO oQryPun:copiare
      PAGE
      nRow := oPrn:nVertRes() / 66        
          oPrn:Say( config:x3,config:y3 , DTOC(oQry:fecha),oFont)
          oPrn:Say( config:x4,config:y4 , "("+STR(oQryCli:codigo,5)+")  "+oQryCli:nombre,oFont)
          oPrn:Say( config:x5,config:y5 , oQryCli:direccion,oFont)
          oPrn:Say( config:x5,config:y3 , "  " + oQryCli:localidad,oFont)
          oPrn:Say( config:x7,config:y7 , oQryCli:cuit,oFont)
          oPrn:Say( config:x6,config:y6 , mivades,oFont)
          y := config:desdey
          
          oQryDet:GoTop()
          DO WHILE !oQryDet:Eof()
              oPrn:Say( y ,  40 ,  STR(oQryDet:codart,6) + "  " + ;
                                   STR(oQryDet:bultos,4) +;
                                   STR(ABS(oQryDet:cantidad),08,2) + ;
                                   " " + LEFT(oQryDet:detart,49) ,oFont)
             oQryDet:SKIP()
             y := y + nRow + 5
          ENDDO
      ENDPAGE
      NEXT x
      ENDPRINT            
      ELSE    
      ** FACTURACION CON FORMATO PARA FACTURA
      oQry1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas WHERE ticomp =" + ClipValue2Sql(oQry:ticomp)+;
                                  " AND numcomp = " + ClipValue2Sql(oQry:numcomp))
      DEFINE FONT oFont NAME "COURIER NEW" SIZE config:fon/4,config:fon/2
      mivades  := aiva[oQryCli:coniva] // + " - " + mforma
      PRINT oPrn NAME "Factura" PREVIEW MODAL
      FOR x := 1 TO IF(LEFT(oQry1:numcomp,1)="A",oQryPun:copiafa,oQryPun:copiafb)
      mbul := 0
      muni := 0      
      PAGE
          nRow := oPrn:nVertRes() / 66
          mtot := 0
          IF oQry1:ticomp <> "FC"
             oPrn:Say( config:x1,config:y1 , IF(oQry1:ticomp="NC","NOTA DE CREDITO",IF(oQry1:ticomp="DE","NOTA DE DEVOLUCION","              ")),oFont)
          ENDIF
          oPrn:Say( config:x3,config:y3 , DTOC(oQry1:fecha),oFont)
          oPrn:Say( config:x4,config:y4 , "("+STR(oQryCli:codigo,5)+")  "+oQryCli:nombre,oFont)
          oPrn:Say( config:x5,config:y5 , oQryCli:direccion,oFont)
          oPrn:Say( config:x5,config:y3 , "  " + oQryCli:localidad,oFont)
          oPrn:Say( config:x7,config:y7 , oQryCli:cuit,oFont)
          oPrn:Say( config:x6,config:y6 , mivades,oFont)
          y := config:desdey
          oQryDet:GoTop()
          DO WHILE !oQryDet:Eof()
              oPrn:Say( y ,  40 ,  STR(oQryDet:codart,6) + "  " + ;
                                   STR(oQryDet:bultos,4) +;
                                   STR(ABS(oQryDet:cantidad),08,2) + ;
                                   " " + LEFT(oQryDet:detart,49) + " " +;
                                   STR(oQryDet:preciouni,8,3) + " " + ;
                                   IF(oQryDet:preciotot=0,;
                                   STR(oQryDet:preciotot,9,2),;
                                   STR(oQryDet:preciotot*oQryDet:cantidad,9,2)),oFont)
              mtot := mtot + oQryDet:preciotot
              IF INT(oQryDet:bultos) = 0
                 muni := muni + ABS(oQryDet:cantidad)
                 ELSE
                 mbul := mbul + INT(oQryDet:bultos)
              ENDIF
              oQryDet:Skip()
              y := y + nRow + 5
          ENDDO
          oPrn:Say( y ,  40 ,"Descuento:" + STR(oQry1:descu,9,2)+;
                            " Bultos:" + STR(mbul,5) + "  - "+;
                            " Unidades:" + STR(muni,10,2), oFont)
          y = y + nRow + 5
          oPrn:Say(y , 40   ,"Carros:" + oQry1:carros, oFont)
          IF oQryCli:coniva >= 3
             oPrn:Say( config:x9,config:y9, STR(oQry1:importe,10,2),oFont)
             ELSE
             oPrn:Say( config:xa,config:ya, STR(oQry1:neto,10,2),oFont)
             oPrn:Say( config:xb,config:yb, STR(oQry1:iva ,10,2),oFont)
             oPrn:Say( config:xa,config:xneto2, STR(oQry1:neto2,10,2),oFont)
             oPrn:Say( config:xb,config:xiva2 , STR(oQry1:iva2 ,10,2),oFont)   
             oPrn:Say( mxper,myper, STR(oQry1:percep,10,2),oFont)
             oPrn:Say( config:x9,config:y9, STR(oQry1:importe,10,2),oFont)
          ENDIF
      ENDPAGE
      NEXT x
      oQry1:End()
      ENDPRINT      
   ENDIF   
RETURN nil