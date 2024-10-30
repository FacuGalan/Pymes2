#include "fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
MEMVAR oApp
*************************************
** Cambio general de precios
STATIC oQry,oQryRub, oQryIva, oQryMar, oQryPro,oQryEmp,oQryDep, oQryTemp,oQryArt, oBrw, oDlg, cWhere,;
       oQry2,oQry3,oQry4,oQry5,oQry6,oQry7,lVenta, nRedondeo, lSumaUtilidad
PROCEDURE PREGEN()
LOCAL oGet := ARRAY(7), nPorcUn:= 0,nPorcUnR:= 0, oBot := ARRAY(4),;
      lRta := .f., acor, base, nPorc := 0, nImpo := 0, oError,cCostoDesc,cCostoFlete, ;
      aRedondeo := {"Sin Redondear","Entero","Multiplo de 10","Multiplo de 100"}
nRedondeo := 2 
cWhere:= "1=1"
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS articu_temp ";
    +"("; 
    +"`CODIGO`     BIGINT(14) NOT NULL,";
    +"`NOMBRE`     VARCHAR(150) NOT NULL,";
    +"`preciocos`  DECIMAL(12,2) DEFAULT '0',";
    +"`preciocos1` DECIMAL(12,2) DEFAULT '0',";
    +"`costofin`  DECIMAL(12,2) DEFAULT '0',";
    +"`incru`  DECIMAL(12,2) DEFAULT '0',";  
    +"`incru1`  DECIMAL(12,2) DEFAULT '0',";
    +"`precioven`  DECIMAL(12,2) DEFAULT '0',";
    +"`precioven1` DECIMAL(12,2) DEFAULT '0',";
    +"`incruR`  DECIMAL(12,2) DEFAULT '0',";  
    +"`incruR1`  DECIMAL(12,2) DEFAULT '0',";
    +"`reventa`  DECIMAL(12,2) DEFAULT '0',";
    +"`reventa1` DECIMAL(12,2) DEFAULT '0'";
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")


oApp:oServer:NextResult()
oQryTemp  :=oApp:oServer:Query("SELECT * FROM articu_temp")                   

   oQryPro  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   oQryEmp  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"empresas ORDER BY codigo")
   oQryIva  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
   oQryDep  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deptos ORDER BY codigo")
   oQryMar  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"marcas ORDER BY codigo")
   oQryRub  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
   oQryArt  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"articu ORDER BY codigo")
   oQry2  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   oQry3  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
   oQry4  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"marcas ORDER BY codigo")
   oQry5  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
   oQry6  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deptos ORDER BY codigo")
   oQry7  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"empresas ORDER BY codigo")

DO WHILE .T.

lVenta:=.t.
lSumaUtilidad := .f.
DEFINE DIALOG oDlg TITLE "Cambio general de precios" FROM 02,01 TO 30,140 OF oApp:oWnd
   acor := AcepCanc( oDlg )
   
   @ 07, 05 SAY "Porcentaje:"     OF oDlg PIXEL    
   @ 07, 70 SAY "Importe Fijo:"   OF oDlg PIXEL
   @ 07,145 SAY "% Utilidad:"       OF oDlg PIXEL
   @ 07,210 SAY "% Utilidad Rev:"       OF oDlg PIXEL
   
   @ 05, 40 GET oGet[1] VAR nPorc    OF oDlg PIXEL PICTURE "999.99" RIGHT WHEN(nImpo=0 .and. nPorcUn=0 .and. nPorcUnR=0)
   @ 05,105 GET oGet[2] VAR nImpo    OF oDlg PIXEL PICTURE "999999.999" RIGHT WHEN(nPorc=0 .and. nPorcUn=0 .and. nPorcUnR=0)
   @ 05,180 GET oGet[3] VAR nPorcUn  OF oDlg PIXEL PICTURE "999.99" RIGHT WHEN(nImpo=0 .and. nPorc=0)
   @ 05,255 GET oGet[4] VAR nPorcUnR OF oDlg PIXEL PICTURE "999.99" RIGHT WHEN(nImpo=0 .and. nPorc=0)
   @ 05,300 CHECKBOX oGet[5] VAR lVenta OF oDlg PIXEL PROMPT "Aplicar incremento solo a precios de venta" SIZE 120,12
   @ 20,300 CHECKBOX oGet[7] VAR lSumaUtilidad OF oDlg PIXEL PROMPT "Sumar utilidad a la existente" SIZE 120,12 ;
     WHEN(nPorcUn>0 .or. nPorcUnR > 0)
   @ 05,440 COMBOBOX oGet[6] VAR nRedondeo ITEMS aRedondeo OF oDlg PIXEL SIZE 55,12  WHEN ((nPorc+nImpo+nPorcUn+nPorcUnR>0) .or. nPorc<0)
   @ 05,500 BUTTON oBot[3] PROMPT "Filtrar" OF oDlg SIZE 35,12 ACTION (Filtrar(nImpo,nPorc,nPorcUn,nPorcUnR)) WHEN ((nPorc+nImpo+nPorcUn+nPorcUnR>0) .or. nPorc<0) PIXEL
   @ 35,02 XBROWSE oBrw DATASOURCE oQryTemp ;
             COLUMNS "codigo","nombre","preciocos","incru","precioven","incruR","reventa","preciocos1","costofin","incru1","precioven1","incruR1","reventa1";
             HEADERS "Codigo","Articulo", "Costo","Utilidad","Venta","Utilidad Rev.","Reventa","Nuevo Costo","Costo final","Uti. Nuevo","Venta nuevo","Uti. Rev. Nuevo","Reventa nuevo";
             SIZES   50, 210, 80, 80, 80, 80,80,80,80,80,80,80,80;
             OF oDlg SIZE 520, 160 AUTOSORT PIXEL
   oBrw:CreateFromCode()
   oBrw:nMoveType := 4
   oBrw:nFreeze:= 2
   oBrw:aCols[08]:lAutoSave := .t.
   oBrw:aCols[08]:nEditType := EDIT_GET  
   oBrw:aCols[08]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(8,xval)} 
   oBrw:aCols[10]:lAutoSave := .t.
   oBrw:aCols[10]:nEditType := EDIT_GET  
   oBrw:aCols[10]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(9,xval)} 
   oBrw:aCols[11]:lAutoSave := .t.
   oBrw:aCols[11]:nEditType := EDIT_GET  
   oBrw:aCols[11]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(10,xval)} 
   oBrw:aCols[12]:lAutoSave := .t.
   oBrw:aCols[12]:nEditType := EDIT_GET  
   oBrw:aCols[12]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(11,xval)} 
   oBrw:aCols[13]:lAutoSave := .t.
   oBrw:aCols[13]:nEditType := EDIT_GET  
   oBrw:aCols[13]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(12,xval)} 
   PintaBrw(oBrw,0)          
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Cambiar"  OF oDlg SIZE 30,10 ACTION ((lrta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg SIZE 30,10 ACTION ((lrta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
    oApp:oServer:Execute("DROP TABLE articu_temp") 
   RETURN 
