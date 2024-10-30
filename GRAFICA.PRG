#Include "FiveWin.Ch"
#Include "TGraph.Ch"
#include "Tdolphin.ch"
MEMVAR oApp
STATIC oFont
PROCEDURE Grafica1()
LOCAL oGet3, oGet4, mrta := .f., mtotal, ant, mdesde := DATE(), mhasta := DATE(),;
      oGraf,aSerie := {}, aLeyen := {}, oDlg, oBot1, oBot2, acor, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Ventas por fecha" FROM 03,15 TO 11,45 ;
       OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg)
   @ 07, 05 SAY "Desde Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 05, 50 GET oGet3 VAR mdesde  OF oDlg PIXEL CENTER
   @ 20, 50 GET oGet4 VAR mhasta  OF oDlg PIXEL VALID(mhasta >= mdesde) CENTER
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT DAY(fecha) as dia, SUM(importe * IF(ticomp='NC' OR ticomp='DE',-1,1)) as cant FROM ge_"+oApp:cId+"ventas_encab WHERE fecha >= " + ClipValue2SQL(mdesde) +;
                            " AND fecha <= " + ClipValue2SQL(mhasta) + " GROUP BY fecha")
DO WHILE !oQry:EOF()
   AADD(aSerie,oQry:cant)
   AADD(aLeyen,STR(oQry:dia))
   oQry:SKIP()
ENDDO
oQry:End()
IF LEN(aSerie) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   oQry:End() 
   RETURN
