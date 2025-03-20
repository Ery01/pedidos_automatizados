package com.das.rest.repository;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.stereotype.Repository;

import com.das.rest.model.Credencial;
import com.google.gson.Gson;

@Repository
public class CredencialesRepository {
	private final NamedParameterJdbcTemplate namedParameterJdbcTemplate;
    private final Gson gson;

    public CredencialesRepository(NamedParameterJdbcTemplate namedParameterJdbcTemplate, Gson gson) {
        this.namedParameterJdbcTemplate = namedParameterJdbcTemplate;
        this.gson = gson;
    }

    public Credencial obtenerCredenciales(String idProveedor) {
        String sql = "EXEC OBTENER_CREDENCIALES :json";
        SqlParameterSource namedParameters = new MapSqlParameterSource().addValue("json", idProveedor);

        return namedParameterJdbcTemplate.queryForObject(sql, namedParameters, (rs, rowNum) -> {
            String credencialesJson = rs.getString("credenciales");
            return gson.fromJson(credencialesJson, Credencial.class);
        });
    }
}
