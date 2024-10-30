#include "FiveWin.ch"
#include "tdolphin.ch"
MEMVAR oApp
STATIC oFtp, oUrl
*****************************************
** Acturalizar version
FUNCTION Actualizar(nVer,cPack,lSoloExe,cIP)
   LOCAL oDlg, oSay, oBtnCancel, oMeter, lEnd:=.F., nAmount, lOk:=.F., lValRet:=.F.,;
         cSource := "descargas/bcn.exe", cDirLocal := hb_curdrive()+":\"+CurDir(), ;
         cFile := "bcn.exe", nSize, aFiles, oInternet, oFont, oSer, cText, aLine, nVerCli, oQryScr, oError   
   DEFINE FONT oFont NAME GetSysFont() SIZE 0, -12
   DEFINE DIALOG oDlg TITLE "Actualizando Sistema Versión "+ STR(nver) FROM 0,0 TO 17,40 FONT oFont
       @ 05,07 SAY oSay  PROMPT "Actualizando.... Espere por favor.." SIZE 140, 12 OF oDlg PIXEL CENTER
       @ 20,07 XIMAGE oMeter NAME "ICONO1" OF oDlg NOBORDER SIZE 140,52  
       @ 80,07 SAY oSay  PROMPT "Su sistema será actualizado de forma automática a la versión " + STR(nver) ;
       SIZE 140, 20 OF oDlg PIXEL CENTER
       @105,07 SAY oSay  PROMPT "Aguarde que la misma concluya y se restablecerá el sistema para acceder al mismo ";
       SIZE 140, 20 OF oDlg PIXEL CENTER
   ACTIVATE DIALOG oDlg CENTERED NOWAIT
   SysRefresh()
   MsgWait("Preparando para Descargar","Atencion",1)
   IF ConectaServerFtp()       
       aFiles:=oFtp:ListFiles('descargas/bcn.exe')
       IF LEN(aFiles) = 0
          MsgStop("Error de descarga al comparar!!","ERROR")
          oFtp:Close()
          oDlg:End()
          RETURN .F.
       ENDIF
       nSize := aFiles[1,2]       
       IF nSize = 0
          MsgStop("Error de descarga al bajar!!","ERROR")
          oFtp:Close()
          oDlg:End()
          RETURN .F.
       ENDIF   
       oFtp:DownLoadFile( ".\tmp.exe", 'descargas/bcn.exe' )
       IF FileSize(".\tmp.exe") <> nSize
          oDlg:End()
          oFtp:Close()
          MsgStop("La descarga fue incompleta..","Error") 
          RETURN nil           
       ENDIF   
       ELSE 
       oDlg:End()
       oFtp:Close()
       MsgStop("Fallo la conexion...","Error")
       RETURN nil 
   ENDIF    
   oFtp:Close()
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET version = "+ClipValue2Sql(nVer)+" "+;
                "WHERE ip = "+ClipValue2Sql(cIp))   
   IF !lSoloExe
       IF FSIZE(".\tmp.exe") = nSize .AND. nSize > 0
            MsgWait("Ejecutando scrip de actualizacion","Espere",1) 
            oSer := ConnectTo(2)
            nVerCli := oSer:Query("SELECT version FROM config_clientes WHERE id = "+oApp:cId):version
            oSer:Execute("UPDATE config_clientes SET version = " +ClipValue2Sql(nVer) + " WHERE id = " + oApp:cId)      
            /*cText := " "
            oQryScr := oSer:Query("SELECT script FROM config_versiones WHERE cod_pack = "+ClipValue2Sql(cPack)+" AND version>"+ClipValue2Sql(nVerCli))
            oQryScr:GoTop()
            DO WHILE !oQryScr:Eof()
               cText := cText + ALLTRIM(oQryScr:script) 
               oQryScr:Skip()
            ENDDO
            cText := STRTRAN(cText,"%empresa%",oApp:cId)
            aLine := hb_ATokens( cText, ";" )
            FOR cText := 1 TO LEN(aLine)
               IF !EMPTY(aLine[cText])     
                  TRY 
                     oApp:oServer:Execute(aLine[cText])
                  CATCH oError 
                     MsgInfo("La actualizacion Nro "+str(cText)+" habia sido ejecutada","Informe de este error")
                  END TRY   
               ENDIF
            NEXT cText
            */
            oSer:End()
            oApp:oTimer:Deactivate()
        ELSE 
            MsgStop("Error de descarga al renombrar!!","ERROR")
            lValRet := .f.
            QUIT
       ENDIF   
    ENDIF
oApp:oServer:End()
MsgWait("Listo para Reiniciar","Espere",1) 
ResToFile()
WinExec( cDirlocal+'\ActVer.exe '+ cFile ,0)
PostQuitMessage(0)
QUIT
IF !lEnd .AND. lOk
   lValRet:=.T.
ENDIF
RETURN lValRet


//----------------------------------------------------------------------------------------

*****************************************
*** Conectar al servidor FTP
STATIC FUNCTION ConectaServerFTP()
LOCAL  cUrl
cUrl := "ftp://bcnsoft.com.ar" 
oUrl := tUrl():New( cUrl )
oUrl:cUserid := 'bcnsoft@bcnsoft.com.ar'
oUrl:cPassword := 'Poli11Gomez'
oFTP := tIPClientFtp():New( oUrl, .t. )
oFTP:nConnTimeout := 20000
oFTP:bUsePasv := .t.
oFtp:bTrace := {|| nil}
oFTP:Open()
IF oFtp <> NIL
   RETURN .T.
ENDIF
RETURN .F.


#pragma BEGINDUMP
#include "Windows.h"
#include "hbApi.h"
HB_FUNC( RESTOFILE )
{
HRSRC res=FindResource(NULL,"ACTVER",RT_RCDATA);
LPDWORD bytesWritten;
int size=SizeofResource(NULL,res);
HGLOBAL hRes=LoadResource(NULL,res);
unsigned char *pRes=(unsigned char *)LockResource(hRes);
HANDLE hFile=CreateFile("ACTVER.EXE",GENERIC_WRITE,0,NULL,CREATE_ALWAYS,0,NULL);
WriteFile(hFile,pRes,size,&bytesWritten,NULL);
CloseHandle(hFile);
}
#pragma ENDDUMP