ENDIF
IF !MsgNoYes("Está a punto de cambiar los precios de todo el grupo"+CHR(10)+;
            "de articulos que está visualizando."+chr(10)+;
            "Realmente desea confirmar el proceso?","Atencion")
   LOOP
ENDIF 

TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre (codigo,preciocos,precossiva,precioven,reventa,fecmod,usuario,ip) "+;
                       "(SELECT a.codigo,IF(a1.costofin>0,a1.costofin,a.preciocos),a1.preciocos1,TRUNCATE(a1.precioven1,0),"+;
                       "TRUNCATE(a1.reventa1,0),CURDATE(),"+ClipValue2Sql(oApp:usuario)+",'Cambio General x %' "+;
                       "FROM ge_"+oApp:cId+"articu a INNER JOIN articu_temp a1 ON a1.codigo = a.codigo "+;
                       "WHERE a.precioven<>TRUNCATE(a1.precioven1,0) AND a1.codigo IS NOT NULL)") 
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a INNER JOIN articu_temp a1 ON a.codigo = a1.codigo "+;
                       "SET a.precossiva    =  a1.preciocos1 ,"+;
                       "    a.preciocos     =  IF(a1.costofin>0,a1.costofin,a.preciocos),"+;
                       "    a.porcentaje    =  IF(a1.incru1>0,a1.incru1,a.porcentaje),"+;
                       "    a.precioven     =  TRUNCATE(a1.precioven1,0), "+;  
                       "    a.porcentajerev =  IF(a1.incruR1>0,a1.incruR1,a.porcentajerev),"+;
                       "    a.reventa       =  TRUNCATE(a1.reventa1,0), "+;                
                       "    a.fecmod=IF(a.precioven<>TRUNCATE(a1.precioven1,0),CURDATE(),a.fecmod),"+;
                       "    a.horamod=IF(a.precioven<>TRUNCATE(a1.precioven1,0),CURTIME(),a.horamod)" )

  oApp:oServer:Execute("DROP TABLE articu_temp")                   
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO  

RETURN 


***************************************************************************************************
STATIC FUNCTION Filtrar(nImpo, nPorc,nPorcUn,nPorcUnR)
LOCAL i := 0, cCostoDesc:= "IF(a.siniva,a.precossiva,100*a.precossiva/(100+(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)))",;
        cCostoFlete,cCostoFin,cIncrCostoF,cIncrCostoB, cPorUti1, cPorUti2

cCostoFlete:= "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100)) ) "
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc2/100)) )"
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc3/100)) )"
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc4/100)) )"
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc5/100)) )"


cCostoFin:=  "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100))) "
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc2/100)))"
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc3/100)))"
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc4/100)))"
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc5/100)))"
cCostoFin:=  "("+cCostoFin+" + (("+cCostoFin+"*(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)/100)) + "+;
             " impint + ("+cCostoFlete+"*flete/100) ) "
       

cIncrCostoF:= "("+cCostoFin+" + " +IF(lVenta,"0",ClipValue2SQL(nImpo))+" + "+cCostoFin+" * (" + ClipValue2SQL(nPorc/100)+"))"
cIncrCostoB:= "(a.precossiva + " +IF(lVenta,"0",ClipValue2SQL(nImpo))+" + a.precossiva * (" + ClipValue2SQL(nPorc/100)+"))"

