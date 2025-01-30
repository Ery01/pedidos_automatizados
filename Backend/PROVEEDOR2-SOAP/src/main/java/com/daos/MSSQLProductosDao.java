package com.daos;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import ar.edu.ubp.das.db.Dao;

public class MSSQLProductosDao extends Dao<String, String, String>{

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
		// TODO Auto-generated method stub
		return resultSet.getString("Productos");
	}

	@Override
	public List<String> select(String arg0) throws SQLException {
		this.connect();
		this.setProcedure("OBTENER_PRODUCTOS");
		return this.executeQuery();
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
