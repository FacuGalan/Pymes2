#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** DEPOSTIROS Y RETIROS
*************************************************
MEMVAR oApp
STATIC oQryBrw,oQry,oQry2, oWnd1, oBrw, oDlg, cVentana
PROCEDURE DEPRET(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
oQryBrw:= oApp:oServer:Query("SELECT d.*, c.nombre AS nomban FROM ge_"+oApp:cId+"deposito d " +;
                             " LEFT JOIN ge_"+oApp:cId+"cuentas c ON d.banco = c.codigo ")

oQry2 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cuentas ORDER BY codigo")



  DEFINE WINDOW oWnd1 MDICHILD TITLE "Depositos y retiros en cuentas" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos) 
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja " TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos)
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Depositos y retiros en cuentas",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "TRANSF" OF oBar ;
            TOOLTIP "Transferencia entre dos cuenta"  ;
            ACTION (Transfe( ),oBrw:Refresh());
            PROMPT "Transf. " TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Datos"  ;
            ACTION (Filtrar( ),oBrw:Refresh());
            PROMPT "Filtra" TOP 
        // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "id","fecacr","nomban","detalle","tipo","importe";
              HEADERS "Regist.","Fecha","Cuenta bancaria","Detalle","Tipo","Importe";
              SIZES 80,80,250,180,60,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu( .f.),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[4]:bStrData := {|| IF(oQryBrw:RecCount()> 0 .and. (oQryBrw:tipo="D"),"Deposito","Retiro")}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,6) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(11), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,cBanco:=SPACE(30),;
      cTipo:={"Deposito","Retiro"},cNomTip:=SPACE(30),oQryTip, mobserva
oQryTip:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"tipodepo")
IF lAlta
   oQry := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deposito LIMIT 0")
   base := oQry:GetBlankRow()
   base:id:= oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"deposito")
   base:tipo:= "Deposito"
   base:fecacr:=DATE()
   base:fecemi:=DATE()
   ELSE
   oQry   := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deposito WHERE id = " + ClipValue2SQL(oQryBrw:id))
   base := oQry:GetRowObj()
   oQry2:GoTop()
   IF oQry2:Seek(base:banco,1) > 0
      cBanco := oQry2:nombre
   ENDIF 
   oQryTip:GoTop()
   IF oQryTip:Seek(base:codtip,1) > 0
      cNomTip := oQryTip:nombre
   ENDIF 
   IF base:tipo = "D"
      base:tipo:= "Deposito"
   ELSE
      base:tipo:= "Retiro"
   ENDIF
