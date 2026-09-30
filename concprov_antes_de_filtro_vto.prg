#include "Fivewin.ch"
#include "Tdolphin.ch"

*************************************************
** CONCPROV - Programa aparte (no va en el sistema)
** Recorre todos los clientes de bcn_config.config_clientes con pack GE3
** y concilia la cuenta corriente de proveedores de cada uno
** (ver CTAPROV.PRG -> ConciliarCtaProv).
**
**  - Modo informe: no graba nada, solo muestra que ajustaria.
**  - Modo conciliar: genera las OPs de ajuste, el log y la marca.
**  - Clientes sin las tablas (dados de baja) o sin conexion se saltean.
**  - Deja concprov_<fecha>_<modo>.txt (detalle, con el porque de cada ajuste),
**    .csv (un renglon por proveedor) y _motivos.csv (un renglon por motivo).
**
** Ejecutar "CONCPROV LOCAL" para probar contra la base local
** (127.0.0.1:3306 root, config en la base bcn_config_prueba).
**
** Compila con CTAPROV.PRG y CONNTO.PRG (ver CONCPROV.BAT).
*************************************************
MEMVAR oApp

STATIC lLocal := .f., cLogTxt := ""

FUNCTION Main(cParam, cParam2)
LOCAL oDlg, oFont, oLog, oMeter, oBot := ARRAY(2), nModo := 1, cVersion, cLog := "", nActual := 0
PUBLIC oApp := nil
DEFAULT cParam := "", cParam2 := ""
IF !(UPPER(ALLTRIM(cParam)) == "LOCAL")
   cParam2 := cParam
ENDIF
lLocal   := UPPER(ALLTRIM(cParam)) == "LOCAL"
cParam2  := UPPER(ALLTRIM(cParam2))
D_SetCaseSensitive( .T. )
IF cParam2 == "INFORME" .OR. cParam2 == "CONCILIAR"
   // Sin ventana (para correrlo programado): deja los mismos archivos
   Procesar(cParam2 == "CONCILIAR", DTOS(DATE()), NIL, NIL, .t.)
   RETURN nil
ENDIF
cVersion := PADR(DTOS(DATE()),20)
D_SetCaseSensitive( .T. )
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Conciliacion cta. cte. proveedores - clientes GE3"+IF(lLocal," (LOCAL)","") ;
       FROM 03,10 TO 38,120 FONT oFont
   oDlg:lHelpIcon := .f.
   @ 07, 08 SAY "Modo:" OF oDlg PIXEL SIZE 40,10
   @ 05, 50 RADIO nModo ITEMS "Solo informe (no graba nada)", "Conciliar (graba OPs de ajuste)" ;
            OF oDlg PIXEL SIZE 150,11
   @ 37, 08 SAY "Version:" OF oDlg PIXEL SIZE 40,10
   @ 35, 50 GET cVersion OF oDlg PIXEL SIZE 80,11
   @ 52, 08 METER oMeter VAR nActual TOTAL 100 OF oDlg PIXEL SIZE 410,10
   @ 67, 08 GET oLog VAR cLog MEMO OF oDlg PIXEL SIZE 410,165 READONLY
   @ 240, 140 BUTTON oBot[1] PROMPT "&Ejecutar" OF oDlg PIXEL SIZE 50,12 ;
            ACTION (oBot[1]:Disable(), Procesar(nModo = 2, ALLTRIM(cVersion), oLog, oMeter, .f.), oBot[1]:Enable())
   @ 240, 230 BUTTON oBot[2] PROMPT "&Salir" OF oDlg PIXEL SIZE 50,12 ACTION oDlg:End() CANCEL
ACTIVATE DIALOG oDlg CENTER
oFont:End()
RETURN nil

*************************************************
STATIC FUNCTION Procesar(lGrabar, cVersion, oLog, oMeter, lSinVentana)
LOCAL oCfg, oQ, hSrv := {=>}, oSrv, cClave, cId, aRes, i, j, cTxt := "", cCsv := "", cCsvMot := "", cArch, lYa,;
      nSinTablas := 0, nSinConex := 0, nYa := 0, nAjust := 0, nLimpios := 0, nError := 0, nProv := 0,;
      nTotal, nN := 0, oError

