/*
 * franqui.prg
 * --------------------------------------------------------------------
 * Replicación de ventas a clientes franquicia como compras en el
 * sistema de la franquicia (mismo servidor MySQL, distinto prefijo).
 *
 * Tablas requeridas (ver franqui_schema.sql):
 *   - ma_config        (configuración por cliente franquicia)
 *   - ma_replica_log   (log de pendientes / errores)
 *
 * Uso desde ventas.prg, inmediatamente DESPUES del CommitTransaction
 * de la grabación de la venta:
 *
 *     IF FranquiActivo()
 *        ReplicarCompraFranquicia( cTipoDoc, LEFT(cNumComp,1), ;
 *                                  RIGHT(cNumComp,13), nCliente, ;
 *                                  oGet[1]:value, dFecVtoC )
 *     ENDIF
 *
 * Sólo se replican comprobantes FC, ND y NC.
 * --------------------------------------------------------------------
 */

#include "FiveWin.ch"

/*STATIC lFranquiChecked := .F.
STATIC lFranquiOn      := .F.*/
MEMVAR oApp

//---------------------------------------------------------------------
// Devuelve .T. si existe ma_config en la base (la simple existencia
// implica que el módulo de franquicias está habilitado).
//---------------------------------------------------------------------
/*FUNCTION FranquiActivo()
   LOCAL oQry
   IF lFranquiChecked
      RETURN lFranquiOn
   ENDIF
   TRY
      oQry := oApp:oServer:Query( "SELECT 1 FROM ma_config LIMIT 1" )
      lFranquiOn := ( oQry != NIL .AND. oQry:nError == 0 )
   CATCH
      lFranquiOn := .F.
   END
   lFranquiChecked := .T.
RETURN lFranquiOn*/

//---------------------------------------------------------------------
// Punto de entrada: replica una venta del cliente principal como
// compra en el sistema de la franquicia. NO bloquea la venta: ante
// cualquier error registra el problema en ma_replica_log y avisa.
//---------------------------------------------------------------------
/*FUNCTION ReplicarCompraFranquicia( cTipoDoc, cLetra, cNumFac, nCliente, dFecha, dFecVto )
   LOCAL oCfg, cMsg, lOk

   // Sólo FC, ND y NC
   IF !( cTipoDoc $ "FC#ND#NC" )
      RETURN .T.
   ENDIF

   oCfg := oApp:oServer:Query( "SELECT * FROM ma_config "+;
            "WHERE punto_origen = " + ClipValue2Sql( oApp:cId ) + " "+;
            "AND cliente_origen = " + ClipValue2Sql( nCliente ) + " "+;
            "AND activo = 1" )

   IF oCfg:Eof()
      RETURN .T.   // El cliente no es franquicia configurada
   ENDIF

   // Registro previo en log como Pendiente (para no perderlo si revienta)
   oApp:oServer:Execute( "INSERT INTO ma_replica_log "+;
      "(fecha,punto_origen,punto_destino,codpro_destino,cliente_origen,"+;
      " tipocomp,letra,numfac,estado,intentos,mensaje) VALUES ("+;
      "NOW(),"+ClipValue2Sql(oApp:cId)+","+ClipValue2Sql(oCfg:punto_destino)+","+;
      ClipValue2Sql(oCfg:codpro_destino)+","+ClipValue2Sql(nCliente)+","+;
      ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumFac)+","+;
      "'P',0,NULL)" )

   lOk := .F.
   cMsg := ""
   TRY
      EjecutarReplicaCompra( oApp:cId, oCfg:punto_destino, oCfg:codpro_destino,;
                             cTipoDoc, cLetra, cNumFac, dFecha, dFecVto )
      lOk := .T.
   CATCH oErr
      cMsg := IF( ValType(oErr)=="O", oErr:description, "Error desconocido" )
   END

   IF lOk
      oApp:oServer:Execute( "UPDATE ma_replica_log SET estado='O', intentos=intentos+1, mensaje=NULL "+;
         "WHERE punto_origen="+ClipValue2Sql(oApp:cId)+" "+;
         "AND tipocomp="+ClipValue2Sql(cTipoDoc)+" "+;
         "AND letra="+ClipValue2Sql(cLetra)+" "+;
         "AND numfac="+ClipValue2Sql(cNumFac)+" "+;
         "AND estado<>'O'" )
   ELSE
      oApp:oServer:Execute( "UPDATE ma_replica_log SET estado='E', intentos=intentos+1, mensaje="+ClipValue2Sql(cMsg)+" "+;
         "WHERE punto_origen="+ClipValue2Sql(oApp:cId)+" "+;
         "AND tipocomp="+ClipValue2Sql(cTipoDoc)+" "+;
         "AND letra="+ClipValue2Sql(cLetra)+" "+;
         "AND numfac="+ClipValue2Sql(cNumFac)+" "+;
         "AND estado='P'" )
      MsgAlert( "La replicación de la compra a la franquicia no se pudo procesar."+CRLF+;
                "Comprobante: "+cTipoDoc+" "+cLetra+" "+cNumFac+CRLF+;
                "Detalle: "+cMsg+CRLF+CRLF+;
                "Quedó pendiente en ma_replica_log; podrá reprocesarse luego.","Atención" )
   ENDIF

RETURN lOk*/

//---------------------------------------------------------------------
// Hace todo el trabajo SQL dentro de una transacción dedicada.
// Idempotente: si el comprobante ya existe en destino, no duplica.
//---------------------------------------------------------------------
FUNCTION EjecutarReplicaCompra(cTipoDoc, cLetra, cNumFac, nCliente, dFecha )
   LOCAL oQ, nNeto, nIva, nImporte, nSigno, oCfg, cIdOrigen, cIdDestino, nCodPro, oErr
   
   IF !oApp:oServer:TableExist('ma_config')
      RETURN .t.
   ENDIF   
   oCfg := oApp:oServer:Query( "SELECT * FROM ma_config "+;
            "WHERE punto_origen = " + ClipValue2Sql( oApp:cId ) + " "+;
            "AND cliente_origen = " + ClipValue2Sql( nCliente ) + " "+;
            "AND activo = 1" )
   IF oCfg:Eof()
      RETURN .T.   // El cliente no es franquicia configurada
   ENDIF
   // ¿Ya existe?
   nCodPro    := oCfg:codpro_destino
   cIdDestino := oCfg:punto_destino
   oQ := oApp:oServer:Query( "SELECT 1 FROM ge_"+cIdDestino+"compras "+;
            "WHERE codpro="+ClipValue2Sql(nCodPro)+" "+;
            "AND tipocomp="+ClipValue2Sql(cTipoDoc)+" "+;
            "AND letra="+ClipValue2Sql(cLetra)+" "+;
            "AND numfac="+ClipValue2Sql(cNumFac) )
   IF !oQ:Eof()
      RETURN .T.   // Ya replicado
   ENDIF
   cIdOrigen  := oApp:cId   
   // Totales tomados del encabezado de la venta original
   oQ := oApp:oServer:Query( "SELECT neto,iva,importe FROM ge_"+cIdOrigen+"ventas_encab "+;
            "WHERE ticomp="+ClipValue2Sql(cTipoDoc)+" "+;
            "AND letra="+ClipValue2Sql(cLetra)+" "+;
            "AND numcomp="+ClipValue2Sql(cNumFac) )
   IF oQ:Eof()
      MsgInfo( "No se encontró la venta original "+cTipoDoc+cLetra+cNumFac,"Error" )
   ENDIF
   nNeto    := oQ:neto
   nIva     := oQ:iva
   nImporte := oQ:importe
   nSigno   := IF( cTipoDoc == "NC", -1, 1 )

   oApp:oServer:BeginTransaction()
   TRY
      // 1) Cabecera ge_<destino>compras
      oApp:oServer:Execute( "INSERT INTO ge_"+cIdDestino+"compras "+;
         "(codpro,tipocomp,letra,numfac,fecfac,fecvto,fecing,nograbado,neto,iva,importe,"+;
         " codcue,estado,observa,saldo,imputaiva,usuario,nomostrar,fecmod,ip,lnocomputaiva) VALUES ("+;
         ClipValue2Sql(nCodPro)+","+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(cLetra)+","+;
         ClipValue2Sql(cNumFac)+","+ClipValue2Sql(dFecha)+","+ClipValue2Sql(dFecha)+",CURDATE(),"+;
         "0,"+ClipValue2Sql(nNeto)+","+ClipValue2Sql(nIva)+","+ClipValue2Sql(nImporte)+","+;
         "1,'A','Auto franquicia',"+ClipValue2Sql(nImporte)+","+ClipValue2Sql(cLetra<>'X')+",'AUTO',0,CURDATE(),"+;
         ClipValue2Sql(oApp:cIp)+","+ClipValue2Sql(cLetra<>'X')+")" )

      // 2) Renglones ge_<destino>compradet desde ventas_det del origen
      //    El RENGLON se genera con una variable de sesión para no depender del temporal.
      oApp:oServer:Execute( "SET @rg := 0" )
      oApp:oServer:Execute( "INSERT INTO ge_"+cIdDestino+"compradet "+;
         "(codpro,tipocomp,letra,numfac,renglon,codart,cantidad,punit,neto,iva,codiva,"+;
         " desc1,desc2,desc3,desc4,desc5,siniva) "+;
         "SELECT "+ClipValue2Sql(nCodPro)+","+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(cLetra)+","+;
         ClipValue2Sql(cNumFac)+",(@rg := @rg + 1),"+;
         " v.codart, v.cantidad, v.punit, v.neto, v.iva, v.codiva, "+;
         " 0,0,0,0,0,0 "+;
         "FROM ge_"+cIdOrigen+"ventas_det v "+;
         "WHERE v.nrofac="+ClipValue2Sql(cTipoDoc+cLetra+cNumFac)+" "+;
         "AND v.codcli="+;
            "(SELECT codcli FROM ge_"+cIdOrigen+"ventas_encab "+;
             "WHERE ticomp="+ClipValue2Sql(cTipoDoc)+" "+;
             "AND letra="+ClipValue2Sql(cLetra)+" "+;
             "AND numcomp="+ClipValue2Sql(cNumFac)+" LIMIT 1)" )

      // 3) IVA discriminado
      oApp:oServer:Execute( "INSERT INTO ge_"+cIdDestino+"compivadet "+;
         "(codpro,tipocomp,letra,numfac,codiva,neto,iva) "+;
         "SELECT "+ClipValue2Sql(nCodPro)+","+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(cLetra)+","+;
         ClipValue2Sql(cNumFac)+", codiva, neto, iva "+;
         "FROM ge_"+cIdOrigen+"ventivadet "+;
         "WHERE tipocomp="+ClipValue2Sql(cTipoDoc)+" "+;
         "AND letra="+ClipValue2Sql(cLetra)+" "+;
         "AND numfac="+ClipValue2Sql(cNumFac) )

      // 4) Stock: NC resta, FC/ND suman
      oApp:oServer:Execute( "UPDATE ge_"+cIdDestino+"articu a "+;
         "INNER JOIN (SELECT codart, SUM(cantidad) AS c FROM ge_"+cIdDestino+"compradet "+;
         "            WHERE codpro="+ClipValue2Sql(nCodPro)+" "+;
         "            AND tipocomp="+ClipValue2Sql(cTipoDoc)+" "+;
         "            AND letra="+ClipValue2Sql(cLetra)+" "+;
         "            AND numfac="+ClipValue2Sql(cNumFac)+" "+;
         "            GROUP BY codart) x ON a.codigo = x.codart "+;
         "SET a.stockact = a.stockact + x.c * "+ Str(nSigno,2) +", "+;
         "    a.fecultcom = "+ClipValue2Sql(dFecha) )

      // 5) Saldo del proveedor en la franquicia
      /*oApp:oServer:Execute( "UPDATE ge_"+cIdDestino+"provee "+;
         "SET saldo = saldo + ("+ClipValue2Sql(nImporte)+" * "+Str(nSigno,2)+") "+;
         "WHERE codigo="+ClipValue2Sql(nCodPro) )*/

      oApp:oServer:CommitTransaction()
   CATCH oErr
      oApp:oServer:RollBackTransaction()
      MsgInfo(oErr:description,"Error al Replicar")
      //_ThrowReplica( IF( ValType(oErr)=="O", oErr:description, "Error SQL en replica" ) )
   END

RETURN .T.

/*STATIC FUNCTION _ThrowReplica( cMsg )
   LOCAL oErr := ErrorNew()
   oErr:description := cMsg
   Eval( ErrorBlock(), oErr )
RETURN NIL*/

//---------------------------------------------------------------------
// Reproceso de pendientes / errores. Llamar manualmente desde un menú.
//---------------------------------------------------------------------
/*FUNCTION ReprocesarReplicas()
   LOCAL oQry, nOk := 0, nErr := 0, oCfg, dFecha, dFecVto

   IF !FranquiActivo()
      MsgAlert( "Módulo de franquicias no instalado.", "Atención" )
      RETURN NIL
   ENDIF

   oQry := oApp:oServer:Query( "SELECT * FROM ma_replica_log "+;
            "WHERE estado IN ('P','E') ORDER BY id" )

   oQry:GoTop()
   DO WHILE !oQry:Eof()
      // Releer la venta original para fecha y vto
      WITH OBJECT oApp:oServer:Query( "SELECT fecha, fecvto FROM ge_"+oQry:punto_origen+"ventas_encab "+;
               "WHERE ticomp="+ClipValue2Sql(oQry:tipocomp)+" "+;
               "AND letra="+ClipValue2Sql(oQry:letra)+" "+;
               "AND numcomp="+ClipValue2Sql(oQry:numfac) )
         IF !:Eof()
            dFecha  := :fecha
            dFecVto := :fecvto
         ELSE
            dFecha  := DATE()
            dFecVto := DATE()
         ENDIF
      END
      TRY
         EjecutarReplicaCompra( oQry:punto_origen, oQry:punto_destino, oQry:codpro_destino, ;
                                oQry:tipocomp, oQry:letra, oQry:numfac, dFecha, dFecVto )
         oApp:oServer:Execute( "UPDATE ma_replica_log SET estado='O', intentos=intentos+1, mensaje=NULL "+;
                               "WHERE id="+ClipValue2Sql(oQry:id) )
         nOk++
      CATCH oErr
         oApp:oServer:Execute( "UPDATE ma_replica_log SET estado='E', intentos=intentos+1, "+;
            "mensaje="+ClipValue2Sql( IF(ValType(oErr)=="O",oErr:description,"Error") )+" "+;
            "WHERE id="+ClipValue2Sql(oQry:id) )
         nErr++
      END
      oQry:Skip()
   ENDDO

   MsgInfo( "Reproceso terminado."+CRLF+"OK: "+Str(nOk,4)+CRLF+"Errores: "+Str(nErr,4), "Franquicias" )
RETURN NIL*/
