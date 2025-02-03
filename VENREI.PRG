#include "Fivewin.ch"

MEMVAR oApp
*************************************************
** REIMPRESION DE FACTURAS
*************************************************
PROCEDURE ReImFac()
LOCAL oGet1, oGet2, oGet3, oGet4, oBot1, oBot2, oDlg1, oFont, mnumfac, ;
      mrta := .f., aCor, base, marchi, mtotal, mdescp := 0, mdeuda := 0,;
      aTipo  := {"Factura","Nota Credito","Nota Debito","Factura x Remito","Remito"}, oQry,;
      aTip1  := {"FC","NC","ND","FR","RE"}, mtipo := 1, mletra := "A", mprefijo := 3,;
      mnumero := 0, oQryDet1, lConsulta := .f., oChe, oQryUlt, oBrw, oQryUlt1, oBrw1, oQryDet
oQryUlt := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab ORDER BY fecha DESC,hora DESC LIMIT 10")

oQryUlt1 := oApp:oServer:Query("SELECT DISTINCT(nrorem) as nrorem,fecha, codcli FROM ge_"+oApp:cId+"remitos ORDER BY fecha DESC LIMIT 10")

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5      
DEFINE DIALOG oDlg1 TITLE "Reimprimir comprobante" FROM 03,20 TO 28,120 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg1)
   @ 01, 05 SAY "Ultmos 10 comprobantes emitidos" OF oDlg1 PIXEL CENTER SIZE 230,10
   @ 12, 05 XBROWSE oBrw DATASOURCE oQryUlt;
              COLUMNS "ticomp","letra","numcomp","nombre","importe";
              HEADERS "Tipo","Letra","Numero Comp","Cliente","Importe";
              SIZES 30,30,100,140,80;
              AUTOSORT OF oDlg1 ;
     SIZE 230,70 PIXEL ON CHANGE Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt)
   PintaBrw(oBrw,5)   
   oBrw:CreateFromcode()
   @ 01,250 SAY "Ultmos 10 remitos" OF oDlg1 PIXEL CENTER SIZE 130,10
   

   @ 12,250 XBROWSE oBrw1 DATASOURCE oQryUlt1;
              COLUMNS "nrorem","fecha";
              HEADERS "Numero remito","fecha";
              SIZES 130,80;
              AUTOSORT OF oDlg1 ;
     SIZE 130,70 PIXEL ON CHANGE Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt1,.t.)
   PintaBrw(oBrw1,2)   
   oBrw1:CreateFromcode()
   @  97, 05 SAY "Tipo Docum.:" OF oDlg1 PIXEL RIGHT SIZE 40,10
   @ 112, 05 SAY "Letra:"       OF oDlg1 PIXEL RIGHT SIZE 40,10
   @ 127, 05 SAY "Prefijo:"     OF oDlg1 PIXEL RIGHT SIZE 40,10
   @ 142, 05 SAY "Numero:"      OF oDlg1 PIXEL RIGHT SIZE 40,10   
   
   @  95, 50 COMBOBOX oGet1 VAR mtipo ITEMS aTipo OF oDlg1 SIZE 79,50 PIXEL
   @ 110, 50 GET      oGet2 VAR mletra PICTURE "@!" OF oDlg1 SIZE 20,10 PIXEL;
                     VALID(mletra$"ABCRXM") WHEN(mtipo<4)
   @ 125, 50 GET      oGet3 VAR mprefijo PICTURE "9999" OF oDlg1 PIXEL RIGHT
   @ 140, 50 GET      oGet4 VAR mnumero  PICTURE "99999999" OF oDlg1 PIXEL RIGHT
   @ 125, 90 CHECKBOX oChe VAR lConsulta PROMPT "Consultar AFIP" OF oDlg1 PIXEL SIZE 70,12 WHEN(mtipo<4)

   oBrw:bGotFocus := {|| Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt)}
   oBrw1:bGotFocus := {|| Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt1,.t.)}

   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER //ON INIT (oGet1:SetFocus(),Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt))
IF !mrta
   RETURN
ENDIF
IF lConsulta
   ConsultarComprobante(mtipo,mLetra,mprefijo,mnumero)
   RETURN 
ENDIF
IF mtipo <> 5
    oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab WHERE ticomp = " + ClipValue2Sql(aTip1[mtipo]) + ;
                       " AND letra = " + ClipValue2Sql(mletra) + " AND numcomp = " + ;
                       ClipValue2Sql(STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0") ))
    IF oQry:nRecCount = 0
       MsgStop("Factura no existe","Error")
       RETURN 
    ENDIF

    IF mletra $ "ABCM"
       PrintFactuElec(aTip1[mtipo],mletra+STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0"))  
    ELSE 
       FacturaNoFiscal(aTip1[mtipo],mletra+STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0"))
    ENDIF
  ELSE 
  //Remitos
  oQryDet := oApp:oServer:Query("SELECT codart,detart,cantidad,auto as bultos, codcli FROM ge_"+oApp:cId+;
         "remitos WHERE nrorem = "+ClipValue2SQL("RE"+STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0")))
  IF oQryDet:nRecCount = 0
     MsgStop("Remito no existe","Error")
     RETURN 
  ENDIF
  PrintRemito(oQryDet,,, STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0"),oQryDet:codcli)
ENDIF  
         
RETURN

STATIC FUNCTION Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt,lRemi)
DEFAULT lRemi := .f.
IF !lRemi
    DO CASE 
       CASE oQryUlt:ticomp = "FC"
            oGet1:Set(1)
       CASE oQryUlt:ticomp = "NC"
            oGet1:Set(2)
       CASE oQryUlt:ticomp = "ND"
            oGet1:Set(3)
       CASE oQryUlt:ticomp = "FR"
            oGet1:Set(4)
    ENDCASE     
    oGet2:cText := oQryUlt:letra 
    oGet3:cText := VAL(LEFT(oQryUlt:numcomp,4))
    oGet4:cText := VAL(RIGHT(oQryUlt:numcomp,8))
    ELSE
    oGet1:Set(5)
    oGet2:cText := 'X' 
    oGet3:cText := VAL(substr( oQryUlt:nrorem,3,4))
    oGet4:cText := VAL(RIGHT(oQryUlt:nrorem,8))
ENDIF    
RETURN NIL
