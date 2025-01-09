package com.das.proveedoruno.rest.repository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ProveedorRepository {
	
	@Autowired
	private JdbcTemplate jdbcTmp; 
}
