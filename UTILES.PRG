**ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ
#include "Fivewin.ch"
#include "tdolphin.ch"
#include "xbrowse.ch"

*ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ
*Û MANTENIMIENTOS DE ARCHIVOS           ÛÛ
*ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ

MEMVAR oApp
******************************
** Backup de archivos
FUNCTION Resguar()
LOCAL cTime := TIME()
oApp:oServer:bOnbackup = {| nStatus, cTable, nTotTable, nCurrTable | OnBackup( nStatus, cTable, nTotTable, nCurrTable  ) }
oApp:oServer:Backup( oApp:oServer:ListTables(), "Backup_"+DTOS(DATE())+".txt", .T., .T., 500, "Inicio del proceso de backup", "Final del proceso de Backup" )
MsgInfo("Terminado, Tiempo de bakcup:" + elaptime( cTime, time() ),"Fin backup")
RETURN nil

STATIC FUNCTION OnBackup( nStatus, cTable, nTotTable, nCurrTable  )

   SWITCH nStatus
      CASE ST_STARTBACKUP
         MsgWait("Inici del Backup ","Backup",0.1)
         EXIT 
      CASE ST_LOADINGTABLE
         MsgWait("Haciendo Backup de: " + cTable,"Backup",0.1)
         EXIT 
      CASE ST_ENDBACKUP
         MsgWait("Backup finalizado","Backup",0.1)
   ENDSWITCH 

RETURN nil

************************************************
** Acelerador2 de Teclas + - y Enter para la barra de tareas
FUNCTION Acelerador2(nKey, oBar, oBrw, cPermisos, nHasta)
IF nKey = 13
   IF "M"$cPermisos
      oBar:aControls[2]:Click()
      oBrw:GoLeftMost()
      oBrw:SetFocus()
  ENDIF
ENDIF

IF nkey = VK_F2
   oBar:aControls[1]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=1
   RETURN nil 
ENDIF
IF nKey = VK_F3 
   oBar:aControls[2]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=2
   RETURN nil 
ENDIF
IF nKey = VK_F4
   oBar:aControls[3]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=3
   RETURN nil 
ENDIF
IF nKey = VK_F5
   oBar:aControls[4]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=4
   RETURN nil 
ENDIF
IF nKey = VK_F6
   oBar:aControls[5]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=5
   RETURN nil 
ENDIF
IF nKey = VK_F7
   oBar:aControls[6]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=6
   RETURN nil 
ENDIF
IF nKey = VK_F8
   oBar:aControls[7]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=7
   RETURN nil 
ENDIF
IF nKey = VK_F9
   oBar:aControls[8]:Click()
   oBrw:SetFocus()
ENDIF
IF nHasta=8
   RETURN nil 
ENDIF

RETURN NIL


**************************************************************************************************************
**** Apertura de turno por fondo de caja 
FUNCTION ValidarTurno(oPadre)
LOCAL oQryAuxi:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"fondo WHERE checkeado = FALSE "+;
                 IF(oApp:unifica_cajas,"","AND caja = "+ClipValue2Sql(oApp:prefijo))),lPreg
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError, poriva,;
      lSuper:=.f.,oQry,lDevolver:=.t.
IF oQryAuxi:reccount() = 0
   lPreg:= MsgYesNo("No se puede ingresar sin haber abierto un turno ¿Desea hacer la apertura de caja en este momento?","Atencion!")
   IF lPreg 
       oQry := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"fondo LIMIT 1")
       base := oQry:GetBlankRow()
       base:fecha := DATE()
       base:caja:= oApp:prefijo
       base:usuario:= oApp:usuario

        DO WHILE .T.
        DEFINE DIALOG oForm TITLE "Alta de Fondo de caja";
               FROM 05,15 TO 15,55 OF oPadre
           
           @ 07, 05 SAY "Fecha:"        OF oForm PIXEL SIZE 35,20 RIGHT
           @ 22, 05 SAY "Importe:"      OF oForm PIXEL SIZE 35,20 RIGHT
           @ 37, 05 SAY "Caja:"         OF oForm PIXEL SIZE 35,20 RIGHT
          
           @ 05, 50 GET oGet[1] VAR base:fecha   PICTURE "@D"  OF oForm PIXEL CENTER 
           @ 20, 50 GET oGet[2] VAR base:importe PICTURE "99999999.99"    OF oForm PIXEL RIGHT;
                        VALID(base:importe>0)
           @ 35, 50 GET oGet[3] VAR base:caja    PICTURE "999" OF oForm PIXEL RIGHT WHEN(lSuper);
                        VALID(base:caja>0)
           
           acor := AcepCanc(oForm)
           @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
                   ACTION ((lRta := .t.), oForm:End() ) PIXEL
           @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
                   ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
        ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
        IF !lRta
           RETURN .f.
        ENDIF
        oQry:GetBlankRow()
        oQry:oRow := base
        TRY
          oApp:oServer:BeginTransaction()
          oQry:Save()
          oApp:oServer:CommitTransaction()
        CATCH oError
            ValidaError(oError)
          LOOP
        END TRY
        EXIT
        ENDDO
    ELSE
        lDevolver:=.f.
    ENDIF
ENDIF
RETURN lDevolver


********************************************
** Generar Certificados con Open-SSL
FUNCTION GeneraCert()
LOCAL oGet := ARRAY(10), oBot1, oBot2, oDlg1, oFont, mrta := .f., aCor, cFile1, cFile2, cComando,;
      cEmpresa := SPACE(20), cAlias := SPACE(10), cCuit := SPACE(13)
IF oApp:lDemo
   MsgStop("Los certificados digitales solo pueden ser generados con un programa registrado!","Error")
   RETURN nil
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5      
DEFINE DIALOG oDlg1 TITLE "Generacion de Certificados AFIP - Paso 1" FROM 03,20 TO 15,75 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg1)
   
   @ 05, 05 SAY "Este proceso te ayudar a crear los certificados digitales para factura electronica."+CHR(10)+;
                "El primer paso es generar la clave privada. "+CHR(10)+;
                "El sistema generara un archivo con nombre privadaBCN"+CHR(10)+;
                "IMPORTANTE: ESE ARCHIVO DEBERA GUARDARLO PARA FUTURO USO"+CHR(10)+;
                "Copielo en otra carpeta una vez generado para mayor seguridad."+CHR(10)+;
                "Da Aceptar para Gererarla" OF oDlg1 PIXEL SIZE 200,100 
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
IF !mrta
   RETURN .f.
