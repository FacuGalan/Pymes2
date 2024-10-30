#include "FiveWin.ch"  
#include "Tdolphin.ch"   
MEMVAR oApp  
PROCEDURE citicompras()
LOCAL mcuit, mtexto, mnombre, mtexto1, oQryCompras
LOCAL oGet1, oGet2, oGet3, mdesde := DATE(), oDlg1, aCor, mrta := .f.,;
      oBot1, oBot2, oGet4, mhasta := DATE(), ;
      aEmp := {}, aNov := {}, i, oRep, oFont1, oFont2, oFont3, lIVA := .f.,;
      marchivo, mindice, mgrupo := 1, j,cCodigo:="   ",oQryReten,oQryIva
   
mdesde = DATE()
mhasta = DATE()
DEFINE DIALOG oDlg1 TITLE "Exportar Datos" FROM 03,15 TO 12,55 
   acor := AcepCanc(oDlg1)
   
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 40,12 RIGHT

   @ 05, 50 GET oGet1 VAR mdesde PICTURE "@D" OF oDlg1 PIXEL CENTER
   @ 20, 50 GET oGet2 VAR mhasta PICTURE "@D" OF oDlg1 PIXEL CENTER 
   @ 35, 55 CHECKBOX oGet3 VAR lIVA PROMPT "Libro I.V.A Compras Digital" SIZE 80,12 PIXEL

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Exportar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mrta
   RETURN 
ENDIF     
oQryCompras:= oApp:oServer:Query("SELECT c.*,p.cuit AS cuit,p.nombre AS nombre, "+;
                                 "(SELECT SUM(cr.importe) FROM ge_"+oApp:cId+"compretdet cr "+;
                                 " WHERE cr.tipocomp = c.tipocomp and cr.letra = c.letra and cr.numfac = c.numfac and cr.tipo = 1 ) AS retencion1,"+;
                                 "(SELECT SUM(cr.importe) FROM ge_"+oApp:cId+"compretdet cr "+;
                                 " WHERE cr.tipocomp = c.tipocomp and cr.letra = c.letra and cr.numfac = c.numfac and cr.tipo = 2 ) AS retencion2,"+;
                                 "(SELECT SUM(cr.importe) FROM ge_"+oApp:cId+"compretdet cr "+;
                                 " WHERE cr.tipocomp = c.tipocomp and cr.letra = c.letra and cr.numfac = c.numfac and cr.tipo = 3 ) AS retencion3,"+;
                                 "(SELECT SUM(cr.importe) FROM ge_"+oApp:cId+"compretdet cr "+;
                                 " WHERE cr.tipocomp = c.tipocomp and cr.letra = c.letra and cr.numfac = c.numfac and cr.tipo = 4 ) AS retencion4,"+;
                                 "(SELECT SUM(cr.importe) FROM ge_"+oApp:cId+"compretdet cr "+;
                                 " WHERE cr.tipocomp = c.tipocomp and cr.letra = c.letra and cr.numfac = c.numfac and cr.tipo = 5 ) AS retencion5,"+;
                                 "(SELECT SUM(cr.importe) FROM ge_"+oApp:cId+"compretdet cr "+;
                                 " WHERE cr.tipocomp = c.tipocomp and cr.letra = c.letra and cr.numfac = c.numfac and cr.tipo = 6 ) AS nograbado "+;
                                 "FROM ge_"+oApp:cId+"compras c "+;
                                 "LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = c.codpro "+;
                                 "WHERE c.imputaiva = 1 AND c.nomostrar = 0 AND c.fecing >= " +;
                                  ClipValue2Sql(mdesde) + " AND c.fecing <= "+ ClipValue2Sql(mhasta)+;
                                 " ORDER BY c.fecfac,c.codpro") 