IF filt()
 oQryTemp:Zap()
 IF ((nPorc + nImpo + nPorcUn) = 0) .or. (nPorcUn >0)
   IF lSumaUtilidad
      cPorUti1 := "(a.porcentaje + "+STR(nPorcUn)+")" 
      cPorUti2 := "(a.porcentajerev + "+STR(nPorcUnR)+")" 
      ELSE
      cPorUti1 := "("+STR(nPorcUn)+")"
      cPorUti2 := "("+STR(nPorcUnR)+")"
   ENDIF 
   /*oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru,precioven,incruR,reventa, preciocos1,costofin, incru1,precioven1,incruR1,reventa1) "+;
                        "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje,a.precioven,a.porcentajerev,a.reventa, a.precossiva,"+ClipValue2Sql(cCostoFin)+","+;
                        ClipValue2Sql(nPorcUn) + ","+cCostoFin+"+("+cCostoFin+"*"+ClipValue2Sql(nPorcUn)+"/100),"+;
                        ClipValue2Sql(nPorcUnR) + ","+cCostoFin+"+("+cCostoFin+"*"+ClipValue2Sql(nPorcUnR)+"/100) "+;
                        " FROM ge_"+oApp:cId+"articu a WHERE " + cWhere + ")")*/
    oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru,precioven,incruR,reventa, preciocos1,costofin, incru1,precioven1,incruR1,reventa1) "+;
                        "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje,a.precioven,a.porcentajerev,a.reventa, a.precossiva,"+ClipValue2Sql(cCostoFin)+","+;
                        cPorUti1 + ","+cCostoFin+"+("+cCostoFin+"*"+cPorUti1+"/100),"+;
                        cPorUti2 + ","+cCostoFin+"+("+cCostoFin+"*"+cPorUti2+"/100) "+;
                        " FROM ge_"+oApp:cId+"articu a WHERE " + cWhere + ")")
 ENDIF
 IF ((nPorc + nImpo) <> 0)

   IF lVenta
    oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru,precioven,incruR,reventa, preciocos1,costofin, incru1,precioven1,incruR1,reventa1)  "+;
                        "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje,a.precioven,a.porcentajerev,a.reventa,"+;
                        "a.precossiva,"+cCostoFin+","+;
                        "((a.precioven+(a.precioven*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+")*100)/"+cCostoFin+" -100,"+;
                        "a.precioven+(a.precioven*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+","+;
                        "((a.reventa+(a.reventa*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+")*100)/"+cCostoFin+" -100,"+;
                        "a.reventa+(a.reventa*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+" "+;
                        " FROM ge_"+oApp:cId+"articu a WHERE " + cWhere + ")") 


   ELSE
   oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru,precioven,incruR,reventa, preciocos1,costofin, incru1,precioven1,incruR1,reventa1)  "+;
                        "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje,a.precioven,a.porcentajerev,a.reventa,"+;
                        cIncrCostoB+","+cIncrCostoF+","+;
                        "a.porcentaje,"+cIncrCostoF+"+"+cIncrCostoF+"*(a.porcentaje/100),"+;
                        "a.porcentajerev,"+cIncrCostoF+"+"+cIncrCostoF+"*(a.porcentajerev/100) "+;  
                        " FROM ge_"+oApp:cId+"articu a WHERE " + cWhere + ")") 
   ENDIF
ENDIF
DO CASE 
   CASE nRedondeo = 1
   CASE nRedondeo = 2
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = ROUND(precioven1), reventa1 = ROUND(reventa1)") 
   CASE nRedondeo = 3
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = ROUND(precioven1,-1), reventa1 = ROUND(reventa1,-1)") 
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = 10 WHERE precioven1 = 0") 
        oApp:oServer:Execute("UPDATE articu_temp SET reventa1 = 10 WHERE reventa1 = 0") 
   CASE nRedondeo = 4
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = ROUND(precioven1,-2), reventa1 = ROUND(reventa1,-2)") 
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = 100 WHERE precioven1 = 0") 
        oApp:oServer:Execute("UPDATE articu_temp SET reventa1 = 100 WHERE reventa1 = 0")    
ENDCASE
oQryTemp:Refresh(.t.)
oBrw:Refresh()
ENDIF
RETURN nil


***********************************************************************************************

STATIC FUNCTION filt ()
   
LOCAL vMarca,cMarc:=SPACE(30),vRubro,cRub:=SPACE(30),vempresa,cEmp:=SPACE(30),;
      vdepto,cDept:=SPACE(30),vProv,cProve:=SPACE(30),vcodigo,cNomArt:=SPACE(30),vnosale:=.f.,;
      vnombre:=SPACE(30),vnomregi:=SPACE(30),vstockmin,vstockact,vstockide,;
      vpreciocos,viva,cNomIva:=SPACE(30),vdesc1,vdesc2,vdesc3,vdesc4,vdesc5,;
      vprecioven,vpresugeri,vprecossiva,vpreciopro,vporcentaje,vfecmodd:="  /  /    ",vfecmodh:="  /  /    ",;
      vfecultcomd:="  /  /    ",vfecultcomh:="  /  /    ",oSay1,oSay2,;
      vneto,vimpint,vflete,vunimed,vobserva,cIvaNom:=SPACE(30),;
      oFilt, acor:=ARRAY(4), oBot:=ARRAY(2), lRta:=.f., oGet:=ARRAY(50),;
      vpesable:=.f.,vcombustible:=.f.,vmprima:=.f.,vproduccion:=.f.,;
      vmedida,ventero,vuxbulto,vpxbulto,vsiniva:=.f.
     