ENDIF
cComando := ".\DRIVERSFC\openssl genrsa -out privadaBCN 2048"
WaitRun( cComando , 0 )
cFile1 := MemoRead("privadaBCN")
cFile1 := strtran( cFile1, chr(10), chr(10)+chr(13) )
DEFINE DIALOG oDlg1 TITLE "Generacion de Certificados AFIP - Paso 2" FROM 03,20 TO 35,85 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg1)
   
   @ 05, 05 SAY "Ahora podra ver el resultado de la clave privada generada." OF oDlg1 PIXEL SIZE 200,12
   @ 25, 05 GET oGet[1] VAR cFile1 OF oDlg1 PIXEL SIZE 250,80 MEMO READONLY
   @115, 05 SAY "Ahora debera generar con sus datos el archivo de pedido." OF oDlg1 PIXEL  SIZE 200,12
   @130, 05 SAY "Empresa:" OF oDlg1 PIXEL  SIZE 60,12
   @145, 05 SAY "Alias:"   OF oDlg1 PIXEL  SIZE 60,12
   @160, 05 SAY "C.U.I.T.:" OF oDlg1 PIXEL  SIZE 60,12
   @130, 75 GET oGet[2] VAR cEmpresa OF oDlg1 PIXEL 
   @145, 75 GET oGet[3] VAR cAlias OF oDlg1 PIXEL  
   @160, 75 GET oGet[4] VAR cCuit PICTURE "99-99999999-9" VALID(ValidaCuit(cCuit)) OF oDlg1 PIXEL

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN .f.
ENDIF
cComando := 'SET OPENSSL_CONF='+HB_CURDRIVE()+':\'+CURDIR()+'\DRIVERSFC\openssl.cfg'+chr(10)+chr(13)
cComando := cComando + '.\DRIVERSFC\openssl req -new -key privadaBCN -subj "/C=AR/O='+ALLTRIM(cEmpresa)+;
            '/CN='+ALLTRIM(cAlias)+'/serialNumber=CUIT '+STRTRAN(cCuit,'-','')+'" -out pedidoBCN'
memowrit( 'cert.bat', cComando )
WaitRun( 'cert.bat' , 0 )
cFile2 := MemoRead("pedidoBCN")
cFile2 := strtran( cFile2, chr(10), chr(10)+chr(13) )
DEFINE DIALOG oDlg1 TITLE "Resultado de la Generacion - Paso 3" FROM 03,20 TO 25,85 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg1)
   
   @ 05, 05 SAY "Ahora este archivo debera subirlo a AFIP " OF oDlg1 PIXEL SIZE 200,12
   @ 25, 05 GET oGet[1] VAR cFile2 OF oDlg1 PIXEL SIZE 250,80 MEMO READONLY
   @115, 05 SAY "Dicho archivo quedo generado como pedidoBCN" OF oDlg1 PIXEL  SIZE 200,12
   

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Finalizar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
RETURN nil

********************************************
*** Pide clave de autorizacion 
FUNCTION PedirClave(cTexto,oPadre)
LOCAL oGet1, oBot1, oBot2, oDlg1, oFont, mrta := .f., aCor,lRespuesta:=.f.,;
      oQryDat:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros"),cClave:=SPACE(15)

IF !oApp:usar_clave
   RETURN .t.
ENDIF

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5      
DEFINE DIALOG oDlg1 TITLE "Ingresar clave de autorizacion" FROM 03,20 TO 11,75 OF oPadre FONT oFont
   acor := AcepCanc(oDlg1)
   
   @ 05, 05 SAY cTexto OF oDlg1 PIXEL CENTER SIZE 200,20 
   @ 27, 05 SAY "Clave:" OF oDlg1 PIXEL RIGHT SIZE 85,10
   
   @ 25, 95 GET oGet1 VAR cClave OF oDlg1 PICTURE "@!" PIXEL PASSWORD

   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mrta
   RETURN .f.
ENDIF

IF cClave = oQryDat:claveadm
   lRespuesta:= .t.
ELSE 
   MsgStop("Clave incorrecta")
   lRespuesta:= .f.
ENDIF

RETURN lRespuesta

********************************
** Funcion que valida el cuit
FUNCTION ValidaCuit(num,lMensaje)
LOCAL amulti, dig, divi,valor,i,retorno
DEFAULT lMensaje := .T.
amulti := {5,4,3,2,7,6,5,4,3,2}
num = STRTRAN(num,"-","")
IF num = SPACE(11)
   RETURN .t.
ENDIF
valor = 0
FOR i = 1 TO 10
    valor = valor + VAL(SUBSTR(num,i,1)) * amulti[i]
NEXT
divi = valor % 11
IF divi = 0
   dig = 0
   ELSE
   dig = 11 - divi
ENDIF
IF STR(dig,1) <> RIGHT(num,1)
   IF lMensaje
      MsgAlert("C.U.I.T. Invalido")
   ENDIF
   retorno = .f.
   ELSE
   retorno = .t.   
ENDIF
RETURN retorno

FUNCTION FechaSql(cDate)
IF VALTYPE(cDate ) = "D"
   RETURN cDate
   ELSE
   IF VALTYPE(cDate ) <> "C"
      RETURN CTOD("  /  /    ")
   ENDIF
ENDIF
RETURN CTOD(RIGHT(cDate,2)+"/"+SUBSTR(cDate,6,2)+"/"+LEFT(cDate,4))


********************************
** Funcion que valida el cbu
FUNCTION validacbu(num)
LOCAL amulti1, amulti2, dig, divi, valor, i, retorno := .f.
amulti1 := {7,1,3,9,7,1,3}
amulti2 := {0,0,0,0,0,0,0,0,3,9,7,1,3,9,7,1,3,9,7,1,3}
IF EMPTY(num)
   RETURN .t.
