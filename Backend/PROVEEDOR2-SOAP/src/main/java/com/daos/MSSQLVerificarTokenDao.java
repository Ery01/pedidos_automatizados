package com.daos;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import ar.edu.ubp.das.db.Dao;

public class MSSQLVerificarTokenDao extends Dao<String, String, String>{

	@Override
	public String delete(String arg0) throws SQLException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public String insert(String arg0) throws SQLException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public String make(ResultSet result) throws SQLException {
		// TODO Auto-generated method stub
		return result.getString("token");
	}

	@Override
	public List<String> select(String token) throws SQLException {
		try {
            this.connect();
            this.setProcedure("VERIFICAR_TOKEN(?)");
            this.setParameter(1, token);
            return this.executeQuery();
        } finally {
            this.close();
        }
	}

	@Override
	public String update(String arg0) throws SQLException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public boolean valid(String token) throws SQLException {
		List<String> tokens = this.select(token);
        System.out.println("Tokens: " + tokens); // Imprimir los tokens obtenidos
        return !tokens.isEmpty(); // Devuelve true si el token está en la lista
	}

}