DO WHILE .T.          
  DEFINE DIALOG oFilt TITLE "Seleccion de articulos" RESOURCE "ABMART1" OF oDlg 
  oFilt:lHelpIcon := .f.
  REDEFINE GET oGet[01] VAR vcodigo ID 100 OF oFilt/* PICTURE "99999999999999" ;
               VALID(EMPTY(oGet[01]:cText) .or. Buscar(oQryArt,oFilt,oGet[01],oGet[02]));
              ACTION (oGet[01]:cText:= 0, Buscar(oQryArt,oFilt,oGet[01],oGet[02])) BITMAP "BUSC1"*/
  REDEFINE GET oGet[02] VAR vnombre PICTURE "@!" ID 101 OF oFilt 
  REDEFINE GET oGet[03] VAR vnomregi ID 102 OF oFilt 
  REDEFINE CHECKBOX oGet[34] VAR vnosale ID 103 
  REDEFINE CHECKBOX oGet[46] VAR vpesable ID 4011 OF oFilt 
  *REDEFINE CHECKBOX oGet[43] VAR vcombustible ID 4005 OF oFilt
  *REDEFINE CHECKBOX oGet[44] VAR vmprima      ID 4007 OF oFilt
  *REDEFINE CHECKBOX oGet[45] VAR vproduccion  ID 4008 OF oFilt

  REDEFINE GET oGet[04] VAR vprov ID 104 OF oFilt ;
               VALID(EMPTY(oGet[04]:cText) .or. Buscar(oQry2,oFilt,oGet[04],oGet[05]));
               ACTION (oGet[04]:cText:= 0, Buscar(oQry2,oFilt,oGet[04],oGet[05])) BITMAP "BUSC1"
  REDEFINE GET oGet[05] VAR cProve          ID 105 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[21] VAR vmarca ID 122 OF oFilt ;
               VALID(EMPTY(oGet[21]:cText) .or. Buscar(oQry4,oFilt,oGet[21],oGet[22]));
               ACTION (oGet[21]:cText:= 0, Buscar(oQry4,oFilt,oGet[21],oGet[22])) BITMAP "BUSC1"
  REDEFINE GET oGet[22] VAR cMarc      ID 123 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[23] VAR vrubro ID 124 OF oFilt ;
               VALID(EMPTY(oGet[23]:cText) .or. Buscar(oQry5,oFilt,oGet[23],oGet[24]));
               ACTION (oGet[23]:cText:= 0, Buscar(oQry5,oFilt,oGet[23],oGet[24])) BITMAP "BUSC1"
  REDEFINE GET oGet[24] VAR cRub ID 125 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[27] VAR vempresa ID 126 OF oFilt ;
               VALID(EMPTY(oGet[27]:cText) .or. Buscar(oQry7,oFilt,oGet[27],oGet[28]));
               ACTION (oGet[27]:cText:= 0, Buscar(oQry7,oFilt,oGet[27],oGet[28])) BITMAP "BUSC1"
  REDEFINE GET oGet[28] VAR cEmp ID 127 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[25] VAR vdepto ID 128 OF oFilt ;
               VALID(EMPTY(oGet[25]:cText) .or. Buscar(oQry6,oFilt,oGet[25],oGet[26]));
               ACTION (oGet[25]:cText:= 0, Buscar(oQry6,oFilt,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[26] VAR cDept ID 129 OF oFilt WHEN (.F.)

  
  REDEFINE GET oGet[35] VAR vunimed     ID 135 OF oFilt PICTURE "@!"
  REDEFINE GET oGet[47] VAR vmedida     ID 500 OF oFilt PICTURE "9999999"
  REDEFINE GET oGet[48] VAR ventero     ID 501 OF oFilt PICTURE "9999999"
  REDEFINE GET oGet[49] VAR vuxbulto    ID 502 OF oFilt PICTURE "99999"
  REDEFINE GET oGet[50] VAR vpxbulto    ID 503 OF oFilt PICTURE "99999999.99"


  REDEFINE CHECKBOX oGet[46] VAR vsiniva  ID 4003 OF oFilt
  REDEFINE GET oGet[06] VAR vprecossiva ID 106 OF oFilt 
  REDEFINE GET oGet[07] VAR vdesc1      ID 107 OF oFilt 
  REDEFINE GET oGet[08] VAR vdesc2      ID 108 OF oFilt 
  REDEFINE GET oGet[09] VAR vdesc3      ID 109 OF oFilt 
  REDEFINE GET oGet[10] VAR vdesc4      ID 110 OF oFilt 
  REDEFINE GET oGet[11] VAR vdesc5      ID 111 OF oFilt 
  REDEFINE GET oGet[39] VAR vNeto ID 112 OF oFilt 
  REDEFINE GET oGet[12] VAR vimpint ID 113 OF oFilt 
  REDEFINE GET oGet[13] VAR vflete ID 114 OF oFilt 
  REDEFINE GET oGet[14] VAR viva ID 115 OF oFilt ;
              VALID(EMPTY(oGet[14]:cText) .or. (Buscar(oQry3,oFilt,oGet[14],oGet[15]) .and. ;             
               ((oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx"))  );
               ACTION (oGet[14]:cText:= 0, Buscar(oQry3,oFilt,oGet[14],oGet[15]),;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx" ) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom ID 116 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[16] VAR vpreciocos ID 117 OF oFilt 
  REDEFINE GET oGet[17] VAR vporcentaje ID 118 OF oFilt 
  REDEFINE GET oGet[18] VAR vpreciopro ID 119 OF oFilt 
  REDEFINE GET oGet[19] VAR vpresugeri ID 120 OF oFilt 
  REDEFINE GET oGet[20] VAR vprecioven ID 121 OF oFilt 
  

  //FECHAS
  REDEFINE GET oGet[41] VAR vfecultcomd ID 1300 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay1 PROMPT "Hasta ultima compra:" ID 802 OF oFilt
  REDEFINE GET oGet[29] VAR vfecultcomh ID 130 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay2 PROMPT "Desde cambio precio:" ID 803 OF oFilt
  REDEFINE GET oGet[30] VAR vfecmodd    ID 131 OF oFilt PICTURE "@D"
  REDEFINE GET oGet[42] VAR vfecmodh    ID 1311 OF oFilt PICTURE "@D"

  REDEFINE GET oGet[31] VAR vstockmin ID 132 OF oFilt
  REDEFINE GET oGet[32] VAR vstockact ID 133 OF oFilt
  REDEFINE GET oGet[33] VAR vstockide ID 134 OF oFilt
  REDEFINE GET oGet[36] VAR vobserva  ID 136 OF oFilt

  REDEFINE BUTTON oBot[1] ID 137 OF oFilt;
           ACTION ((lRta := .t.), oFilt:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oFilt;
           ACTION ((lRta := .f.), oFilt:End() ) CANCEL
 
ACTIVATE DIALOG oFilt CENTER ON INIT (oGet[01]:SetFocus(),oGet[34]:Hide())

IF !lRta
   RETURN .f.
ENDIF

cWhere = " 1=1 " + IF(EMPTY(vCodigo),""," and a.CODIGO =" + ClipValue2SQL(VCodigo) + "") ;
            + "" + IF(EMPTY(VNOMBRE),"","  and TRIM(a.NOMBRE) like '%" + ALLTRIM(VNOMBRE) + "%'") ;
            + "" + IF(EMPTY(Vnomregi),"","  and TRIM(a.nomregi) like '%" + ALLTRIM(Vnomregi) + "%'") ;
            + "" + IF(!vnosale,""," and a.nosale = TRUE ");
            + "" + IF(!vpesable,""," and a.pesable = TRUE ");
            + "" + IF(!vcombustible,""," and a.combustible = TRUE");
            + "" + IF(!vmprima,""," and a.mprima = TRUE ");
            + "" + IF(!vproduccion,""," and a.produccion = TRUE ");
            + "" + IF(!vsiniva,""," and a.siniva = TRUE ");
            + "" + IF(EMPTY(vProv),""," and a.prov =" + ClipValue2SQL(vProv) + "") ;
            + "" + IF(EMPTY(vMarca),""," and a.marca =" + ClipValue2SQL(vMarca) + "") ;
            + "" + IF(EMPTY(vRubro),""," and a.rubro =" + ClipValue2SQL(vRubro) + "") ;
            + "" + IF(EMPTY(vempresa),""," and a.empresa =" + ClipValue2SQL(vempresa) + "") ;
            + "" + IF(EMPTY(vdepto),""," and a.depto =" + ClipValue2SQL(vdepto) + "") ;
            + "" + IF(EMPTY(vStockmin),""," and a.stockmin =" + ClipValue2SQL(vstockmin) + "") ; 
            + "" + IF(EMPTY(vmedida),""," and a.medida =" + ClipValue2SQL(vmedida) + "") ;
            + "" + IF(EMPTY(ventero),""," and a.entero =" + ClipValue2SQL(ventero) + "") ;
            + "" + IF(EMPTY(vuxbulto),""," and a.uxbulto =" + ClipValue2SQL(vuxbulto) + "") ;
            + "" + IF(EMPTY(vpxbulto),""," and a.pxbulto =" + ClipValue2SQL(vpxbulto) + "") ;
            + "" + IF(EMPTY(vStockact),""," and a.stockact =" + ClipValue2SQL(vstockact) + "") ;
            + "" + IF(EMPTY(vstockide),""," and a.stockide =" + ClipValue2SQL(vstockide) + "") ;
            + "" + IF(EMPTY(vunimed),"","  and TRIM(a.unimed) like '%" + ALLTRIM(vunimed) + "%'");
            + "" + IF(EMPTY(vpreciocos),""," and a.preciocos =" + ClipValue2SQL(vpreciocos) + "") ;
            + "" + IF(EMPTY(vporcentaje),""," and a.porcentaje =" + ClipValue2SQL(vporcentaje) + "") ;
            + "" + IF(EMPTY(vprecossiva),""," and a.precossiva =" + ClipValue2SQL(vprecossiva) + "") ;
            + "" + IF(EMPTY(vneto),""," and a.neto =" + ClipValue2SQL(vneto) + "") ;
            + "" + IF(EMPTY(vimpint),""," and a.impint =" + ClipValue2SQL(vimpint) + "") ;
            + "" + IF(EMPTY(vflete),""," and a.flete =" + ClipValue2SQL(vflete) + "") ;
            + "" + IF(EMPTY(viva),""," and a.iva =" + ClipValue2SQL(viva) + "") ;
            + "" + IF(EMPTY(vdesc1),""," and a.desc1 =" + ClipValue2SQL(vdesc1) + "") ;
            + "" + IF(EMPTY(vdesc2),""," and a.desc2 =" + ClipValue2SQL(vdesc2) + "") ;
            + "" + IF(EMPTY(vdesc3),""," and a.desc3 =" + ClipValue2SQL(vdesc3) + "") ;
            + "" + IF(EMPTY(vdesc4),""," and a.desc4 =" + ClipValue2SQL(vdesc4) + "") ;
            + "" + IF(EMPTY(vdesc5),""," and a.desc5 =" + ClipValue2SQL(vdesc5) + "") ;            
            + "" + IF(EMPTY(vprecioven),""," and a.precioven =" + ClipValue2SQL(vprecioven) + "") ;
            + "" + IF(EMPTY(vpreciopro),""," and a.preciopro =" + ClipValue2SQL(vpreciopro) + "") ; 
            + "" + IF(EMPTY(vpresugeri),""," and a.presugeri =" + ClipValue2SQL(vpresugeri) + "") ; 
            + "" + IF(vfecultcomd="  /  /    ",""," and a.fecultcom >=" + ClipValue2SQL(CTOD(vfecultcomd)) + "") ;
            + "" + IF(vfecultcomh="  /  /    ",""," and a.fecultcom <=" + ClipValue2SQL(CTOD(vfecultcomh)) + "") ;
            + "" + IF(vfecmodd="  /  /    ",""," and a.fecmod >=" + ClipValue2SQL(CTOD(vfecmodd)) + "") ;
            + "" + IF(vfecmodh="  /  /    ",""," and a.fecmod <=" + ClipValue2SQL(CTOD(vfecmodh)) + "") ;
            + "" + IF(EMPTY(vobserva),"","  and TRIM(a.observa) like '%" + ALLTRIM(vobserva) + "%'") ;
 
       EXIT
   ENDDO
  

RETURN .t.   


PROCEDURE PREGENLIS()
LOCAL oGet := ARRAY(3),  oBot := ARRAY(2), lRta := .f., oBrwTmp, aCols, oBrw, cCostoDesc, cCostoFlete,;
      aCor, base, oError, oFont, oBrwDet, oQryDet , oForm, oQryPro,mcodpro := 0, cNomPro := SPACE(30), i, nError,cCostoFin
oQryPro := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"provee")
aCols := {{SPACE(14),SPACE(30),0.00,SPACE(30),0,0,0}}
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .t.
DEFINE DIALOG oForm TITLE "Cambio de Precios por Excel " FROM 03,15 TO 35,140
   acor := AcepCanc(oForm)   
   
   // Datos del programa de inasistencia
   @ 07, 05 SAY "Proveedor:"           OF oForm PIXEL RIGHT SIZE 65,10
   @ 35, 05 SAY "Aqui podrá importar la lista de precios desde un Excel que su proveedor le pase. "+CHR(10)+;
                "IMPORTANTE: Los códigos del proveedor y su correspondiente con el código del sistema "+;
                "deben estar previamente asignados en el proveedor. "+CHR(10)+;
                "IMPORTANTE 2: El código del proveedor debe estar en la columna 1 del Excel,"+;
                " y el precio de costo en la columna 3 del Excel, y deberán estar SIN FORMATO." OF oForm PIXEL SIZE 285,70   
   @ 20, 05 XBROWSE oBrwTmp SIZE 465,180 pixel OF oForm ARRAY aCols ;
      HEADERS "Cod.Prov.", "Producto","Costo","Observaciones","Cod.Propio","UxB","Costo Bulto";
      PICTURE "@!","@!","9999999.999","@!","99999999999999","999","999999999.99";
      COLUMNS 1, 2 ,3, 4, 5, 6, 7;
      SIZES 80,240,70,240,70,80,70,70;
      CELL LINES NOBORDER 
   WITH OBJECT oBrwTmp
      :nEditTypes := 1  
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
      :CreateFromCode()
      :aCols[3]:nEditType := EDIT_GET
      :aCols[6]:nEditType := EDIT_GET
      :aCols[6]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,oBrwTmp,@aCols)}
   END  
   @ 205,05 SAY "Aqui podrá importar la lista de precios desde un Excel que su proveedor le pase. "+CHR(10)+;
                "IMPORTANTE: Los códigos del proveedor y su correspondiente con el código del sistema "+;
                "deben estar previamente asignados en el proveedor. "+CHR(10)+;
                "IMPORTANTE 2: El código del proveedor debe estar en la columna 1 del Excel,"+;
                " y el precio de costo en la columna 3 del Excel, y deberán estar SIN FORMATO." SIZE 465,60 OF oForm PIXEL 
   PintaBrw(oBrwTmp,0)   

   @ 05, 70 GET oGet[01] VAR mcodpro     OF oForm PICTURE "999999" PIXEL SIZE 25,12 RIGHT;
                         VALID(Buscar(oQryPro,oForm,oGet[1],oGet[2]));
                         ACTION (oGet[1]:cText:= 0, Buscar(oQryPro,oForm,oGet[1],oGet[2])) BITMAP "BUSC1"  
   @ 05,105 GET oGet[02] VAR cNomPro         OF oForm PIXEL PICTURE "@!" WHEN(.F.)    
   @ 05,300 BUTTON oBot[1] PROMPT "&Pegar" OF oForm SIZE 30,10 ;
           ACTION (Procesando(.t.),oBrwTmp:Paste(),Recalc(oBrwTmp),Procesando(.f.)) PIXEL WHEN( mcodpro>0)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Procesar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[1],acor[2]+60 BUTTON oBot[1] PROMPT "&Borra Errores" OF oForm SIZE 50,10 ;
           ACTION (BorrarErr(oBrwTmp,aCols)) PIXEL
   @ acor[1],acor[2]+60+90 BUTTON oBot[1] PROMPT "&Procesar con UXB" OF oForm SIZE 50,10 ;
           ACTION (ProcesarUxB(oBrwTmp,aCols,mcodpro)) PIXEL        
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN 
ENDIF
Procesando(.t.)
** Validaciones
nError := 0
FOR i := 1 TO LEN(aCols)
    IF EMPTY(aCols[i,1])
       nError ++
       aCols[i,4] := "No puede estar vacio "
       nError ++
       ELSE 
       IF oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
          " WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):nRecCount = 0
          nError ++
          aCols[i,4] := "NO EXISTE en tu sistema para este proveedor"
          ELSE 
          aCols[i,5] := oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
          " WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):codart
       ENDIF
    ENDIF
    IF EMPTY(aCols[i,3])
       nError ++
       aCols[i,4] := "No puede estar en cero"
    ENDIF    
NEXT
Procesando(.f.)
IF nError > 0
   MsgStop("Hay "+STR(nError,5)+" errores","Errores")
   LOOP
ENDIF
EXIT
ENDDO
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS articu_temp ";
    +"("; 
    +"`CODIGO`     BIGINT(14) NOT NULL,";
    +"`NOMBRE`     VARCHAR(50) NOT NULL,";
    +"`preciocos`  DECIMAL(12,2) DEFAULT '0',";
    +"`preciocos1` DECIMAL(12,2) DEFAULT '0',";
    +"`incru`      DECIMAL(12,2) DEFAULT '0',";  
    +"`incru1`     DECIMAL(12,2) DEFAULT '0',";
    +"`uxbulto`    INT(4) DEFAULT '0',";
    +"`pxbulto`    DECIMAL (12,2) DEFAULT '0.00'";
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:Execute("TRUNCATE articu_temp")

FOR i := 1 TO LEN(aCols)
    oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru, preciocos1, incru1, uxbulto,pxbulto) "+;
                        "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje, "+;
                        ClipValue2Sql(aCols[i,3]) + ",a.porcentaje, "+;
                        ClipValue2Sql(aCols[i,6]) + ","+ClipValue2Sql(aCols[i,7]) + ""+;
                        " FROM ge_"+oApp:cId+"articu a WHERE a.codigo = " + ClipValue2Sql(aCols[i,5])+ ")")
NEXT i
oQryTemp  :=oApp:oServer:Query("SELECT * FROM articu_temp")
DEFINE DIALOG oForm TITLE "Resultado de la importacion" FROM 02,01 TO 20,78 OF oApp:oWnd
   acor := AcepCanc( oForm )   
   @ 05,02 XBROWSE oBrw DATASOURCE oQryTemp ;
             COLUMNS "codigo","nombre","preciocos","incru","preciocos1","incru1","uxbulto","pxbulto";
             HEADERS "Codigo","Articulo", "Costo Act.","Utilidad","Nuevo Costo","Utilidad Nuevo","UxBto","PxBto";
             SIZES   50, 210, 60, 60, 70, 90, 90, 90;
             OF oForm SIZE 300, 88 AUTOSORT PIXEL
   oBrw:CreateFromCode()
   oBrw:aCols[5]:lAutoSave := .t.
   oBrw:nMoveType := 4
   oBrw:aCols[5]:nEditType := EDIT_GET
   oBrw:aCols[6]:lAutoSave := .t.
   oBrw:nMoveType := 4
   oBrw:aCols[6]:nEditType := EDIT_GET
   PintaBrw(oBrw,0)          
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Cambiar"  OF oForm SIZE 30,10 ACTION ((lrta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ACTION ((lrta := .f.), oForm:End() ) PIXEL
ACTIVATE DIALOG oForm CENTER 

IF !lRta
   oApp:oServer:Execute("DROP TABLE articu_temp") 
   RETURN 
ENDIF

TRY
 oApp:oServer:BeginTransaction()
cCostoDesc:= "IF(a.siniva,a1.preciocos1,100*a1.preciocos1/(100+(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)) ) "

cCostoFlete:= "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100)) ) "
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc2/100)) )"
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc3/100)) )"
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc4/100)) )"
cCostoFlete:= "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc5/100)) )"