ENDIF
   valor = 0
   FOR i = 1 TO 7
       valor := valor + VAL(SUBSTR(num,i,1)) * amulti1[i]
   NEXT
   dig = 10 - (valor % 10)
   dig = if(dig=10,0,dig)
   IF dig = VAL(SUBSTR(num,8,1))
      retorno := .t.
      ELSE
      MsgAlert("C.B.U. Bloque 1 Invalido")
      RETURN .f.
   ENDIF

   valor = 0
   FOR i = 9 TO 21
       valor := valor + VAL(SUBSTR(num,i,1)) * amulti2[i]
   NEXT
   dig = 10 - (valor % 10)
   dig = if(dig=10,0,dig)
   IF dig = VAL(SUBSTR(num,22,1))
      retorno := .t.
      ELSE
      MsgAlert("C.B.U. Bloque 2 Invalido")      
   ENDIF

RETURN retorno

**************************
** Crear temporarios
FUNCTION crear_temp(atabla)
LOCAL mnom_arc,i
mnom_arc = "TEMPOR"
i = 0
DO WHILE FILE(mnom_arc+".DBF")
   mnom_arc = LEFT(mnom_arc,6) + STRTRAN(STR(i,2)," ","0")
   i++
ENDDO
DBCREATE(mnom_arc,atabla)
RETURN mnom_arc


******************************************************************************
// Funcion   : Incrusta
// Proposito : Poner justo justo un dialogo en una ventana
// Parametros: oWnd: Ventana donde se quiere poner el dialogo
//             oDlg: Dialogo que se quiere inscrustar
//             lCentra: Si lo quiere centrado o no
FUNCTION Incrusta( oWnd, oDlg, lCentra)

  STATIC lActivo := .F.
  LOCAL  aRect, nPosY, nPosX, nPosXX, oIco
  DEFINE ICON oIco RESOURCE "socie"
**  DEFAULT lCentra := .F.
  IF IsIconic(oWnd:hWnd)
     RETURN .T.
  ENDIF

  IF !(lActivo)
     lActivo = .T.

     // Muevo dialogo a 0,0 para que quede bien incrustado...
     oDlg:Move(0,0)

     // Primero Seteo Como si Windows Fuera Estandar...
     oWnd:SetSize(oDlg:nWidth+8, oDlg:nHeight+27)

     // Calculo diferencia !
     aRect  := GetClientRect(oWnd:hWnd)
     nPosY := ABS(ABS(aRect[3]-aRect[1])-ABS(oWnd:nTop-oWnd:nBottom))
     nPosX := ABS(ABS(aRect[4]-aRect[2])-ABS(oWnd:nRight-oWnd:nLeft))
     nPosXX := INT(ABS(ABS(oWnd:nRight-oWnd:nLeft) - ;
               ABS(oApp:oWnd:nRight-oApp:oWnd:nLeft)) / 2)
     // Ahora la pongo JUSTA, JUSTA...
     oWnd:SetSize(oDlg:nWidth+nPosX,oDlg:nHeight+nPosY)           
     oWnd:Move(oApp:oWnd:nTop+5,nPosXX)
     lActivo := .F.
     oWnd:SetIcon(oIco)
     oWnd:Refresh()
     oApp:oWnd:oWndClient:Refresh()
  ENDIF

RETURN .T.

******************************************************************************
// Funcion   : Bus
// Proposito : Hacer una busqueda incremental en un archivo ordenado
// Parametros: base: Tabla donde se va a buscar
//             oGet: Arreglo de get que contiene la variables para buscar
//             oLbx: Objeto ListBox donde se muestra el browse
FUNCTION Bus(base, oGet, oLbx)
// Hace la busqueda segun el contenido del get
IF ALLTRIM(oGet:cText) + " " = " "
   oLbx:Gotop()
   ELSE
   base:Find({oGet:cText},{"APELLIDO"})
// Se refresca el listbox
ENDIF

oLbx:refresh()
RETURN .T.

*******************************************************************************
** Poner un cuadro para los bonotes de aceptar y cancelar del formulario
** y devolver un arreglo con las coordenadas donde porner los botones
FUNCTION AcepCanc(oDlg)
LOCAL acor,arr := ARRAY(4), oGru
acor := GetDialogBaseUnits()
** Pongo el cuadro abajo del dialogo
*@ oDlg:nHeight/ acor[2] - 20,01 BOX TO;
*  oDlg:nHeight/acor[2] -1,oDlg:nWidth/acor[1]-1 PIXEL
oDlg:lHelpIcon := .f.
arr[1] := oDlg:nHeight/ acor[2] - 15
arr[2] := INT(oDlg:nWidth/acor[1]/2/2 -20)
arr[3] := oDlg:nHeight/ acor[2] - 15
arr[4] := INT(oDlg:nWidth/acor[1]/2/2*3 -20)
@ oDlg:nHeight/ acor[2] - 22,01 GROUP oGru TO;
  oDlg:nHeight/acor[2] -1,oDlg:nWidth/acor[1]-1 PIXEL
RETURN arr

*******************************************************************************
** Acelerador de Teclas + - y Enter para la barra de tareas
FUNCTION Acelerador(nKey, oBar)
IF nkey = 107
   oBar:aControls[1]:Click()
ENDIF
IF nKey = 109
   oBar:aControls[2]:Click()
ENDIF
IF nKey = 13
   oBar:aControls[3]:Click()
ENDIF
RETURN NIL

FUNCTION DbZap()
ZAP
RETURN .T.

FUNCTION DbPack()
PACK
RETURN .T.
 