ENDIF
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "Ventas por dia" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 2
      oGraf:cTitle := "Ventas del " + DTOC(mdesde) + " al " + DTOC(mhasta)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Dias"
      oGraf:lPopUp := .T.
      oGraf:AddSerie(aSerie, "Ventas por dia", RGB(128,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN

PROCEDURE Grafica2()
LOCAL oGet3, mrta := .f., mdesde := YEAR(DATE()), ;
      oGraf,aSerie := {0,0,0,0,0,0,0,0,0,0,0,0},;
      aLeyen := {"Ene","Feb","Mar","Abr","May","Jun",;
                 "Jul","Ago","Sep","Oct","Nov","Dic"},;
      oDlg, oBot1, oBot2, acor, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Ventas Anuales" FROM 03,15 TO 10,45 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg)
   @ 12, 05 SAY "Año:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 10, 50 GET oGet3 VAR mdesde  PICTURE "9999" OF oDlg PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta   
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT MONTH(fecha) as mes, SUM(importe * IF(ticomp='NC' OR ticomp='DE',-1,1)) as cant FROM ge_"+oApp:cId+"ventas_encab WHERE YEAR(fecha) = " + ClipValue2SQL(mdesde) +;
                            " GROUP BY MONTH(fecha)")
DO WHILE !oQry:EOF()
   aSerie[oQry:mes] := oQry:cant
   oQry:Skip()
ENDDO
oQry:End()
IF LEN(aSerie) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   RETURN
ENDIF
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "Ventas por mes" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 1
      oGraf:cTitle := "Ventas Anuales " + STR(mdesde)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Mes"
      oGraf:lPopUp := .T.
      oGraf:AddSerie(aSerie, "Mes", RGB(255,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN

PROCEDURE Grafica3()
LOCAL oGet3, oGet4, mrta := .f., mtotal, ant, mdesde := DATE(), mhasta := DATE(),;
      oGraf,aSerie := {}, aLeyen := {}, oDlg, oBot1, oBot2, acor,;
      aRubro := {}, aPreci := {}, j, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Grafico por Rubro" FROM 03,15 TO 11,45 OF oApp:oWnd
   acor := AcepCanc(oDlg)
   @ 07, 05 SAY "Desde Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 05, 50 GET oGet3 VAR mdesde  OF oDlg PIXEL CENTER
   @ 20, 50 GET oGet4 VAR mhasta  OF oDlg PIXEL VALID(mhasta >= mdesde) CENTER
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta   
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT r.nombre as rubro, SUM(v.importe) as cant FROM ge_"+oApp:cId+"ventas_det v "+;
                            "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;  
                            "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;  
                            "WHERE v.fecha >= " + ClipValue2SQL(mdesde) +;
                            "  AND v.fecha <= " + ClipValue2SQL(mhasta) + " GROUP BY r.nombre")
DO WHILE !oQry:Eof()
   AADD(aLeyen,oQry:rubro)
   AADD(aPreci,oQry:cant)      
   oQry:Skip()
ENDDO
IF LEN(aLeyen) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   RETURN
ENDIF
      
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "Ventas por Marca" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 4
      oGraf:cTitle := "Ventas x rubros del " + DTOC(mdesde) + " al " + DTOC(mhasta)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Rubro"
      oGraf:lPopUp := .T.
      
      oGraf:AddSerie(aPreci, "Rubro", RGB(255,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN


**************************************************************************************************************************************
** C O M P R A S 
PROCEDURE Grafica21()
LOCAL oGet3, oGet4, mrta := .f., mtotal, ant, mdesde := DATE(), mhasta := DATE(),;
      oGraf,aSerie := {}, aLeyen := {}, oDlg, oBot1, oBot2, acor, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Compras por fecha" FROM 03,15 TO 11,45 ;
       OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg)
   @ 07, 05 SAY "Desde Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 05, 50 GET oGet3 VAR mdesde  OF oDlg PIXEL CENTER
   @ 20, 50 GET oGet4 VAR mhasta  OF oDlg PIXEL VALID(mhasta >= mdesde) CENTER
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT DAY(fecfac) as dia, SUM(importe * IF(tipocomp='NC' OR tipocomp='DE',-1,1)) as cant FROM ge_"+oApp:cId+"compras WHERE fecfac >= " + ClipValue2SQL(mdesde) +;
                            " AND fecfac <= " + ClipValue2SQL(mhasta) + " GROUP BY fecfac")
DO WHILE !oQry:EOF()
   AADD(aSerie,oQry:cant)
   AADD(aLeyen,STR(oQry:dia))
   oQry:SKIP()
ENDDO
oQry:End()
IF LEN(aSerie) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   oQry:End() 
   RETURN
ENDIF
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "Compras por dia" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 2
      oGraf:cTitle := "Compras del " + DTOC(mdesde) + " al " + DTOC(mhasta)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Dias"
      oGraf:lPopUp := .T.
      oGraf:AddSerie(aSerie, "Compras por dia", RGB(128,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN

PROCEDURE Grafica22()
LOCAL oGet3, mrta := .f., mdesde := YEAR(DATE()), ;
      oGraf,aSerie := {0,0,0,0,0,0,0,0,0,0,0,0},;
      aLeyen := {"Ene","Feb","Mar","Abr","May","Jun",;
                 "Jul","Ago","Sep","Oct","Nov","Dic"},;
      oDlg, oBot1, oBot2, acor, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Compras Anuales" FROM 03,15 TO 10,45 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg)
   @ 12, 05 SAY "Año:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 10, 50 GET oGet3 VAR mdesde  PICTURE "9999" OF oDlg PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta   
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT MONTH(fecfac) as mes, SUM(importe * IF(tipocomp='NC' OR tipocomp='DE',-1,1)) as cant FROM ge_"+oApp:cId+"compras WHERE YEAR(fecfac) = " + ClipValue2SQL(mdesde) +;
                            " GROUP BY MONTH(fecfac)")
DO WHILE !oQry:EOF()
   aSerie[oQry:mes] := oQry:cant
   oQry:Skip()
ENDDO
oQry:End()
IF LEN(aSerie) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   RETURN
ENDIF
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "Compras por mes" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 1
      oGraf:cTitle := "Compras Anuales " + STR(mdesde)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Mes"
      oGraf:lPopUp := .T.
      oGraf:AddSerie(aSerie, "Mes", RGB(255,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN

PROCEDURE Grafica23()
LOCAL oGet3, oGet4, mrta := .f., mtotal, ant, mdesde := DATE(), mhasta := DATE(),;
      oGraf,aSerie := {}, aLeyen := {}, oDlg, oBot1, oBot2, acor,;
      aRubro := {}, aPreci := {}, j, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Compras por cuenta" FROM 03,15 TO 11,45 OF oApp:oWnd
   acor := AcepCanc(oDlg)
   @ 07, 05 SAY "Desde Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 05, 50 GET oGet3 VAR mdesde  OF oDlg PIXEL CENTER
   @ 20, 50 GET oGet4 VAR mhasta  OF oDlg PIXEL VALID(mhasta >= mdesde) CENTER
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta   
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT r.nombre as rubro, SUM(v.importe* IF(v.tipocomp='NC' OR v.tipocomp='DE',-1,1)) as cant FROM ge_"+oApp:cId+"compras v "+;
                            "LEFT JOIN ge_"+oApp:cId+"plancont r ON r.codigo = v.codcue "+;
                            "WHERE v.fecfac >= " + ClipValue2SQL(mdesde) +;
                            "  AND v.fecfac <= " + ClipValue2SQL(mhasta) + " GROUP BY r.nombre")
DO WHILE !oQry:Eof()
   AADD(aLeyen,oQry:rubro)
   AADD(aPreci,oQry:cant)      
   oQry:Skip()
ENDDO
IF LEN(aLeyen) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   RETURN
ENDIF
      
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "Compras por cuenta" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 4
      oGraf:cTitle := "Compras por cuenta del " + DTOC(mdesde) + " al " + DTOC(mhasta)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Cuenta"
      oGraf:lPopUp := .T.
      
      oGraf:AddSerie(aPreci, "Cuenta", RGB(255,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN

***********************************************************************************************************
** A cobrar
PROCEDURE Grafica31()
LOCAL oGet3, oGet4, mrta := .f., mtotal, ant, mdesde := DATE(), mhasta := DATE(),;
      oGraf,aSerie := {}, aLeyen := {}, oDlg, oBot1, oBot2, acor,;
      aRubro := {}, aPreci := {}, j, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "A cobrar por cliente" FROM 03,15 TO 11,45 OF oApp:oWnd
   acor := AcepCanc(oDlg)
   @ 07, 05 SAY "Desde Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 05, 50 GET oGet3 VAR mdesde  OF oDlg PIXEL CENTER
   @ 20, 50 GET oGet4 VAR mhasta  OF oDlg PIXEL VALID(mhasta >= mdesde) CENTER
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta   
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT r.nombre as rubro, SUM(v.importe* IF(v.tipo='NC' OR v.tipo='DE',-1,1)) as cant FROM ge_"+oApp:cId+"ventas_cuota v "+;
                            "LEFT JOIN ge_"+oApp:cId+"clientes r ON r.codigo = v.cliente "+;
                            "WHERE v.saldo > 0  and v.fecha >= " + ClipValue2SQL(mdesde) +;
                            "  AND v.fecha <= " + ClipValue2SQL(mhasta) + " GROUP BY r.nombre")
DO WHILE !oQry:Eof()
   AADD(aLeyen,oQry:rubro)
   AADD(aPreci,oQry:cant)      
   oQry:Skip()
ENDDO
IF LEN(aLeyen) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   RETURN
ENDIF
      
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "A cobrar por cliente" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 4
      oGraf:cTitle := "Ventas a cobrar del " + DTOC(mdesde) + " al " + DTOC(mhasta)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Cliente"
      oGraf:lPopUp := .T.
      
      oGraf:AddSerie(aPreci, "Clientes", RGB(255,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN

***********************************************************************************************************
** A Pagar
PROCEDURE Grafica41()
LOCAL oGet3, oGet4, mrta := .f., mtotal, ant, mdesde := DATE(), mhasta := DATE(),;
      oGraf,aSerie := {}, aLeyen := {}, oDlg, oBot1, oBot2, acor,;
      aRubro := {}, aPreci := {}, j, oQry
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "A Pagar por proveedor" FROM 03,15 TO 11,45 OF oApp:oWnd
   acor := AcepCanc(oDlg)
   @ 07, 05 SAY "Desde Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg PIXEL SIZE 40,12 RIGHT
   
   @ 05, 50 GET oGet3 VAR mdesde  OF oDlg PIXEL CENTER
   @ 20, 50 GET oGet4 VAR mhasta  OF oDlg PIXEL VALID(mhasta >= mdesde) CENTER
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet3:SetFocus()
IF !mrta   
   RETURN
ENDIF
oQry := oApp:oServer:Query( "SELECT r.nombre as rubro, SUM(v.importe* IF(v.tipocomp='NC' OR v.tipocomp='DE',-1,1)) as cant FROM ge_"+oApp:cId+"compras v "+;
                            "LEFT JOIN ge_"+oApp:cId+"provee r ON r.codigo = v.codpro "+;
                            "WHERE v.saldo > 0  and v.fecfac >= " + ClipValue2SQL(mdesde) +;
                            "  AND v.fecfac <= " + ClipValue2SQL(mhasta) + " GROUP BY r.nombre")
DO WHILE !oQry:Eof()
   AADD(aLeyen,oQry:rubro)
   AADD(aPreci,oQry:cant)      
   oQry:Skip()
ENDDO
IF LEN(aLeyen) = 0
   MsgStop("Sin datos para mostrar","Atencion")
   RETURN
ENDIF
      
      DEFINE DIALOG oDlg RESOURCE "GRAFICA" OF oApp:oWnd
      oDlg:lHelpIcon := .f.
      REDEFINE GRAPH oGraf OF oDlg ID 111 TITLE "A pagar por proveedor" 3D XGRID;
                            YGRID XVALUES YVALUES LEGENDS TYPE 4
      oGraf:cTitle := "Compras a pagar del " + DTOC(mdesde) + " al " + DTOC(mhasta)
      oGraf:cSubTit:= "En Pesos"
      oGraf:cTitX  := "Pesos"
      oGraf:cTitY  := "Proveedor"
      oGraf:lPopUp := .T.
      
      oGraf:AddSerie(aPreci, "Proveedor", RGB(255,128,255))
      oGraf:SetYVals(aLeyen)
      oGraf:Refresh()
      REDEFINE BUTTON oBot1 ID 102 OF oDlg ACTION Imprime(oDlg)
      REDEFINE BUTTON oBot2 ID 104 OF oDlg ACTION oDlg:End()
      ACTIVATE DIALOG oDlg CENTER
RETURN


STATIC PROCEDURE Imprime(oW)
oW:Print(,,,9)
RETURN