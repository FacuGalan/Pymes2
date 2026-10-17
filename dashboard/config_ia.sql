-- Configuracion central del asistente de IA del Tablero de control (DASHWEB.PRG).
-- Correr UNA sola vez en la base bcn_config del servidor (la misma que tiene
-- config_clientes). La clave no queda en las PCs ni en las bases de los clientes.
--
-- proveedor        : GROQ (hoy). Preparado para CLAUDE (ver el plan).
-- modelo           : modelo que arma la consulta.
-- modelo_redaccion : modelo que redacta la respuesta (vacio = el mismo).
-- api_key          : clave del servicio.
-- url              : vacio = la del proveedor. Solo para pruebas.
-- activo           : se usa la ultima fila activa.

CREATE TABLE IF NOT EXISTS config_ia (
  id               INT(10)      NOT NULL AUTO_INCREMENT,
  proveedor        VARCHAR(20)  NOT NULL DEFAULT 'GROQ',
  modelo           VARCHAR(80)  NOT NULL DEFAULT 'openai/gpt-oss-120b',
  modelo_redaccion VARCHAR(80)  NOT NULL DEFAULT '',
  api_key          VARCHAR(250) NOT NULL DEFAULT '',
  url              VARCHAR(250) NOT NULL DEFAULT '',
  activo           TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Reemplazar PEGAR_ACA_LA_CLAVE por la clave de Groq (console.groq.com -> API Keys)
INSERT INTO config_ia (proveedor, modelo, modelo_redaccion, api_key)
VALUES ('GROQ', 'openai/gpt-oss-120b', 'openai/gpt-oss-120b', 'PEGAR_ACA_LA_CLAVE');