***************************************************************************
** Pinta los browse
FUNCTION PintaBrw(oBrw,C)
LOCAL i,nColTam,nFaltante 
     oBrw:bClrStd := { || If( oBrw:KeyNo() % 2 == 0, ;
                         { CLR_BLACK, RGB(193,221,255)}, ;
                         { CLR_BLACK, RGB(221,245,255)} ) }
     oBrw:bClrSel := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }
     oBrw:lColDividerComplete  := .t.                    
     oBrw:nColDividerStyle     := LINESTYLE_INSET
     oBrw:nRowDividerStyle     := LINESTYLE_INSET
     oBrw:bClrSelFocus  := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }  // para barra de linea selecc cuando el control tiene el foco
     oBrw:nMarqueeStyle    := MARQSTYLE_HIGHLCELL  //solo ilumina la celda actual
     **************************************AJUSTAR COLUMNAS********************************
     IF C> 0 
      nColTam:=0
      FOR i := 1 TO C
       nColTam:= (nColTam + oBrw:aCols[ i ]:nWidth)
      NEXT
      IF nColTam < 761
         nFaltante:= 761 - nColTam - 1.5
         oBrw:aCols[ C ]:nWidth:= (oBrw:aCols[ C ]:nWidth + nFaltante)
      ENDIF   
     ENDIF
     
    
    

RETURN nil 



FUNCTION ValidaError(oError)
LOCAL oQryError, cText
oApp:oServer:RollBack()
IF oError <> nil
  cText :=  oError:description
  oQryError:= oApp:oServer:Query( "SELECT * FROM errores WHERE codigo = " + ClipValue2Sql(oError:SubCode))
  IF oQryError:nRecCount > 0
     IF  !EMPTY(oQryError:descripcion)
      MsgStop(oQryError:descripcion,"Error")
     ELSE
      MsgStop("Error Base de datos"+CHR(10)+oError:description,"Error")
     ENDIF
  ELSE
     oApp:oServer:Execute("INSERT INTO errores (codigo,description,descripcion) VALUES ("+;
                          ClipValue2Sql(oError:SubCode)+",'"+STRTRAN(ClipValue2Sql(oError:description),"'"," ")+"',' ')")
     MsgStop("Error base de datos"+CHR(10)+oError:description,"Error")
  ENDIF
ELSE 
  MsgStop("Error desconocido","Error")
  cText := "Desconocido"
ENDIF
oApp:oServer:Execute("INSERT INTO errores_audit (fecha,descripcion,proceso) VALUES ("+;
                        ClipValue2Sql(date())+",'"+STRTRAN(ClipValue2Sql(cText),"'"," ")+;
                        "','"+ProcName( 2 )+" Linea "+STR(ProcLine( 2 ))+"')")
RETURN nil

********************************************************************************
** Importar Padrones de ARBA
PROCEDURE Importar()
LOCAL march, march1, mcuit, oQry
use padron index padron new
march  := SPACE(25)
march1 := SPACE(25)
march := cGetFile("*.TXT","Importar archivo de Percepciones")
march1 := cGetFile("*.TXT","Importar archivo de Retenciones")
march := alltrim(march)
march1 := alltrim(march1)
IF !FILE(march)
   MsgStop("No encontrado el archivo 1")
   CLOSE padron
   RETURN
endif
IF !EMPTY(march)
   padron->(dbzap())
   APPEND FROM (march) SDF
ENDIF
IF !EMPTY(march1)
   APPEND FROM (march1) SDF
ENDIF
oQry := oApp:oServer:Query("SELECT codigo,cuit FROM ge_"+oApp:cId+"clientes")
do while !oQry:eof()
   mcuit := STRTRAN(oQry:cuit,"-","")
   IF padron->(DBSEEK("P"+mcuit))      
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET percep = " + ClipValue2Sql(padron->percep) + " WHERE codigo = " + ClipValue2Sql(oQry:codigo))
      *replace clientes->percep with VAL(STRTRAN(padron->percep,",","."))
      else
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET percep = 0 WHERE codigo = " + ClipValue2Sql(oQry:codigo))
      *replace clientes->percep with 0
   ENDIF
   oQry:SKIP()   
ENDDO
oQry:End()
oQry := oApp:oServer:Query("SELECT codigo,cuit FROM ge_"+oApp:cId+"clientes")
do while !oQry:eof()
   mcuit := STRTRAN(oQry:cuit,"-","")
   IF padron->(DBSEEK("R"+mcuit))      
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"provee SET reten = " + ClipValue2Sql(padron->percep) + " WHERE codigo = " + ClipValue2Sql(oQry:codigo))
      *replace clientes->percep with VAL(STRTRAN(padron->percep,",","."))
      else
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"provee SET reten = 0 WHERE codigo = " + ClipValue2Sql(oQry:codigo))
      *replace clientes->percep with 0
   ENDIF
   oQry:SKIP() 
ENDDO
oQry:End()
close padron
MsgInfo("PROCESO TERMINADO")
RETURN

FUNCTION Procesando(lAction)
LOCAL oImg
IF !lAction 
   IF oApp:oDlgP <> nil
      oApp:oDlgP:End()  
   ENDIF   
   CursorArrow()
   RETURN nil
   ELSE   
   CursorWait()   
   DEFINE DIALOG oApp:oDlgP   FROM 0,0 TO 5, 33 STYLE nOr( DS_MODALFRAME, WS_POPUP ) 
   oApp:oDlgP:lHelpIcon := .f.     
   @ 5, 5 IMAGE oImg FILE ".\cargando.png" OF oApp:oDlgP SIZE 120, 29 ADJUST PIXEL NOBORDER   
   ACTIVATE DIALOG oApp:oDlgP NOWAIT CENTERED   
   SysRefresh()
ENDIF
RETURN nil


function DlgOnTop( lState, hWnd )

   local nRet := 0

   DEFAULT hWnd := GetActiveWindow()

   if !lState
      nRet = AcpOnTop( hWnd, -2, 0, 0, 0, 0, 3 )
   else
      nRet = AcpOnTop( hWnd, -1, 0, 0, 0, 0, 3 )
   endif

return nRet