IF lGrabar .AND. !lSinVentana
   IF !MsgNoYes("Va a GRABAR las OPs de ajuste en todos los clientes GE3."+CRLF+;
                "Hacerlo despues del backup y con la version nueva ya activa."+CRLF+CRLF+;
                "Continua?","Conciliar")
      RETURN nil
   ENDIF
ENDIF
cLogTxt := ""
IF oLog <> NIL
   oLog:cText := ""
ENDIF
Agrega(oLog, "Inicio "+DTOC(DATE())+" "+TIME()+" - modo "+IF(lGrabar,"CONCILIAR","INFORME"))

oCfg := Conecta("bcn_config", "")
IF oCfg == NIL
   Agrega(oLog, "ERROR: no conecta a bcn_config")
   RETURN nil
ENDIF
oQ := oCfg:Query("SELECT id, nombre, base, host FROM config_clientes WHERE pack = 'GE3' ORDER BY host, base, id")
nTotal := oQ:RecCount()
IF oMeter <> NIL
   oMeter:nTotal := MAX(nTotal,1)
ENDIF
Agrega(oLog, ALLTRIM(STR(nTotal))+" clientes GE3 en config_clientes")
cCsv := "cliente;base;codpro;proveedor;anticipo_guardado;anticipo_formula;ajuste;facturas;deuda;ctacte"+CRLF
cCsvMot := "cliente;base;codpro;proveedor;motivo;importe;detalle"+CRLF

oQ:GoTop()
DO WHILE !oQ:Eof()
   nN++
   IF oMeter <> NIL
      oMeter:Set(nN)
   ENDIF
   cId    := STRTRAN(STR(oQ:id,6)," ","0")
   cClave := LOWER(ALLTRIM(oQ:host))+"|"+LOWER(ALLTRIM(oQ:base))
   IF !HB_HHasKey(hSrv, cClave)
      hSrv[cClave] := Conecta(ALLTRIM(oQ:base), ALLTRIM(oQ:host))
   ENDIF
   oSrv := hSrv[cClave]
   cTxt := cId+" "+PADR(ALLTRIM(oQ:nombre),30)+" ["+ALLTRIM(oQ:base)+"] "
   DO CASE
   CASE oSrv == NIL
      nSinConex++
      Agrega(oLog, cTxt+"SIN CONEXION a la base")
   CASE !TienenTablas(oSrv, cId)
      nSinTablas++
      // los dados de baja no se listan uno por uno, solo se cuentan
   OTHERWISE
      TRY
         lYa  := CtaProvConciliado(oSrv, cId)
         aRes := ConciliarCtaProv(lGrabar, oSrv, cId, cVersion, "CONCILIACION")
         IF !aRes[1]
            nError++
            Agrega(oLog, cTxt+"ERROR: "+aRes[2])
         ELSEIF lYa
            nYa++
            IF LEN(aRes[3]) > 0      // conciliado pero con descuadres nuevos (no deberia pasar)
               Agrega(oLog, cTxt+"YA CONCILIADO, pero con "+ALLTRIM(STR(LEN(aRes[3])))+" proveedores descuadrados!")
            ENDIF
         ELSEIF LEN(aRes[3]) = 0
            nLimpios++
         ELSE
            nAjust++
            nProv += LEN(aRes[3])
            Agrega(oLog, cTxt+IF(lGrabar,"CONCILIADO: ","A AJUSTAR: ")+ALLTRIM(STR(LEN(aRes[3])))+" proveedores")
         ENDIF
         IF aRes[1] .AND. LEN(aRes[3]) > 0
            FOR i := 1 TO LEN(aRes[3])
               cCsv += cId+";"+ALLTRIM(oQ:base)+";"+ALLTRIM(STR(aRes[3,i,1]))+";"+STRTRAN(aRes[3,i,2],";",",")+";"+;
                       Num(aRes[3,i,3])+";"+Num(aRes[3,i,4])+";"+Num(aRes[3,i,5])+";"+;
                       ALLTRIM(STR(aRes[3,i,6]))+";"+Num(aRes[3,i,7])+";"+Num(aRes[3,i,8])+CRLF
               // Por que se ajusta cada proveedor: al .txt y al _motivos.csv
               Agrega(oLog, "     Prov "+ALLTRIM(STR(aRes[3,i,1]))+" "+aRes[3,i,2]+": ajuste cta cte "+Num(aRes[3,i,5]))
               IF LEN(aRes[3,i]) >= 9
                  FOR j := 1 TO LEN(aRes[3,i,9])
                     Agrega(oLog, "        ["+aRes[3,i,9,j,1]+"] "+aRes[3,i,9,j,2]+;
                                  IF(aRes[3,i,9,j,3] <> 0, "  => "+Num(aRes[3,i,9,j,3]), ""))
                     cCsvMot += cId+";"+ALLTRIM(oQ:base)+";"+ALLTRIM(STR(aRes[3,i,1]))+";"+;
                                STRTRAN(aRes[3,i,2],";",",")+";"+aRes[3,i,9,j,1]+";"+Num(aRes[3,i,9,j,3])+";"+;
                                STRTRAN(aRes[3,i,9,j,2],";",",")+CRLF
                  NEXT j
               ENDIF
            NEXT i
         ENDIF
      CATCH oError
         nError++
         Agrega(oLog, cTxt+"ERROR: "+IF(oError <> nil, oError:description+" "+oError:operation, ""))
      END TRY
   ENDCASE
   oQ:Skip()