cCostoFin:=  "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100))) "
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc2/100)))"
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc3/100)))"
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc4/100)))"
cCostoFin:=  "("+cCostoFin+" - ("+cCostoFin+" *(a.desc5/100)))"
cCostoFin:=  "("+cCostoFin+" + (("+cCostoFin+"*(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)/100)) + "+;
             " impint + ("+cCostoFlete+"*flete/100) ) "
 oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre (codigo,preciocos,precossiva,precioven,reventa,fecmod,usuario,ip) "+;
                       "(SELECT a.codigo,"+cCostoFin+",a1.preciocos1,TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentaje/100),0),"+;
                       "TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentajerev/100),0),CURDATE(),"+ClipValue2Sql(oApp:usuario)+",'Cambio Lista Prov.' "+;
                       "FROM ge_"+oApp:cId+"articu a INNER JOIN articu_temp a1 ON a1.codigo = a.codigo "+;
                       "WHERE a.precioven<>TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentaje/100),0) AND a1.codigo IS NOT NULL)") 
 oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a INNER JOIN articu_temp a1 ON a.codigo = a1.codigo "+;
                       "SET a.precossiva   =  a1.preciocos1 ,"+;
                       "    a.porcentaje  =  a1.incru1,"+;
                       "    a.preciocos   =  "+cCostoFin+","+;
                       "    a.precioven   = TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentaje/100),0), "+;
                       "    a.reventa     = TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentajerev/100),0), "+;                
                       "    a.fecmod      = CURDATE(),"+;
                       "    a.horamod     = CURTIME() " )
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a INNER JOIN articu_temp a1 ON a.codigo = a1.codigo "+;
                       "SET a.uxbulto   =  a1.uxbulto ,"+;
                       "    a.pxbulto   =  a1.pxbulto WHERE a1.uxbulto > 1 and a1.pxbulto > 1")
  oApp:oServer:Execute("DROP TABLE articu_temp")                   
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
MsgInfo("Cambios realizados con exito!","Proceso Exitoso!")
RETURN 

