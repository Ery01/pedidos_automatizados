package com.daos;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import ar.edu.ubp.das.db.Dao;

public class MSSQLPedidoDao extends Dao<String, String, String>{

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
	public String make(ResultSet resultSet) throws SQLException {
		return resultSet.getString("Pedido");
	}

	@Override
	public List<String> select(String json) throws SQLException {
		try {
			this.connect();
			this.setProcedure("OBTENER_PEDIDO(?)");
			this.setParameter(1,json);
			return this.executeQuery();
		}
		finally {
			this.close();
		}
	}

	@Override
	public String update(String arg0) throws SQLException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public boolean valid(String arg0) throws SQLException {
		// TODO Auto-generated method stub
		return false;
	}

}