ENDDO

Agrega(oLog, REPLICATE("-",60))
Agrega(oLog, "Clientes GE3 .............: "+STR(nTotal,6))
Agrega(oLog, "Sin tablas (baja) ........: "+STR(nSinTablas,6))
Agrega(oLog, "Sin conexion .............: "+STR(nSinConex,6))
Agrega(oLog, "Ya conciliados antes .....: "+STR(nYa,6))
Agrega(oLog, "Sin diferencias ..........: "+STR(nLimpios,6))
Agrega(oLog, IF(lGrabar,"Conciliados con ajuste ...: ","Con diferencias ..........: ")+STR(nAjust,6)+;
             "  ("+ALLTRIM(STR(nProv))+" proveedores)")
Agrega(oLog, "Con error ................: "+STR(nError,6))
Agrega(oLog, "Fin "+TIME())

cArch := "concprov_"+DTOS(DATE())+"_"+STRTRAN(LEFT(TIME(),5),":","")+"_"+IF(lGrabar,"conciliar","informe")
MemoWrit(cArch+".txt", cLogTxt)
MemoWrit(cArch+".csv", cCsv)
MemoWrit(cArch+"_motivos.csv", cCsvMot)
Agrega(oLog, "Archivos: "+cArch+".txt / .csv / _motivos.csv")

FOR EACH oSrv IN hSrv
   IF oSrv <> NIL
      oSrv:End()
   ENDIF
NEXT
oCfg:End()
RETURN nil

*************************************************
** Las 5 tablas que usa la conciliacion tienen que existir
STATIC FUNCTION TienenTablas(oSrv, cId)
LOCAL cP := "ge_"+cId
RETURN oSrv:Query("SELECT COUNT(*) AS cant FROM information_schema.tables "+;
                  "WHERE table_schema = DATABASE() AND table_name IN ("+;
                  "'"+cP+"provee','"+cP+"compras','"+cP+"ordpag','"+cP+"ordfac','"+cP+"ordcon')"):cant = 5

*************************************************
** Conexion: en modo LOCAL a la base local de prueba, si no igual que el
** sistema (CONNTO.PRG). cHost vacio = bcn_config.
STATIC FUNCTION Conecta(cBase, cHost)
LOCAL oSrv, oErr
IF lLocal
   IF EMPTY(cHost)
      cBase := "bcn_config_prueba"
   ENDIF
   TRY
      CONNECT oSrv HOST "127.0.0.1" USER "root" PASSWORD "" PORT 3306 FLAGS 0 DATABASE cBase
   CATCH oErr
      oSrv := NIL
   END
   RETURN oSrv
ENDIF
IF EMPTY(cHost)
   RETURN ConnectTo(2)
ENDIF
RETURN ConnectTo(1, cBase, cHost, .f.)

*************************************************
STATIC FUNCTION Agrega(oLog, cLinea)
cLogTxt += cLinea + CRLF
IF oLog <> NIL
   oLog:cText := cLogTxt
   oLog:GoBottom()
   SysRefresh()
ENDIF
RETURN nil

STATIC FUNCTION Num(n)
RETURN STRTRAN(ALLTRIM(STR(n,16,2)),".",",")