*******************************************************
** Pasar numero a letras
FUNCTION LETRA ( NUM )
LOCAL niv, cad, i, letra, lon, nivel, nums, let,  cer, numero
 NIV:= {[MIL], [MILLON], [BILLON], [TRILLON] };   LET:= Space(40)
 CAD := Alltrim( Str(INT(NUM)) );CER := IF (Len(CAD)%3 < 3 .AND. Len(CAD)%3 <> 0, 3-(Len(CAD)%3), 0)
 CAD := Replicate ( '0', CER ) + CAD;LON := Len(CAD)
 LETRA:=''
 FOR I:=1 TO Int(Len(CAD)/3)
     numero:= Val( SubStr(CAD, LON-2, 3) ); NIVEL:=''
     NUMLET ( numero, @LET ) 
     LET   := IF (I>1, IF (numero=1, Left(LET,2), LET), LET)
      LON   := LON - 3
      IF I < Int(Len(CAD)/3)
          NIVEL := NIV[I] 
          IF I>1
             nums:= Val ( SubStr(CAD, LON-2, 3) )
             NIVEL:= NIVEL + IF(nums>1, 'ES', '')
          ENDIF
      ENDIF   
     LETRA:=  NIVEL + ' ' +  LET  +  ' '+LETRA
 NEXT
 LETRA:= Alltrim(LETRA) + ' CON ' + Strzero( (NUM-INT(NUM))*100, 2 ) + '/100 '
RETURN LETRA

PROCEDURE NUMLET ( num, let )
LOCAL numc, nomd, nomu, nomc, c, d, u, x, cen, to, dec, uni
 numc:= nomd:= nomu:= ''
 C:= {[CIEN], [DOSCIENTOS], [TRESCIENTOS], [CUATROCIENTOS], [QUINIENTOS], [SEISCIENTOS], [SETECIENTOS], [OCHOCIENTOS], [NOVECIENTOS]}
 D:= {[DIEZ], [VEINTE]    , [TREINTA]    , [CUARENTA]     , [CINCUENTA] , [SESENTA]    , [SETENTA]    , [OCHENTA]    , [NOVENTA]}       
 U:= {[UNO] , [DOS]       , [TRES]       , [CUATRO]       , [CINCO]     , [SEIS]       , [SIETE]      , [OCHO]       , [NUEVE]}
 X:= {[ONCE], [DOCE]      , [TRECE]      , [CATORCE]      , [QUINCE]    , [DIECISEIS]  , [DIECISIETE] , [DIECIOCHO]  , [DIECINUEVE]}
 cen := INT (num/100);    dec := INT ((num%100)/10);  uni := ( (num%100) % 10 )
 TO  := IF (cen=1, IF (dec>0 .OR. uni>0, 'TO', '') , '')  
 nomc := IF(cen>0, C[cen] + TO + [ ] ,'')                 
 IF dec=1 .AND. uni>=1                                   
    nomu := IF(uni>0, X[uni], '' )                         
 ELSE                                                     
    nomd := IF(dec>0, D[dec] ,'')                          
     IF dec=2 .AND. uni>0                                  
        nomd:= Left(nomd,5) + 'I'
     ELSEIF dec>=3  .AND. uni>0
        nomd:= nomd + ' Y '
     ENDIF
    nomu := IF(uni>0, U[uni]+[ ] ,'')
 ENDIF
 let := nomc + nomd + nomu ;let := Alltrim( let )
RETURN
//----------------------------------------------------------------------------//

dll32 static function AcpOnTop( hWnd AS LONG, hWndInsertAfter AS LONG, x AS LONG, y AS LONG, cx AS LONG, cy AS LONG, wFlags AS LONG ) ;
      AS LONG PASCAL  FROM "SetWindowPos" LIB "User32.dll"


/////////// QR
FUNCTION GeneraQr(oQry)

Local cOrigen, cJason, cDestino, ElTxt, xdia,xtip, xdni

Local cCuitEmite:= ALLTRIM(STRTRAN(oApp:cuit_emp,'-',''))
Local cFechaEmit,cXIMP, Nhandle

xDIA=DToC(oQry:fecha)
cFechaEmit:=subst(xDIA,7,4)+'-'+subst(xDIA,4,2)+'-'+subst(xDIA,1,2)
cXIMP=AllTrim(Str(oQry:importe))
cXIMP=subst(cXIMP,1,Len(cXIMP)-3)
IF oQry:cuit = " " .or. oQry:cuit = '-        - ' .or. oQry:cuit = '  -        - '
   xtip = '96'
   xdni = STR(oQry:dni)
   ELSE 
   xtip = '80'
   xdni = oQry:cuit
ENDIF   
xdni = STRTRAN(xdni,' ','')
xdni = STRTRAN(xdni,'-','')
xdni = if(xdni = "0","1000000",xdni)

cOrigen:="https://www.afip.gob.ar/fe/qr/?p="
cJason:='{"ver":1,"fecha":"'+cFechaEmit+'","cuit":'+ cCuitEmite +',"ptoVta":'+ALLTRIM(STR(VAL(left(oQry:numcomp,4))))+;
          ',"tipoCmp":'+AllTrim(STR(VAL(oQry:tipfor)))+',"nroCmp":'+ALLTRIM(STR(VAL(RIGHT(oQry:numcomp,8))))+;
          ',"importe":'+cXIMP+',"moneda":"PES","ctz":1,"tipoDocRec":'+xtip+',"nroDocRec":'+AllTrim(XDNI)+',"tipoCodAut":"E","codAut":'+alltrim(oQry:cae)+'}'
cJason=StrToBase64( cJason )
cOrigen=cOrigen+cJason

/*ElTxt:= "QrJason.txt"
Nhandle:= fcreate(ElTxt)
If (nhandle > 0)
   fwrite(Nhandle, cOrigen + CRLF)
   fclose(nhandle)
EndIf*/

cDestino:="FactQR.bmp"

QRCode(cOrigen,cDestino)


Return nil

//----------------------------------------------------------------------------//
///en fivewin

//FastQRCode("https://github.com/VFPX/FoxBarcodeQR", "C:\Mis imagenes\FastQR.bmp")

