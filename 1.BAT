@ECHO OFF
CLS
ECHO ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO ³ FiveWin for Harbour 2.7 - March 2006            Harbour development power  ³Ü
ECHO ³ (c) FiveTech, 1993-2006      for Microsoft Windows 95/98/NT/2000/ME and XP ³Û
ECHO ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÛ
ECHO ÿ ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß


set hdir=c:\harb16
set bcdir=c:\bcc7
SET LIB=C:\FWH16\LIB


echo -O2 -eBCN.exe -I%hdir%\include BCN.c > b32.bc
%bcdir%\bin\bcc32 -M -c @b32.bc
:ENDCOMPILE

IF EXIST RC\BCN.rc %bcdir%\bin\brc32 -r RC\BCN

echo c0w32.obj + > b32.bc
echo BCN.obj  + >> b32.bc
echo prueba2.obj + >> b32.bc
echo listadostab.obj procesosper.obj + >> b32.bc
echo modsto.obj pregen.obj fcaja.obj rcaja.obj chepro.obj cheter.obj depret.obj modrem.obj abmgar.obj + >> b32.bc
echo abmpro.obj abmmar.obj abmrub.obj abmven.obj abmban.obj abmctas.obj abmcom.obj abmpcon.obj abmcondven.obj + >> b32.bc
echo abmiva.obj abmrep.obj abmdat.obj abmdat1.obj abmcli.obj abmcli1.obj abmart.obj abmdes.obj abmrep.obj + >> b32.bc
echo abmemp.obj abmdep.obj abmret.obj abmfor.obj abmaut.obj bcaja.obj cambiopre.obj combus.obj + >> b32.bc
echo ordenes.obj canpag.obj pedprov.obj consulta.obj pedidos.obj abmfgs.obj buscapre.obj lispre.obj promos.obj service.obj + >> b32.bc
echo calinfo.obj tcalex.obj agenda.obj + >> b32.bc
echo liscaja.obj cietur.obj vales.obj audita.obj + >> b32.bc
echo descu.obj carcre.obj cardeu.obj fe.obj venrei.obj asigna.obj + >> b32.bc
echo prelis.obj lisarti.obj lisven.obj liscom.obj lisfac.obj lisdeu.obj grafica.obj + >> b32.bc
echo compras.obj lische.obj ventas.obj rendi.obj gastos.obj citicomp.obj remitar.obj fact_multi.obj + >> b32.bc
echo etique.obj ordpag.obj cobran.obj facrem.obj FACT.obj transf.obj + >> b32.bc
echo ABMEMPLE.OBJ ABMCATEMP.OBJ ABMHORAS.OBJ ABMINAS.OBJ ABMSECTOR.OBJ LISHORAS.OBJ NOVINDIV.OBJ PAGEMPLE.OBJ CONSUMOINT.OBJ + >> b32.bc
echo xbrowse.obj busqueda.obj utiles.obj usua.obj demo.obj enviomail.obj rpreview.obj prv2pdf.obj + >> b32.bc
echo conectar.obj descarga.obj, + >> b32.bc
echo BCN.exe, + >> b32.bc
echo BCN.map, + >> b32.bc
echo H71532BC.LIB C:\FWH11\lib\dolphin.lib + >> b32.bc
echo C:\FWH16\lib\dolphin.lib + >> b32.bc
echo C:\FWH16\lib\FiveH.lib C:\FWH16\lib\FiveHC.lib C:\FWH16\lib\tcalex.lib + >> b32.bc
echo C:\FWH16\lib\libmysql.lib + >> b32.bc
echo C:\FWH16\lib\libmysqld.lib + >> b32.bc
echo %hdir%\lib\hbwin.lib + >> b32.bc
echo %hdir%\lib\hbrtl.lib + >> b32.bc
echo %hdir%\lib\xhb.lib + >> b32.bc
echo %hdir%\lib\hbvm.lib + >> b32.bc
echo %hdir%\lib\gtgui.lib + >> b32.bc
echo %hdir%\lib\gtstd.lib + >> b32.bc
echo %hdir%\lib\hblang.lib + >> b32.bc
echo %hdir%\lib\hbmacro.lib + >> b32.bc
echo %hdir%\lib\hbrdd.lib + >> b32.bc
echo %hdir%\lib\rddntx.lib + >> b32.bc
echo %hdir%\lib\rddcdx.lib + >> b32.bc
echo %hdir%\lib\rddfpt.lib + >> b32.bc
echo %hdir%\lib\hbsix.lib + >> b32.bc
echo %hdir%\lib\hbdebug.lib + >> b32.bc
echo %hdir%\lib\hbcommon.lib + >> b32.bc
echo %hdir%\lib\hbpp.lib + >> b32.bc
echo %hdir%\lib\hbusrrdd.lib + >> b32.bc
echo %hdir%\lib\hbwin.lib + >> b32.bc
echo %hdir%\lib\hbcplr.lib + >> b32.bc
echo %hdir%\lib\hbct.lib + >> b32.bc
echo %hdir%\lib\hbcpage.lib + >> b32.bc
echo %hdir%\lib\hbhsx.lib + >> b32.bc
echo %hdir%\lib\hbmisc.lib + >> b32.bc
echo %hdir%\lib\hbmzip.lib + >> b32.bc
echo %hdir%\lib\hbnf.lib + >> b32.bc
echo %hdir%\lib\hbpcre.lib + >> b32.bc
echo %hdir%\lib\hbtip.lib + >> b32.bc
echo %hdir%\lib\hbziparc.lib + >> b32.bc
echo %hdir%\lib\hbmzip.lib + >> b32.bc
echo %hdir%\lib\hbzlib.lib + >> b32.bc
echo %hdir%\lib\minizip.lib + >> b32.bc
echo %hdir%\lib\png.lib + >> b32.bc
echo %hdir%\lib\hbusrrdd.lib + >> b32.bc
echo %hdir%\lib\hbtip.lib + >> b32.bc

