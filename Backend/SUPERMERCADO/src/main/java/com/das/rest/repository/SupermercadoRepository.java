package com.das.rest.repository;

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
public class SupermercadoRepository {
	
	@Autowired
	private JdbcTemplate jdbcTmpl;
	
	@SuppressWarnings("unchecked")
	public String getLogin(JsonNode json) {
		try {
			String jsonString = json.toString();
			
			SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTmpl);
			SqlParameterSource in = new MapSqlParameterSource().addValue("json", jsonString);
			Map<String,Object> out = jdbcCall.withProcedureName("LOGIN_USUARIO")
					.withSchemaName("dbo")
					.execute(in);
			List<Map<String,Object>> rs = (List<Map<String, Object>>) out.get("#result-set-1");
			
			if (rs != null && !rs.isEmpty()) {
				Map<String,Object> firstRow = rs.get(0);
				
				return (String) firstRow.get("ResultadoLogin");
			} else {
				throw new RuntimeException("El usuario no existe");
			}
		} catch (Exception e) {
			throw new RuntimeException("Error al ejecutar el procedimiento LOGIN_USUARIO", e);
		}
	} 
}