DLL32 STATIC FUNCTION QRCode(cStr As STRING, cFile As STRING) AS LONG PASCAL ;
FROM "FastQRCode" LIB "QRCodelib.Dll"
RETURN NIL

//
FUNCTION StrToBase64( cTexte )
  //******************
// Conversion en base 64 de la chaine cTexte
// Un alphabet de 65 caractères est utilisé pour permettre la représentation de 6 bits par caractère :
// "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
// Le '=' (65e caractère) est utilisé dans le processus de codage pour les caractères finaux.
   LOCAL cTexte64 := ""
   LOCAL X
   LOCAL cHex
   DO WHILE !( cTexte == "" )
      cHex := ""
      // Le processus de codage représente des groupes de 24 bits de données en entrée par une chaîne en sortie de 4 caractères codés.
      // En procédant de gauche à droite, un groupe de 24 bits est créé en concaténant 3 octets (8 bits par octet).
      FOR X := 1 TO 3
         // Conversion de chaque caractère en chaine binaire de 8 octets
         cHex += CarToBin( LEFT( cTexte, 1 ) )
         IF LEN( cTexte ) > 1
            cTexte := SUBSTR( cTexte, 2 )
         ELSE
            cTexte := ""
            EXIT
         ENDIF
      NEXT X
      // Ces 24 bits (ici contenus dans cHex, ou au moins un multiple) sont traités comme 4 groupes concaténés de 6 bits chacun convertis
      // en un unique caractère dans l'alphabet de la base 64.
      // Chaque groupe de 6 bits est utilisé comme index dans la table des caractères de la base 64.
      // Le caractère référencé par l'index correspondant est utilisé comme codage de ce groupe de 6 bits.
      FOR X := 1 TO 4
         IF SUBSTR( cHex, ( (X - 1 ) * 6 ) + 1 ) == ""
            cTexte64 += REPLICATE( "=", 4 - X + 1 )
            EXIT
         ELSE
            // Un traitement spécial est effectué si moins de 24 bits sont disponibles à la fin des données
            // à coder. Aucun bit ne restant non-codé,
            // si moins de 24 bits sont disponibles alors des bits à zéro sont ajoutés à la droite des données
            // pour former un nombre entier de groupes de 6 bits.
            IF LEN( cHex ) % 6 > 0
               // Ajout des bits à zéro
               cHex += REPLICATE( "0", 6 - ( LEN( cHex ) % 6 ) )
            ENDIF
            cTexte64 += Carac64( "00" + SUBSTR( cHex, ( (X - 1 ) * 6 ) + 1, 6 ) )
         ENDIF
      NEXT X
   ENDDO
RETURN cTexte64


FUNCTION Carac64( cBin )
  //***************
// Renvoie le caractère correspondant en base 64
   LOCAL nPos := ASC( BinToCar( @cBin ) ) + 1
RETURN SUBSTR( "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", nPos, 1 )
FUNCTION Hex64( carac64 )
  //*************
