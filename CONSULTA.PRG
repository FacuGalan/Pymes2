#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** consulta de precios por forma de pago
*************************************************
MEMVAR oApp
STATIC oGet,oDlg, mfecha, manticipo, mcodpro, mentrega,;
       oBrw, oQry, lEdita, oQryBan, oQryPro, oQryCue,mobserva,;
       lMostrarSis,lReten,;  //VARIABLE QUE DICE SI MUESTRA SISTEMA O DEMO / VARIABLE PARA CALCULAR O NO RETENCIONES
       lACuenta,; //LOGICA QUE ME HABILITA EL BOTON PARA PAGO A CUENTA
       oBrwCheT,oQryCheT,;
       oBrwCheP,oQryCheP,;
       nEfectivo,nTransferencia,nCheqT,nCheqP,nAnticipo,nFaltante,nTotal,nTotal1,; //FORMAS DE PAGO
       nReten1,nReten2,nReten3,nIndice,nRetencion1,nRetencion3,nNetoGan,nNetoGanTot,nReten3Tot //PARA CALCULAR LAS RETENCIONES
PROCEDURE consulta()
LOCAL oFont, oFo1,  oSay1, mnompro, mrta := .f.,nCodArt:=0,cNomArt:=SPACE(50),oBot:=ARRAY(2),oQryArt
oGet:=ARRAY(2)
oQryArt:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"articu")
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS precios_temp ";
    +"( `FORMAPAG` VARCHAR(50) NOT NULL, ";
    +"`INCREMENTO` DECIMAL(5,2) DEFAULT '0.00',";
    +"`IMPORTE` DECIMAL(12,2) DEFAULT '0.00' ";
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE precios_temp")

oApp:oServer:Execute("INSERT INTO precios_temp (formapag,incremento,importe) "+;
                     "(SELECT nombre,incremento,0 FROM ge_"+oApp:cId+"forpag )")


DO WHILE .T.
   oQry:= oApp:oServer:Query("SELECT * FROM precios_temp")
   DEFINE DIALOG oDlg RESOURCE "CONSULTA" OF oApp:oWnd TITLE "Consultar precios por forma de pago"
    oDlg:lHelpIcon := .f.

   REDEFINE GET oGet[01] VAR nCodArt ID 101 OF oDlg PICTURE "9999999999999";
            VALID(BuscarArt(oQryArt,oDlg,oGet[01],oGet[02]) .and. MostrarPrecios(nCodArt));
               ACTION (oGet[01]:cText:= 0,BuscarArt(oQryArt,oDlg,oGet[01],oGet[02]),MostrarPrecios(nCodArt)) BITMAP "BUSC1"

   REDEFINE get oGet[02] VAR cNomArt ID 102 OF oDlg PICTURE "@!" WHEN(.F.)


        REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "formapag","importe";
              HEADERS "Forma de pago","Precio" FOOTERS;
              SIZES 300,100  ID 200 OF oDlg       
    PintaBrw(oBrw,0)    

   REDEFINE BUTTON oBot[1] ID 301 OF oDlg ACTION (oDlg:End()) CANCEL
   ACTIVATE DIALOG oDlg CENTER 
   IF !mrta
      EXIT
   ENDIF
ENDDO
Cerrar(oGet[1],oDlg)

RETURN

******************************************************************************************************************************
**** CALCULAR LAS RETENCIONES DE LAS FACTURAS PAGADAS
STATIC FUNCTION MostrarPrecios(nCodArt)
oApp:oServer:Execute("UPDATE precios_temp SET importe = "+;
                    "(SELECT precioven FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(nCodArt)+")"+;
                    "*(1+(incremento/100))")
oQry:Refresh()
oBrw:Refresh()
oGet[1]:SetFocus()
RETURN .T.

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
oQry:End()
RELEASE oQry
  

RETURN .t.