***************************************************************************************************************
***** CAMBIA LOS VALORES DEL BROWSE 
STATIC FUNCTION CambiaValor(n,xVal)
LOCAL nNeto,nNeto2,nImpInt,nFlete,nIVA,nNetoPar,oQryArt:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2SQL(oQryTemp:codigo)),;
      nTasa:= oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(oQryArt:iva)):tasa



IF n = 8
    nNeto:= IF(oQryArt:siniva,xVal,xVal/(1+nTasa/100))
    nNeto:= nNeto - nNeto * (oQryArt:desc1/100) 
    nNeto:= nNeto - nNeto * (oQryArt:desc2/100) 
    nNeto:= nNeto - nNeto * (oQryArt:desc3/100) 
    nNeto:= nNeto - nNeto * (oQryArt:desc4/100) 
    nNeto:= nNeto - nNeto * (oQryArt:desc5/100) 
    nImpInt:= nNeto * (oQryArt:impint/100)
    nFlete:= nNeto * (oQryArt:flete/100) 
    nIVA:= nNeto * nTasa/100
    nNeto:= nNeto + nImpInt + nFlete + nIVA
    
    oQryTemp:preciocos1 := xVal
    oQryTemp:costofin   := nNeto
    oQryTemp:precioven1 := nNeto + nNeto  * (oQryTemp:incru1/100)
    oQryTemp:reventa1   := nNeto + nNeto  * (oQryTemp:incruR1/100)