// Renvoie le caractère correspondant en base 64
   LOCAL cCodeAsc := CHR( AT( carac64, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" ) - 1 )
RETURN SUBSTR( CarToBin( @cCodeAsc ) , 3, 6 )

FUNCTION CarToBin( carac, lInverse )
  //****************
// Renvoie le caractère correspondant dans une chaine binaire (composée de 0 et 1) de 8 bits
#define cHexa "0123456789ABCDEF"
#define aBin {"0000", "0001", "0010", "0011", "0100", "0101", "0110", "0111", "1000", "1001", "1010", "1011", "1100", "1101", "1110", "1111" }
   LOCAL cToHex
   IF EMPTY( lInverse )
      // Retourne la chaine binaire en ayant reçu le caractère ASCII
      cToHex := str2Hex( carac )
      RETURN aBin[ AT( LEFT(cToHex,1), cHexa ) ] + aBin[ AT( SUBSTR(cToHex,2), cHexa ) ]
   ELSE
      // Retourne le caractère ASCII en ayant reçu la chaine binaire
      cToHex := SUBSTR( cHexa, ASCAN( aBin, LEFT(carac,4 ) ), 1 ) + SUBSTR( cHexa, ASCAN( aBin, SUBSTR(carac,5,4 ) ), 1 )
      RETURN Hex2str( cToHex )
   ENDIF
RETURN NIL

FUNCTION BinToCar( cBin )
  //****************
RETURN CarToBin( @cBin, .T. )



FUNCTION SiNoCancelar(cTitle, cText, aBot)
LOCAL oDlgF, oBot := array(3), lRta := .f. , lCanc := .F.
DEFAULT aBot := {"Si","No","Cancelar"}
DEFINE DIALOG oDlgF TITLE cTitle FROM 05,15 TO 16,65
oDlgF:lHelpIcon := .f.
@ 05,05 SAY cText  OF oDlgF PIXEL SIZE 190,40 CENTER
@ 50,10 BUTTON oBot[1] PROMPT "&"+aBot[1] OF oDlgF SIZE 50,12 ;
       ACTION ((lRta := .t.), oDlgF:End() ) PIXEL
@ 50,70 BUTTON oBot[2] PROMPT "&"+aBot[2] OF oDlgF SIZE 50,12 ;
       ACTION ((lRta := .f.), oDlgF:End() ) PIXEL  
@ 50,130 BUTTON oBot[2] PROMPT "&"+aBot[3] OF oDlgF SIZE 50,12 ;
       ACTION ((lCanc := .T.), oDlgF:End() ) PIXEL     
ACTIVATE DIALOG oDlgF CENTER 
IF lCanc 
   RETURN nil 
ENDIF 
RETURN lRta   

/// Funcion que arma consulta de columnas variables
function ColsVariables(oCn, cTable, cRowFld, cColFld, cValFld, cAggrFunc ,cCampos, lExcluyeRow, cOrden)

   local cSql, cCol, lUseCase, cRdbms, n, oQry , cPunta, cAs
   default cCampos := '', cAggrFunc := 'SUM', lExcluyeRow := .f., cOrden := ""
   if ( n := At( " AS ", cTable ) ) > 0
      cPunta := ""
      cAs := right( cTable, n+4 )
      ELSE 
      cPunta := " DST"
      cAs    := "DST"
   endif
   oQry     := oCn:Query("SELECT DISTINCT " + cColFld + " as col FROM " + cTable + cPunta)
   if at('.', cRowFld) = 0
      if ( n := At( " AS ", cRowFld ) ) > 0 
         cRowFld     := Left( cRowFld, n + 3 ) + ;
                        FW_QuotedColSQL( AllTrim( SubStr( cRowFld, n + 4 ) ) )
      else
         cRowFld     := FW_QuotedColSQL( cRowFld )
      endif
   endif

   if ( n := At( " AS ", cColFld ) ) > 0
      cColFld  := Trim( Left( cColFld, n - 1 ) )
   endif

   cSql  := "SELECT "+IF(!EMPTY(cCampos),cCampos,'')+if(lExcluyeRow,'',',' + cRowFld)
   do while !oQry:Eof()
      cSql  += ", " + cAggrFunc + "( CASE WHEN " + cColFld + " = " + ClipValue2Sql( oQry:col ) + " THEN " + cValFld + " ELSE 0 END ) AS " + ;
            If( ValType( oQry:col ) == 'C', FW_QuotedColSQL( sacanovalidos(oQry:col) ), CharRem( "-/.", "COL_" + cValToChar( oQry:col ) ) )
      oQry:Skip()
   enddo

   cSql += " FROM " + cTable + if(empty(cPunta),"", " PVTTBL ") +" GROUP BY " + ;
      If( ( n := At( " AS ", Upper( cRowFld ) ) ) > 0, Left( cRowFld, n - 1 ), cRowFld ) + " ORDER BY "+cOrden

return oCn:Query(cSql)

STATIC FUNCTION sacanovalidos(c)
c := STRTRAN(c,","," ")
c := STRTRAN(c,"'"," ")
RETURN c


**********************************************************
** Consulta cuit
FUNCTION ConsultaCuit(nCuit,oGet,aRef,lCambiar)
LOCAL Contribuyente, lwsPadron, oError, lRta, aRespuesta := hash()  
IF nCuit = 0
   RETURN .t.
ENDIF   
TRY 
    lwsPadron := CreateObject("FEAFIPLib.wsPadron")
    IF oApp:lDemo
        lwsPadron:CUIT := 20214424666
    ELSE
        lwsPadron:CUIT := VAL(STRTRAN(oApp:cuit_emp,"-",""))
    ENDIF
CATCH oError 
    MsgInfo( "No esta el Driver fiscal registrado..."+chr(10)+;
             "Para poder consultar datos impositivos"+chr(10)+;
             "debe tener instalado el driver fiscal."+chr(10)+;
             "Ejecute el programa REGISTRA.BAT que"+chr(10)+;
             "Esta en la carpeta DRIVERFC dentro de"+chr(10)+;
             "la carpeta donde instalo el sistema."+chr(10)+;
             "Hagalo con permisos de administrador";
             ,"Error" ) 
    RETURN .f.
END TRY 

TRY 
  lwsPadron:ModoProduccion := !oApp:lDemo
  lRta := lwsPadron:login("MiCertificado.crt", "MiClavePrivada")
CATCH oError
  MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oError:description+chr(10);
             ,"CONECTANDO CON WEB SERVICE" ) 
  RETURN .t.
END TRY
IF !lRta 
   MsgInfo( "No pudo conectar con el AFIP"+CHR(10)+;
            "Para esta funcionalidad debe tener"+CHR(10)+;
            "habilitado la opcion de Consulta"+CHR(10)+;
            "de cuits autorizados electrónicamente"+chr(10)+;
            "Error:"+lwsPadron:ErrorDesc,"CONECTANDO CON WEB SERVICE" ) 
   RETURN .t.
ENDIF   

    Contribuyente := CreateObject("FEAFIPLib.Contribuyente")
   
    IF lwsPadron:consultar(nCuit, Contribuyente)     
        oGet[aRef[1]]:cText :=  ALLTRIM(Contribuyente:nombre)
        oGet[aRef[2]]:cText := Contribuyente:domiciliofiscal:direccion
        oGet[aRef[3]]:cText := ALLTRIM(Contribuyente:domiciliofiscal:localidad)+" "+ALLTRIM(Contribuyente:domiciliofiscal:provincia)
        oGet[aRef[4]]:cText := SUBSTR(str(nCuit,11),1,2)+"-"+SUBSTR(str(nCuit,11),3,8)+"-"+RIGHT(str(nCuit,11),1)
        oGet[aRef[5]]:Set(Contribuyente:condicionIva)
        IF Contribuyente:estadoClave <> 'ACTIVO'
           MsgInfo("Esta CUIT esta "+Contribuyente:estadoClave,"Atencion")
        ENDIF   
    ELSE
        MessageBox(0, lwsPadron:ErrorDesc+chr(10))        
    ENDIF
    lCambiar:= .f.
return .T.


**********************************************************
** Consulta cuit
FUNCTION ConsultaCuitRapida(nCuit,nCondi)
LOCAL Contribuyente, lwsPadron, oError, lRta, oFont, aRespuesta := hash()  ,;
      atipoiva  := {;
"1 IVA Responsable Inscripto",;
"2 IVA Responsable no Inscripto",;
"3 IVA no Responsable",;
"4 IVA Sujeto Exento",;
"5 Consumidor Final",;
"6 Responsable Monotributo",;
"7 Sujeto no Categorizado",;
"8 Proveedor del Exterior",;
"9 Cliente del Exterior",;
"10  IVA Liberado – Ley Nº 19.640",;
"11  IVA Responsable Inscripto – Agente de Percepción",;
"12  Pequeño Contribuyente Eventual",;
"13  Monotributista Social",;
"14  Pequeño Contribuyente Eventual Social",;
"15  IVA NO Alcanzado"}  
IF nCuit = 0
   RETURN .t.
ENDIF   
TRY 
    lwsPadron := CreateObject("FEAFIPLib.wsPadron")
    IF oApp:lDemo
        lwsPadron:CUIT := 20214424666
    ELSE
        lwsPadron:CUIT := VAL(STRTRAN(oApp:cuit_emp,"-",""))
    ENDIF
CATCH oError 
    MsgInfo( "No esta el Driver fiscal registrado..."+chr(10)+;
             "Para poder consultar datos impositivos"+chr(10)+;
             "debe tener instalado el driver fiscal."+chr(10)+;
             "Ejecute el programa REGISTRA.BAT que"+chr(10)+;
             "Esta en la carpeta DRIVERFC dentro de"+chr(10)+;
             "la carpeta donde instalo el sistema."+chr(10)+;
             "Hagalo con permisos de administrador";
             ,"Error" ) 
    RETURN .t.
END TRY 

TRY 
  lwsPadron:ModoProduccion := !oApp:lDemo
  lRta := lwsPadron:login("MiCertificado.crt", "MiClavePrivada")
CATCH oError
  MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oError:description+chr(10);
             ,"CONECTANDO CON WEB SERVICE" ) 
  RETURN .t.