ENDIF

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Deposito/Retiro";
       FROM 05,15 TO 25,69 OF oWnd1
   
   @ 07, 05 SAY "Cuenta:"                  OF oForm PIXEL SIZE 50,12 RIGHT 
   @ 22, 05 SAY "Fecha:"                   OF oForm PIXEL SIZE 50,12 RIGHT  
   @ 37, 05 SAY "Tipo de operación:"       OF oForm PIXEL SIZE 50,12 RIGHT
   @ 52, 05 SAY "Tipo de depósito/retiro:" OF oForm PIXEL SIZE 50,12 RIGHT
   @ 67, 05 SAY "Fecha de emisión:"        OF oForm PIXEL SIZE 50,12 RIGHT
   @ 82, 05 SAY "N° de operación:"         OF oForm PIXEL SIZE 50,12 RIGHT
   @ 97, 05 SAY "Detalle:"                 OF oForm PIXEL SIZE 50,12 RIGHT
   @112, 05 SAY "Importe:"                 OF oForm PIXEL SIZE 50,12 RIGHT

   @ 05, 65 GET oGet[1] VAR base:banco PICTURE "99999999" OF oForm PIXEL RIGHT;
                  VALID(Buscar(oQry2,oForm,oGet[1],oGet[2]));
                  ACTION (oGet[1]:cText:= 0, Buscar(oQry2,oForm,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 05,100 GET oGet[2] VAR cBanco PICTURE "@!" OF oForm PIXEL  WHEN(.F.)
   @ 20, 65 GET oGet[3] VAR base:fecacr    PICTURE "@D"  OF oForm PIXEL CENTER    
   @ 35, 65 COMBOBOX oGet[5] VAR base:tipo  ITEMS cTipo  SIZE 40,20 PIXEL
   @ 50, 65 GET oGet[6] VAR base:codtip OF oForm PIXEL PICTURE "99" SIZE 30,12 RIGHT;
                VALID(Buscar(oQrytip,oForm,oGet[6],oGet[11]));
                ACTION (oGet[6]:cText:= 0, Buscar(oQrytip,oForm,oGet[6],oGet[11])) BITMAP "BUSC1"
   @ 50, 95 GET oGet[11] VAR cNomTip OF oForm PIXEL PICTURE "@!" WHEN(.F.)
   @ 65, 65 GET oGet[7] VAR base:fecemi OF oForm PIXEL PICTURE "@D" CENTER
   @ 80, 65 GET oGet[8] VAR base:numope OF oForm PIXEL PICTURE "999999" RIGHT
   @ 95, 65 GET oGet[9] VAR base:detalle OF oForm PIXEL PICTURE "@!"
   @110, 65 GET oGet[10] VAR base:importe OF oForm PIXEL PICTURE "999999999.99" RIGHT;
                VALID(base:importe>0)
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF

IF base:importe = 0 
   MsgStop("Valor no valido:Importe en 0 ","Error")
   LOOP
ENDIF

IF lAlta
   oQry:GetBlankRow()
ENDIF
base:tipo:= LEFT(base:tipo,1)

base:usuario:= oApp:usuario
base:ip     := oApp:cIp
base:fecmod := DATE()

oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQryBrw:Refresh(.t.)
  IF lAlta
      IF base:codtip = 1
         mobserva = IF(base:tipo = "R","Retiro","Deposito")+" Bancario"
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"retiros (importe,fecha, observa, tipo, checkeado, caja, usuario  ) "+;
                              " VALUES ("+;
                           ClipValue2Sql(base:importe)+",CURDATE(),"+ClipValue2Sql(mobserva)+","+IF(base:tipo='R',"'I'","'R'")+",false,"+;
                           ClipValue2Sql(oApp:prefijo)+","+ClipValue2Sql(oApp:usuario)+")")
      ENDIF
  ENDIF    
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Transfe()
LOCAL oGet := ARRAY(11), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,;
      nBancoDe:=0,nBancoA:=0,cBancoDe:=SPACE(30),cBancoA:=SPACE(30),dFecAcr:=DATE(),dFecEmi:=DATE(),;
      nNumOpe:=0,cDetalle:=SPACE(30),nImporte:=0

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Deposito/Retiro";
       FROM 05,15 TO 23,69 OF oWnd1
   
   @ 07, 05 SAY "De cuenta:"               OF oForm PIXEL SIZE 40,12 RIGHT 
   @ 22, 05 SAY "A cuenta:"                OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Fecha:"                   OF oForm PIXEL SIZE 40,12 RIGHT  
   @ 52, 05 SAY "Fecha de emisión:"        OF oForm PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "N° de operación:"         OF oForm PIXEL SIZE 40,12 RIGHT
   @ 82, 05 SAY "Detalle:"                 OF oForm PIXEL SIZE 40,12 RIGHT
   @ 97, 05 SAY "Importe:"                 OF oForm PIXEL SIZE 40,12 RIGHT

   @ 05, 50 GET oGet[1] VAR nbancode PICTURE "99999999" OF oForm PIXEL RIGHT;
                  VALID(Buscar(oQry2,oForm,oGet[1],oGet[2]));
                  ACTION (oGet[1]:cText:= 0, Buscar(oQry2,oForm,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 05, 90 GET oGet[2] VAR cBancode PICTURE "@!" OF oForm PIXEL  WHEN(.F.)
   @ 20, 50 GET oGet[3] VAR nbancoa PICTURE "99999999" OF oForm PIXEL RIGHT;
                  VALID(Buscar(oQry2,oForm,oGet[3],oGet[4]));
                  ACTION (oGet[3]:cText:= 0, Buscar(oQry2,oForm,oGet[3],oGet[4])) BITMAP "BUSC1"
   @ 20, 90 GET oGet[4] VAR cBancoa PICTURE "@!" OF oForm PIXEL  WHEN(.F.)
   @ 35, 50 GET oGet[5] VAR dfecacr OF oForm PIXEL PICTURE "@D" CENTER    
   @ 50, 50 GET oGet[6] VAR dfecemi OF oForm PIXEL PICTURE "@D" CENTER
   @ 65, 50 GET oGet[7] VAR nnumope OF oForm PIXEL PICTURE "999999" RIGHT
   @ 80, 50 GET oGet[8] VAR cdetalle OF oForm PIXEL PICTURE "@!"
   @ 95, 50 GET oGet[9] VAR nimporte OF oForm PIXEL PICTURE "99999999.99" RIGHT;
                VALID(nimporte>0)
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF

IF nimporte = 0 
   MsgStop("Valor no valido:Importe en 0 ","Error")
   LOOP
ENDIF

TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                        " (banco,tipo,fecemi,fecacr,codtip,numope,detalle,importe) VALUES "+;
                        " ("+;
                          ClipValue2SQL(nBancoDe)+","+;
                          "'R',"+;
                          ClipValue2SQL(dFecEmi)+","+;
                          ClipValue2SQL(dFecAcr)+","+;
                          "1,"+;
                          ClipValue2SQL(nNumOpe)+","+;
                          ClipValue2SQL(cDetalle)+","+;
                          ClipValue2SQL(nImporte)+")")
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                        " (banco,tipo,fecemi,fecacr,codtip,numope,detalle,importe) VALUES "+;
                        " ("+;
                          ClipValue2SQL(nBancoA)+","+;
                          "'D',"+;
                          ClipValue2SQL(dFecEmi)+","+;
                          ClipValue2SQL(dFecAcr)+","+;
                          "1,"+;
                          ClipValue2SQL(nNumOpe)+","+;
                          ClipValue2SQL(cDetalle)+","+;
                          ClipValue2SQL(nImporte)+")")
  oQryBrw:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
IF oQry <> nil
   oQry:End()
ENDIF  

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

mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF

TRY
  oApp:oServer:BeginTransaction()
  oQry   := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deposito WHERE id = " + ClipValue2SQL(oQryBrw:id))
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.t.)

