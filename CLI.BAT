@ECHO OFF
CLS
ECHO ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO ³ FiveWin for Harbour 2.7 - March 2006            Harbour development power  ³Ü
ECHO ³ (c) FiveTech, 1993-2006      for Microsoft Windows 95/98/NT/2000/ME and XP ³Û
ECHO ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÛ
ECHO ÿ ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß

if A%1 == A GOTO :SINTAX
if NOT EXIST %1.prg GOTO :NOEXIST

ECHO Compiling...

set hdir=c:\harb16
set bcdir=c:\bcc7
SET INCLUDE=C:\FWH16\INCLUDE

%hdir%\bin\harbour %1 /n /i..\include;%hdir%\include /w /p %2 %3 > clip.log
@type clip.log
IF ERRORLEVEL 1 PAUSE
IF ERRORLEVEL 1 GOTO EXIT

echo -O2 -e%1.exe -I%hdir%\include %1.c > b32.bc
%bcdir%\bin\bcc32 -M -c @b32.bc
:ENDCOMPILE