ENDIF
IF n = 9
    oQryTemp:incru1:= xVal
    oQryTemp:precioven1:= oQryTemp:costofin + oQryTemp:costofin * (oQryTemp:incru1/100)
ENDIF

IF n = 10
  oQryTemp:precioven1:= xVal
  oQryTemp:incru1:= (oQryTemp:precioven1 * 100) / oQryTemp:costofin -100
ENDIF  

IF n = 11
    oQryTemp:incruR1:= xVal
    oQryTemp:reventa1:= oQryTemp:costofin + oQryTemp:costofin * (oQryTemp:incruR1/100)
ENDIF

IF n = 12
  oQryTemp:reventa1:= xVal
  oQryTemp:incruR1:= (oQryTemp:reventa1 * 100) / oQryTemp:costofin -100
ENDIF 


oQryTemp:Save()
oQryTemp:Refresh()
oQryTemp:Refresh()
oBrw:Refresh()
RETURN nil


*****************************************
** Cambiar valores de uxb
STATIC FUNCTION CambiaCant(n,oBrw,aCols)
LOCAl i := oBrw:keyno()
aCols[i,6] := n
aCols[i,3] := aCols[i,7] / aCols[i,6] 
oBrw:Refresh()
RETURN nil

STATIC FUNCTION Recalc(oBrw)
LOCAL i, aCols := oBrw:aArrayData
oBrw:GoTop()
FOR i := 1 TO LEN(oBrw:aArrayData)    
    IF oBrw:aArrayData[i,6] = 0
       oBrw:aArrayData[i,7] = oBrw:aArrayData[i,3]    
       oBrw:aArrayData[i,6] = 1
       ELSE 
       oBrw:aArrayData[i,3] = oBrw:aArrayData[i,7] / oBrw:aArrayData[i,6]
    ENDIF   
