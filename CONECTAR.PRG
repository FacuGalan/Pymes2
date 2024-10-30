#include "tdolphin.ch"
#include "xbrowse.ch"
#include "fivewin.ch"
MEMVAR oApp, nCliente

FUNCTION Conectar()
LOCAL oServer, cDB, lRta, cHost, lLocal, oQryProc
   D_SetCaseSensitive( .T. )
   Set_MyLang( "es_ES" )
   
   IF ( oServer := ConnectTo(2) ) == NIL
      MsgStop("Internet no responde."+CHR(10)+;
              "Verifique que el equipo tenga conexion a internet"+CHR(10)+;              
              "Error de conexion")
      QUIT      
   ENDIF

   IF !FILE("BCN.DLL")
      MsgStop("Un archivo fundamental para la ejecucion del programa"+CHR(10)+;
              "no esta presente. Por favor"+CHR(10)+;
              "comuniquese con el servicio tecnico."+CHR(10)+;
              "Verifique que su conexion de internet esta activa.",;
              "Error de Instalacion")
      QUIT
   ENDIF
   USE bcn.dll SHARED NEW ALIAS "bcn"
   IF neterr( )
      MsgStop("El programa no tiene permisos de lectura en su PC"+CHR(10)+;
              "Por favor, vuelva a ejecutar el programa con permisos de supervisor."+CHR(10)+;
              "Haga click derecho en el acceso directo y elija la opcion"+CHR(10)+;
              "EJECUTAR COMO ADMINISTRADOR.",;
              "Vuelva a intentarlo.")
      QUIT 
   ENDIF
   nCliente := 0
   IF FILE("BCN_administra.DLL")      
      MsgGet("Ingrese cliente","Ingrese Cliente",@nCliente)
   ENDIF   
   IF EMPTY(bcn->id)
      lRta := PrimeraVez(oServer)
      IF !lRta
         CLOSE bcn
         QUIT
      ENDIF
      ValidarCli(oServer,@cDB,@cHost,@lLocal)
      ELSE 
      ValidarCli(oServer,@cDB,@cHost,@lLocal,nCliente) 
   ENDIF
   CLOSE bcn 
   oServer:End()
   IF ( oServer := ConnectTo(1,cDB,cHost,lLocal) ) == NIL
       MsgStop("Internet no responde."+CHR(10)+;
              "Verifique que el equipo tenga conexion a internet"+CHR(10)+;              
              "Error de conexion")
      QUIT      
   ENDIF
   oQryProc:= oServer:Query("SELECT id FROM information_schema.processlist WHERE db = '"+cDB+"' AND TIME > 3000")
   IF oQryProc:reccount() > 0
     oQryProc:GoTop()
     WHILE !oQryProc:EOF()
        oServer:Execute("KILL "+ClipValue2Sql(oQryProc:id))
        oQryProc:Skip()
     ENDDO
   ENDIF
RETURN oServer


STATIC FUNCTION PrimeraVez(oServer)
LOCAL oGet := ARRAY(2), oBot := ARRAY(2), oForm, lRta := .f., aCor, oError,;
      cMail := SPACE(100), cCode := SPACE(30), oQry, cDB, cHost, lLocal,oServer1
DO WHILE .T.
DEFINE DIALOG oForm TITLE "Identificacion de usuario";
       FROM 05,15 TO 19,65 
   
   @ 07, 05 SAY "Gracias por descargar nuestro programa. "+ ;
                "Este proceso lo guiara paso a paso para la correcta "+;
                "instalacion del mismo."+;
                "Indique a continuacion el mail que utilizo para descargar "+;
                "el programa y el codigo que le fue suministrado."    OF oForm PIXEL SIZE 170,40 
   @ 52, 05 SAY "E-Mail:"                 OF oForm PIXEL SIZE 50,20 RIGHT
   @ 67, 05 SAY "Codigo de Validacion:"   OF oForm PIXEL SIZE 50,20 RIGHT
     
   @ 50, 65 GET oGet[1] VAR cMail PICTURE "@S35"    OF oForm PIXEL 
   @ 65, 65 GET oGet[2] VAR cCode PICTURE "@!"      OF oForm PIXEL 
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Continuar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL WHEN(!EMPTY(oGet[1]:cText) .and. !EMPTY(oGet[2]:cText))
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN .f.
ENDIF
Procesando(.t.)
oQry := oServer:Query("SELECT * FROM config_clientes WHERE mail = " +;
                       ClipValue2Sql(cMail) + " AND code = " + ClipValue2Sql(cCode)+;
                       " AND pack LIKE '%GE%'")