rem Uncomment these two lines to use Advantage RDD
rem echo %hdir%\lib\rddads.lib + >> b32.bc
rem echo %hdir%\lib\Ace32.lib + >> b32.bc

echo %bcdir%\lib\cw32.lib + >> b32.bc
echo %bcdir%\lib\uuid.lib + >> b32.bc
echo %bcdir%\lib\import32.lib + >> b32.bc
echo %bcdir%\lib\ws2_32.lib + >> b32.bc
echo %bcdir%\lib\psdk\odbc32.lib + >> b32.bc
echo %bcdir%\lib\psdk\nddeapi.lib + >> b32.bc
echo %bcdir%\lib\psdk\iphlpapi.lib + >> b32.bc
echo %bcdir%\lib\psdk\msimg32.lib + >> b32.bc
echo %bcdir%\lib\psdk\psapi.lib + >> b32.bc
echo %bcdir%\lib\psdk\rasapi32.lib + >> b32.bc
echo %bcdir%\lib\psdk\gdiplus.lib + >> b32.bc
echo %bcdir%\lib\psdk\shell32.lib, >> b32.bc

IF EXIST RC\BCN.res echo RC\BCN.res >> b32.bc
rem uncomment this line to use the debugger and comment the next one
rem %bcdir%\bin\ilink32 -Tpe -s @b32.bc
%bcdir%\bin\ilink32 -Gn -aa -Tpe -s @b32.bc

IF ERRORLEVEL 1 GOTO LINKERROR
ECHO * Application successfully built
@del *.c
@del *.PPO
@del *.MAP
GOTO EXIT
ECHO

rem delete temporary files
@del *.c
@del *.PPO
@del *.MAP

:LINKERROR
ECHO * There are errors
GOTO EXIT

:SINTAX
ECHO    SYNTAX: Build [Program]     {-- No especifiques la extensi¢n PRG
ECHO                                {-- Don't specify .PRG extension
GOTO EXIT

:NOEXIST
ECHO The specified PRG %1 does not exist

:EXIT
