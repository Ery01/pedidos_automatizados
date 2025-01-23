package com.das.proveedoruno.rest.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import com.das.proveedoruno.rest.repository.ProveedorRepository;

@RestController
@RequestMapping(path="/proveedor", produces= {MediaType.APPLICATION_JSON_VALUE})
public class ProveedorController {
	
	@Autowired
	ProveedorRepository repository; 
	
	private static final Logger logger = LoggerFactory.getLogger(ProveedorController.class);
	
	@PostMapping(path = "/configuracion",
            produces = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<String> getConfiguracion() {
		try {
			String jsonConfig = repository.getConfiguracion();
			logger.info("Se ejecuto exitosamente: /Configuracion");
            return new ResponseEntity<>(jsonConfig, HttpStatus.OK);
		} catch (Exception e) {
			logger.error("Error al ejecutar /Configuracion: {}", e.getMessage(), e);
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		}
	}
	
	@PostMapping(path = "/obtenerProductos",
            produces = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<String> getProductos() {
		try {
			String jsonConfig = repository.getProductos();
			logger.info("Se ejecuto exitosamente: /obtenerProductos");
            return new ResponseEntity<>(jsonConfig, HttpStatus.OK);
		} catch (Exception e) {
			logger.error("Error al ejecutar /obtenerProductos: {}", e.getMessage(), e);
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		}
	}
}