mtexto := ""
mtexto1:= ""
DO WHILE !oQryCompras:Eof()
    mcuit := oQryCompras:cuit
    mcuit := STRTRAN(mcuit,"-","")
    mcuit := STR(VAL(mcuit),20)
    mcuit := STRTRAN(mcuit," ","0")
    mnombre := oQryCompras:nombre
    oQryIva:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"compivadet WHERE tipocomp = "+ClipValue2Sql(oQryCompras:tipocomp)+" AND "+;
                                 " letra = "+ClipValue2Sql(oQryCompras:letra)+" AND "+;
                                 " codpro = "+ClipValue2Sql(oQryCompras:codpro)+"  "+;
                                 " AND letra <> 'B' AND numfac = "+ClipValue2Sql(oQryCompras:numfac))
    DO CASE 
       CASE oQryCompras:tipocomp ="FC" .and. oQryCompras:letra = "A"
          cCodigo:= "001"
       CASE oQryCompras:tipocomp ="FC" .and. oQryCompras:letra = "B"
          cCodigo:= "006"
       CASE oQryCompras:tipocomp ="FC" .and. oQryCompras:letra = "C"
          cCodigo:= "011"
       CASE oQryCompras:tipocomp ="FC" .and. oQryCompras:letra = "M"
          cCodigo:= "051"
       CASE oQryCompras:tipocomp ="NC" .and. oQryCompras:letra = "A"
          cCodigo:= "003"
       CASE oQryCompras:tipocomp ="NC" .and. oQryCompras:letra = "B"
          cCodigo:= "008"
       CASE oQryCompras:tipocomp ="NC" .and. oQryCompras:letra = "C"
          cCodigo:= "013"
       CASE oQryCompras:tipocomp ="ND" .and. oQryCompras:letra = "A"
          cCodigo:= "002"
       CASE oQryCompras:tipocomp ="ND" .and. oQryCompras:letra = "B"
          cCodigo:= "007"
       CASE oQryCompras:tipocomp ="ND" .and. oQryCompras:letra = "C"
          cCodigo:= "012"
       CASE oQryCompras:tipocomp ="FC" .and. oQryCompras:letra = "E"
          cCodigo:= "019"
       CASE oQryCompras:tipocomp ="FC" .and. oQryCompras:letra = "M"
          cCodigo:= "051"
       OTHERWISE 
          oQryCompras:Skip()
          LOOP
    ENDCASE
    mtexto := mtexto +;
              DTOS(oQryCompras:fecfac) + cCodigo + "0" + SUBSTR(oQryCompras:numfac,1,4)  + REPLICATE("0",12)+;
              SUBSTR(oQryCompras:numfac,6,8) + REPLICATE(" ",16)+;
              "80"+;
              mcuit + ;
              LEFT(mnombre,30) +;
              STRTRAN(STR((oQryCompras:Importe)*100,15)," ","0") + ;
              STRTRAN(STR((oQryCompras:nograbado)*100,15)," ","0") + ;
              STRTRAN(STR((oQryCompras:retencion1)*100,15)," ","0") + ;
              STRTRAN(STR((oQryCompras:retencion2)*100,15)," ","0") + ;
              STRTRAN(STR((oQryCompras:retencion3)*100,15)," ","0") + ;
              STRTRAN(STR((oQryCompras:retencion4)*100,15)," ","0") + ;
              REPLICATE("0",15)+;
              STRTRAN(STR((oQryCompras:retencion5)*100,15)," ","0") + ;
              "PES"+;
              "0001000000"+;
              IF(oQryCompras:letra = 'C','0',STR(oQryIva:RecCount(),1))+;
              " "+;
              STRTRAN(STR((oQryCompras:iva)*100,15)," ","0") + ;//REPLICATE("0",15)+;
              REPLICATE("0",15)+;
              REPLICATE("0",11)+;
              REPLICATE(" ",30)+;
              REPLICATE("0",15)+;
              CHR(13) + CHR(10)
    oQryIva:GoTop()
    DO WHILE !oQryIva:eof()
          mtexto1 := mtexto1 +;
                     cCodigo+;
                     "0" + SUBSTR(oQryCompras:numfac,1,4)  +;
                     REPLICATE("0",12)+SUBSTR(oQryCompras:numfac,6,8)+;
                     "80"+;
                     mcuit + ;
                     STRTRAN(STR(oQryIva:neto*100,15)," ","0")+;
                     STRTRAN(STR(oQryIva:codiva,4)," ","0")+;
                     STRTRAN(STR(oQryIva:iva*100,15)," ","0")+;
                     CHR(13) + CHR(10)
          oQryIva:Skip()
    ENDDO
    oQryCompras:Skip()             
ENDDO              
mtexto  := LEFT(mtexto,LEN(mtexto)-2)
mtexto1 := LEFT(mtexto1,LEN(mtexto1)-2)      
IF !lIVA           
  GrabaArchivo("EXPORTA\REGINFO_CV_COMPRAS_CBTE.TXT",mtexto)
  GrabaArchivo("EXPORTA\REGINFO_CV_COMPRAS_ALICUOTAS.TXT",mtexto1)   
  ELSE
  GrabaArchivo("EXPORTA\LIBRO_IVA_DIGITAL_COMPRAS_CBTE.TXT",mtexto)
  GrabaArchivo("EXPORTA\LIBRO_IVA_DIGITAL_COMPRAS_ALICUOTAS.TXT",mtexto1)
ENDIF
Msginfo("Proceso Terminado","Exportacion de compras")
RETURN 

*****************
** Grabar archivo
FUNCTION GrabaArchivo(cArchivo,cDato)
LOCAL Han
Han := LCREAT(cArchivo)
FWRITE(Han,cDato,Len(cDato))
LCLOSE(Han)
RETURN nil 