CATCH oError
  MsgStop("Error al borrar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
oBrw:Refresh()
RETURN nil 


******************************************

STATIC FUNCTION Filtrar( )

LOCAL CWHERE, vdesde := CTOD("01/01/1990"), vhasta := CTOD("31/12/2500"), nEstado := 1 
LOCAL oGet1, oGet2, oGet3, oGet4, oGet5, nCuenta := 0, oBot1, oBot2,oDlg1,base,oError, ;
      mrta := .f., aCor, aEstado := {"Todos","Depositos","Retiros"}, aEst := {" ","D","R"} ,;
      cTodos := "Todas los cuentas          ", cCuenta := cTodos


DEFINE DIALOG oDlg1 TITLE "Filtrado de movimientos" FROM 05,10 TO 16,70 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Desde Fecha:"    OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:"    OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Tipo:"           OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Cta.(0: Todas):" OF oDlg1 PIXEL SIZE 60,12 RIGHT      
   @ 05, 70 GET oGet1 VAR vdesde PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR vhasta PICTURE "@D"  OF oDlg1 PIXEL 
   @ 35, 70 COMBOBOX oGet3 VAR nEstado  ITEMS aEstado SIZE 80,80 PIXEL
   @ 50, 75 GET oGet4 VAR nCuenta PICTURE "99999999" OF oDlg1 PIXEL RIGHT;
                  VALID(Buscar(oQry2,oDlg1,oGet4,oGet5));
                  ACTION (oGet4:cText:= 0, Buscar(oQry2,oDlg1,oGet4,oGet5)) BITMAP "BUSC1"
   @ 50,105 GET oGet5 VAR cCuenta PICTURE "@!"  OF oDlg1 PIXEL ;
      WHEN((oGet5:cText := IF(nCuenta=0,cTodos,oQry2:nombre)) = SPACE(30))
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " fecemi >=" + ClipValue2SQL(vdesde) +;
      + "  and fecemi <= " + ClipValue2SQL(vhasta) ;
      + "  and " + IF(nEstado = 1," TRUE ", " tipo =  " +ClipValue2Sql(aEst[nEstado]))+;
      + "  and " + IF(nCuenta = 0," TRUE ", " banco =  " +ClipValue2Sql(nCuenta))
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil