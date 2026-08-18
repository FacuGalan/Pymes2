-- =====================================================================
-- Replicación Venta -> Compra para clientes franquicia
-- =====================================================================

-- Configuración: para cada cliente del sistema principal que sea franquicia,
-- a qué punto destino se replica y bajo qué proveedor queda registrada la compra.
CREATE TABLE IF NOT EXISTS ma_config (
  id              INT(3)      NOT NULL AUTO_INCREMENT,
  punto_origen    VARCHAR(6)  NOT NULL,                 -- ma_puntos.punto del sistema que vende (ej '000014')
  cliente_origen  INT(6)      NOT NULL,                 -- CODIGO en ge_<origen>clientes (la franquicia como cliente)
  punto_destino   VARCHAR(6)  NOT NULL,                 -- ma_puntos.punto del sistema franquicia (ej '000015')
  codpro_destino  INT(6)      NOT NULL,                 -- CODIGO en ge_<destino>provee (proveedor "Manager")
  activo          TINYINT(1)  NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_origen (punto_origen, cliente_origen)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Log de replicaciones (pendientes / errores / OK)
CREATE TABLE IF NOT EXISTS ma_replica_log (
  id              INT(10)     NOT NULL AUTO_INCREMENT,
  fecha           DATETIME    NOT NULL,
  punto_origen    VARCHAR(6)  NOT NULL,
  punto_destino   VARCHAR(6)  NOT NULL,
  codpro_destino  INT(6)      NOT NULL,
  cliente_origen  INT(6)      NOT NULL,
  tipocomp        VARCHAR(2)  NOT NULL,
  letra           VARCHAR(1)  NOT NULL,
  numfac          VARCHAR(13) NOT NULL,
  estado          VARCHAR(1)  NOT NULL DEFAULT 'P',     -- P=Pendiente, O=Ok, E=Error
  intentos        INT(3)      NOT NULL DEFAULT 0,
  mensaje         VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY k_estado (estado),
  KEY k_doc (punto_origen,tipocomp,letra,numfac)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
