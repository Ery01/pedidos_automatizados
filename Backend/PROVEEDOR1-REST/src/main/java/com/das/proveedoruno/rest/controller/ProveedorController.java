package com.das.proveedoruno.rest.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.das.proveedoruno.rest.repository.ProveedorRepository;

@RestController
@RequestMapping(path="/proveedor", produces= {MediaType.APPLICATION_JSON_VALUE})
public class ProveedorController {
	
	@Autowired
	ProveedorRepository repository; 
}