Procesando(.f.)
IF oQry:nRecCount = 0 
   MsgStop("La combinacion de mail y codigo ingresados no son validos.","Error")
   LOOP
ENDIF
EXIT
ENDDO
Procesando(.t.)
cDB := ALLTRIM(oQry:base)
oServer1 := ConnectTo(1,cDB, ALLTRIM(oQry:host),oQry:baselocal) 
// Verificar si las tablas estan creadas
IF oServer1:TableExist( "ge_"+STRTRAN(STR(oQry:id,6)," ","0")+"ventivadet" )
   //Si existe verifico si tiene una terminal registrada
   IF oServer1:Query("SELECT * FROM " + "ge_"+STRTRAN(STR(oQry:id,6)," ","0")+"punto"):nRecCount > 0
      //Quiere decir que tiene, o sea que pregunto si quiere agregar la terminal
      Procesando(.f.)
      IF bcn->(rlock())
		     REPLACE bcn->id   WITH STRTRAN(STR(oQry:id,6)," ","0"),;
		         bcn->mail WITH cMail
	    ENDIF
      bcn->(dbunlock())
      AgregarTerminal(oServer1,oQry:id,2)
      RETURN .t.
   ENDIF
   ELSE
   CorrerScript(oServer,oServer1,oQry:id)
   Procesando(.f.)
   AgregarTerminal(oServer1,oQry:id,1) 
ENDIF
IF bcn->(rlock())
   REPLACE bcn->id   WITH STRTRAN(STR(oQry:id,6)," ","0"),;
           bcn->mail WITH cMail
ENDIF
bcn->(dbunlock())
RETURN .T.

STATIC FUNCTION ValidarCli(oServer,cDb,cHost,lLocal,nCliente)
LOCAL oQry, oQry1, cMail
oApp:cId := IF(nCliente=nil .or. nCliente = 0,bcn->id,STRTRAN(STR(nCliente,6)," ","0")) 

oQry  := oServer:Query("SELECT c.*, c.abono * if(c.disc_iva=3,1.21,1) as saldoabono, curdate() as fechact, p.alias FROM config_clientes c "+;
                     " LEFT JOIN perfiles p ON p.id = c.id_perfil "+;  
                     "WHERE c.id = " + oApp:cId)
cMail := IF(nCliente=0,bcn->mail,oQry:mail) 
oQry1 := oServer:Query("SELECT MIN(vto) as fechavto "+;
                       " FROM config_clientes "+;
                       " WHERE id = "+oApp:cId)
cDB    := ALLTRIM(oQry:base)
cHost  := ALLTRIM(oQry:host)
lLocal := oQry:baselocal

// Paso 1: Verificar que el cliente exista
IF oQry:nRecCount = 0
   MsgStop("1- El programa no esta registrado correctamente..."+CHR(10)+;
           "por favor, ponganse en contacto con el proveedor","Error")
   QUIT
ENDIF
// Paso 2: Verificar que el cliente sea el de la configuracion
IF ALLTRIM(oQry:mail) <> ALLTRIM(cMail)
   MsgStop("2- El programa no esta registrado correctamente..."+CHR(10)+;
           "por favor, ponganse en contacto con el proveedor","Error")
   QUIT
ENDIF
// Paso 3: Verificar que el cliente este activo
IF !oQry:activo
   MsgStop("3- El programa no esta activo para esta instalacion..."+CHR(10)+;
           "por favor, ponganse en contacto con el proveedor","Error")
   QUIT
ENDIF
// Paso 4: Verificar que no este vencido el periodo de prueba
IF oQry:demo .and. oQry:vto < oQry:fechact
   MsgStop("El periodo de prueba ha caducado..."+CHR(10)+;
           "por favor, ponganse en contacto con el proveedor"+CHR(10)+;
           "si necesita extender dicho periodo","Periodo Expirado")
   QUIT