NEXT i
RETURN nil

STATIC FUNCTION BorrarErr(oBrw)
LOCAL i:=1, aCols := LEN(oBrw:aArrayData)
oBrw:GoTop()
DO WHILE !oBrw:Eof()   
    IF !Empty(oBrw:aCols[4]:Value())
       oBrw:Delete()               
       ELSE 
       oBrw:Skip()              
    ENDIF 
    i++
    IF i > aCols 
       EXIT 
    ENDIF      
ENDDO
RETURN nil

**************************************
** PROCESAR CON UXB 
STATIC FUNCTION ProcesarUxB(oBrwTmp,aCols,mcodpro)
LOCAL i, nError, oQryA
Procesando(.t.)
** Validaciones
nError := 0
FOR i := 1 TO LEN(aCols)
    IF EMPTY(aCols[i,1])
       nError ++
       aCols[i,4] := "No puede estar vacio "
       nError ++
       ELSE 
       IF oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
          " WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):nRecCount = 0
          nError ++
          aCols[i,4] := "NO EXISTE en tu sistema para este proveedor"
          ELSE 
          aCols[i,5] := oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
          " WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):codart
          aCols[i,2] := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu "+;
          " WHERE codigo = "+ClipValue2SQL(aCols[i,5])):nombre
       ENDIF
    ENDIF
    IF EMPTY(aCols[i,3])
       nError ++
       aCols[i,4] := "No puede estar en cero"
    ENDIF 
    IF aCols[i,5] <> 0
       oQryA := oApp:oServer:Query("SELECT uxbulto FROM ge_"+oApp:cId+"articu "+;
               " WHERE codigo = "+ClipValue2SQL(aCols[i,5]))   
       IF oQryA:uxbulto > 0 //.AND. aCols[i,7] = 0
          aCols[i,6] := oQryA:uxbulto
          aCols[i,7] := aCols[i,3]
          aCols[i,3] := aCols[i,7] / aCols[i,6] 
       ENDIF
    ENDIF
NEXT
Procesando(.f.)
IF nError > 0
   MsgStop("Hay "+STR(nError,5)+" errores","Errores")   
ENDIF
oBrwTmp:Refresh()
RETURN nil