END TRY
IF !lRta 
   MsgInfo( "Para mayor seguridad "+CHR(10)+;
            "habilite la opcion de Consulta"+CHR(10)+;
            "de cuits autorizados electrónicamente"+CHR(10)+;
            "con su clave fiscal","Aviso!" ) 
   RETURN .t.
ENDIF   

    Contribuyente := CreateObject("FEAFIPLib.Contribuyente")
   
    IF lwsPadron:consultar(nCuit, Contribuyente)        
        IF Contribuyente:condicionIva <> nCondi
           MsgStop("La condicion frente al IVA no coincide"+CHR(10)+;
                   "Condicion en AFIP:"+atipoiva[Contribuyente:condicionIva]+CHR(10)+;
                   "Condicion en Sistema:"+atipoiva[nCondi]+CHR(10);
                   ,"Atencion")   
           lRta := MsgNoYes("La CUIT  a la que quiere facturar"+chr(10)+;
                            "presenta insconsistencias en los padrones de AFIP"+chr(10)+;
                            "Desea factura igual BAJO SU ABSOLUTA RESPONSABILIDAD???","ATENCION!!!")

           RETURN lRta
        ENDIF   
        IF Contribuyente:estadoClave <> 'ACTIVO'
           MsgStop("Esta CUIT esta "+Contribuyente:estadoClave,"Atencion")
           lRta := MsgNoYes("La CUIT  a la que quiere facturar"+chr(10)+;
                            "presenta insconsistencias en los padrones de AFIP"+chr(10)+;
                            "Desea factura igual BAJO SU ABSOLUTA RESPONSABILIDAD???","ATENCION!!!")

           RETURN lRta
        ENDIF   
    ELSE
        MsgStop("No Existe esa CUIT en los padrones de AFIP","Atencion")
        lRta := MsgNoYes("La CUIT  a la que quiere facturar"+chr(10)+;
                         "presenta insconsistencias en los padrones de AFIP"+chr(10)+;
                         "Desea factura igual BAJO SU ABSOLUTA RESPONSABILIDAD???","ATENCION!!!")

        RETURN lRta
    ENDIF
return .T.

**********************************************************
** Consulta cuit
FUNCTION ConsultaVencimiento(dFechaVto,lMuestra)
LOCAL Certificado, oError, lRta, oResult, dFecVto 
DEFAULT lMuestra := .f.
dFechaVto := CTOD("  /  /    ")   
TRY 
    Certificado := CreateObject("FEAFIPLib.Certificado")
CATCH oError 
    RETURN .f.
END TRY 

TRY 
  IF Certificado:CargarInformacionCertificado("MiCertificado.crt", "MiClavePrivada")
      dFecVto := CTOD(LEFT(Certificado:ic_fechavencimiento,10))
      dFechaVto := dFecVto
          IF dFecVto < DATE()
            IF lMuestra
              MsgInfo("ATENCION!!!"+CHR(10)+"Certificado de AFIP vencido"+CHR(10)+;
              "Alias del Certificado:"+Certificado:ic_nombrecomun+chr(10)+;
              "Fecha Vto:"+ClipValue2Sql(Certificado:ic_fechavencimiento)+chr(10)+;
              "CUIT:"+STR(Certificado:ic_CUIT,11),"ATENCION!!!")         
            ENDIF  
            ELSE 
            IF dFecVto < DATE()+10      
               IF lMuestra
                  MsgInfo("ATENCION!!!"+CHR(10)+"Certificado de AFIP proximo a vencer"+CHR(10)+;
                    "Alias del Certificado:"+Certificado:ic_nombrecomun+chr(10)+;
                    "Fecha Vto:"+ClipValue2Sql(Certificado:ic_fechavencimiento)+chr(10)+;
                    "CUIT:"+STR(Certificado:ic_CUIT,11),"ATENCION!!!") 
               ENDIF
            ENDIF   
          ENDIF    
  ENDIF 
CATCH oError  
  RETURN .t.
END TRY
return .T.

****************************************************
** Mostrar error con Get 
FUNCTION MsgGet1(cTitle,cText,cGet)
LOCAL oDlgF, oBot := array(3), lRta := .f. , lCanc := .F.
DEFAULT cTitle := "Error", cText := "Dato", cGet := " "
DEFINE DIALOG oDlgF TITLE cTitle FROM 05,15 TO 17,65 FONT oApp:oFont
oDlgF:lHelpIcon := .f.
@ 02,75 XIMAGE oBot[3] NAME "ICONO1" SIZE 46,17 OF oDlgF NOBORDER
@ 20,05 SAY cText  OF oDlgF PIXEL SIZE 190,40 CENTER
@ 62,05 GET oBot[1] VAR cGet OF oDlgF SIZE 190,12 PIXEL
@ 75,130 BUTTON oBot[2] PROMPT "&Salir" OF oDlgF SIZE 50,12 ;
       ACTION oDlgF:End() PIXEL     
ACTIVATE DIALOG oDlgF CENTER 
RETURN .f.  