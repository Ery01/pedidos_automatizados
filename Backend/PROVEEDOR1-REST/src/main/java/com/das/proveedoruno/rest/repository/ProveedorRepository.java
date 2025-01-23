package com.das.proveedoruno.rest.repository;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import com.fasterxml.jackson.databind.JsonNode;

@Repository
public class ProveedorRepository {

	@Autowired
	private JdbcTemplate jdbcTmp;

	@SuppressWarnings("unchecked")
	public String getConfiguracion() {
		try {
			SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmp).withProcedureName("OBTENER_CONFIGURACION")
					.withSchemaName("dbo");

			SqlParameterSource in = new MapSqlParameterSource();
			Map<String, Object> out = jdbcCall.execute(in);

			List<Map<String, Object>> resultSet = (List<Map<String, Object>>) out.get("#result-set-1");

			if (resultSet != null && !resultSet.isEmpty()) {
				Map<String, Object> firstRow = resultSet.get(0);
				return (String) firstRow.get("Configuracion");
			} else {
				throw new RuntimeException("Error al recuperar la CONFIGURACION");
			}
		} catch (Exception e) {
			throw new RuntimeException("Error ejecutando el procedimiento almacenado: OBTENER_CONFIGURACION", e);
		}

	}

	@SuppressWarnings("unchecked")
	public String getProductos() {
		try {
			SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmp).withProcedureName("OBTENER_PRODUCTOS")
					.withSchemaName("dbo");

			SqlParameterSource in = new MapSqlParameterSource();
			Map<String, Object> out = jdbcCall.execute(in);

			List<Map<String, Object>> resultSet = (List<Map<String, Object>>) out.get("#result-set-1");

			if (resultSet != null && !resultSet.isEmpty()) {
				Map<String, Object> firstRow = resultSet.get(0);
				return (String) firstRow.get("Productos");
			} else {
				throw new RuntimeException("Error al recuperar los PRODUCTOS");
			}
		} catch (Exception e) {
			throw new RuntimeException("Error ejecutando el procedimiento almacenado: OBTENER_PRODUCTOS", e);
		}
	}

	@SuppressWarnings("unchecked")
	public String getEscala() {
		try {
			SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmp).withProcedureName("OBTENER_ESCALA")
					.withSchemaName("dbo");

			SqlParameterSource in = new MapSqlParameterSource();
			Map<String, Object> out = jdbcCall.execute(in);

			List<Map<String, Object>> resultSet = (List<Map<String, Object>>) out.get("#result-set-1");

			if (resultSet != null && !resultSet.isEmpty()) {
				Map<String, Object> firstRow = resultSet.get(0);
				return (String) firstRow.get("Escala");
			} else {
				throw new RuntimeException("Error al recuperar la ESCALA");
			}
		} catch (Exception e) {
			throw new RuntimeException("Error ejecutando el procedimiento almacenado: OBTENER_ESCALA", e);
		}
	}

	@SuppressWarnings("unchecked")
	public String getPedido(JsonNode pedidoJson) {
		try {
			String jsonString = pedidoJson.toString();
			SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmp);

			SqlParameterSource in = new MapSqlParameterSource().addValue("json", jsonString);

			Map<String, Object> out = jdbcCall.withProcedureName("OBTENER_PEDIDO").withSchemaName("dbo").execute(in);
			List<Map<String, Object>> resultSet = (List<Map<String, Object>>) out.get("#result-set-1");

			if (resultSet != null && !resultSet.isEmpty()) {
				Map<String, Object> firstRow = resultSet.get(0);
				return (String) firstRow.get("Pedido");
			} else {
				throw new RuntimeException("Error al recuperar el Pedido.");
			}
		} catch (Exception e) {
			throw new RuntimeException("Error ejecutando el procedimiento almacenado: OBTENER_PRODUCTOS", e);
		}
	}

	@SuppressWarnings("unchecked")
	public String getPedidos() {
		SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmp).withProcedureName("OBTENER_PEDIDOS")
				.withSchemaName("dbo");

		SqlParameterSource in = new MapSqlParameterSource();
		Map<String, Object> out = jdbcCall.execute(in);

		List<Map<String, Object>> resultSet = (List<Map<String, Object>>) out.get("#result-set-1");

		if (resultSet != null && !resultSet.isEmpty()) {
			Map<String, Object> firstRow = resultSet.get(0);
			return (String) firstRow.get("Pedidos");
		} else {
			throw new RuntimeException("Error ejecutando el procedimiento almacenado: OBTENER_PEDIDOS.");
		}
	}

	@SuppressWarnings("unchecked")
	public String cancelarPedido(String jsonString) {
		try {
			SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmp);

			SqlParameterSource in = new MapSqlParameterSource().addValue("json", jsonString);

			Map<String, Object> out = jdbcCall.withProcedureName("CANCELAR_PEDIDO").withSchemaName("dbo").execute(in);
			List<Map<String, Object>> resultSet = (List<Map<String, Object>>) out.get("#result-set-1");

			if (resultSet != null && !resultSet.isEmpty()) {
				Map<String, Object> firstRow = resultSet.get(0);
				return (String) firstRow.get("PedidoCancelado");
			} else {
				throw new RuntimeException("No se devolvió el pedido cancelado.");
			}
		} catch (Exception e) {
			throw new RuntimeException("Error ejecutando el procedimiento almacenado: CANCELAR_PEDIDO", e);
		}
	}

	@SuppressWarnings("unchecked")
	public String insertarPedido(String jsonString) {
		try {
			SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmp);

			SqlParameterSource in = new MapSqlParameterSource().addValue("json", jsonString);

			Map<String, Object> out = jdbcCall.withProcedureName("INSERTAR_DETALLE").withSchemaName("dbo").execute(in);
			List<Map<String, Object>> resultSet = (List<Map<String, Object>>) out.get("#result-set-1");

			if (resultSet != null && !resultSet.isEmpty()) {
				SimpleJdbcCall jdbcCallpedido = new SimpleJdbcCall(jdbcTmp);
				SqlParameterSource inPedido = new MapSqlParameterSource();

				Map<String, Object> outPedido = jdbcCallpedido.withProcedureName("OBTENER_DETALLES_ULTIMO_PEDIDO")
						.withSchemaName("dbo").execute(inPedido);
				List<Map<String, Object>> resultSetPedido = (List<Map<String, Object>>) outPedido.get("#result-set-1");
				if (resultSetPedido != null && !resultSetPedido.isEmpty()) {
					Map<String, Object> firstRow = resultSetPedido.get(0);
					return (String) firstRow.get("Resultado");
				} else {
					throw new RuntimeException("No se insertó el Pedido.");
				}
			} else {
				throw new RuntimeException("No se devolvió el Pedido.");
			}
		} catch (Exception e) {
			throw new RuntimeException("Error ejecutando el procedimiento almacenado", e);
		}
	}
	
	
}