ENDIF
// Paso 5: Avisar los dias que le quedan
IF oQry:demo
   /*IF oQry:vto-oQry:fechact >= 7
     MsgInfo("Su periodo de prueba ya finalizo, si esta interesado en el sistema o tiene alguna duda comuniquese "+CHR(10)+;
             "con su proveedor o visitenos en WWW.BCNSOFT.COM.AR"+chr(10)+str(oQry:vto-oQry:fechact)+' dias',"Programa DEMO") 
     QUIT
   ELSE*/
     /*MsgInfo("Este programa no esta registrado."+CHR(10)+;
             "Al periodo de prueba le quedan "+STR(oQry:vto-oQry:fechact+1,5)+" dias restantes"+CHR(10)+;
             "agradecemos su interes en nuestros productos","Programa DEMO")*/
   /*ENDIF*/
ENDIF
IF !oQry:demo .AND. oQry:fechact > oQry1:fechavto .and. oQry:saldoabono > 0
   IF oQry:fechact - oQry1:fechavto > 5
      MsgStop("Le recordamos que el vencimiento de su cuota del abono mensual "+;
           "operaba el día "+DTOC(oQry1:fechavto)+"."+CHR(10)+"Su servicio fue cancelado por falta de pago, "+;
           "contactese con su proveedor para restaurarlo."+CHR(10)+;
           "Importe actual del abono mensual: $"+ALLTRIM(STR(oQry:saldoabono,12,2))+chr(10)+;
           "Alias para realizar la transferencia: "+ALLTRIM(upper(oQry:alias)),"Vencimiento de abono")
      QUIT
   ENDIF
      MsgStop("SU ABONO ESTA VENCIDO DESDE EL DÍA "+DTOC(oQry1:fechavto)+CHR(10)+CHR(10)+;
           "Dispone de "+ALLTRIM(STR(5-(oQry:fechact - oQry1:fechavto)))+" días de gracia antes de que se cancele su suscripción."+CHR(10)+CHR(10)+;
           "Por favor, realice el pago de la misma para poder seguir operando con el sistema."+chr(10)+;
           "Importe actual del abono mensual: $"+ALLTRIM(STR(oQry:saldoabono,12,2))+chr(10)+;
           "Alias para realizar la transferencia: "+ALLTRIM(upper(oQry:alias));
           ,"Vencimiento de cuota")

ENDIF
oQry:End()
RETURN NIL


STATIC FUNCTION CorrerScript(oServer,oServer1,nId)
LOCAL cText := oServer:Query("SELECT consulta FROM config_importa WHERE id=1"):consulta, aLine,;
      dFecVto := oServer:Query("SELECT curdate() as fecha"):fecha + 7
cText := STRTRAN(cText,"%empresa%",STRTRAN(STR(nId,6)," ","0"))
aLine := hb_ATokens( cText, ";" )
oServer1:MultiQuery( aLine, .t. )
oServer:Execute("UPDATE config_clientes SET activo = true,  Tablas_creadas = true WHERE id = " + STR(nId))
RETURN nil

STATIC FUNCTION AgregarTerminal(oServer,nId,n)
LOCAL cIp,cId := STRTRAN(STR(nId,6)," ","0"), lRta := .f.,;
      cPunto := oServer:Query("SELECT COUNT(ip) as cant FROM ge_"+cId+"punto"):cant + 1
cPunto := STR(cPunto)
IF n = 1
   cIP :=  GetNetCardInfo()[1,1]
   oServer:Execute("INSERT INTO ge_"+cId+"punto (ip,caja) "+;
                    " value  (" + ClipValue2SQL(cIp) + ",1)")
   ELSE 
   cIP :=  GetNetCardInfo()[1,1]
   lRta := MsgNoYes("Ud. ya posee puntos de venta cargado..."+CHR(10)+;
            "Realmente quiere agregar otra terminal"+CHR(10)+;
            "para operar con el sistema?","Atencion")
   IF lRta
      oServer:Execute("INSERT INTO ge_"+cId+"punto (ip,caja) "+;
                    " value  (" + ClipValue2SQL(cIp) + ","+cPunto+")")
   ENDIF
ENDIF

RETURN nil

#include "connto.prg"