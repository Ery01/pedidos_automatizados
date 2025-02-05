package com.das.proveedoruno.rest.controller;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.das.proveedoruno.rest.repository.ProveedorRepository;
import com.fasterxml.jackson.databind.JsonNode;

@RestController
@RequestMapping(path="/proveedor", produces= {MediaType.APPLICATION_JSON_VALUE})
public class ProveedorController {
	
	@Autowired
	ProveedorRepository repository; 
	
	private static final Logger logger = LoggerFactory.getLogger(ProveedorController.class);
	
	@GetMapping(path = "/configuracion",
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
	
	@GetMapping(path = "/obtenerProductos",
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
	
	@GetMapping(path = "/obtenerEscala",
            produces = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<String> getEscala() {
		try {
			String jsonConfig = repository.getEscala();
			logger.info("Se ejecuto exitosamente: /obtenerEscala");
            return new ResponseEntity<>(jsonConfig, HttpStatus.OK);
		} catch (Exception e) {
			logger.error("Error al ejecutar /obtenerEscala: {}", e.getMessage(), e);
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		}
	}
	
	@GetMapping(path = "/obtenerPedido",
            produces = {MediaType.APPLICATION_JSON_VALUE},
            consumes = {MediaType.APPLICATION_JSON_VALUE})
	public ResponseEntity<String> getPedido(@RequestBody JsonNode json) {
		try {
			String jsonConfig = repository.getPedido(json);
			logger.info("Se ejecuto exitosamente: /obtenerPedido{json}");
            return new ResponseEntity<>(jsonConfig, HttpStatus.OK);
		} catch (Exception e) {
			logger.error("Error al ejecutar /obtenerPedido{json}:{}", e.getMessage(), e);
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		}
	}
	
	@GetMapping(path = "/obtenerPedidos",
            produces = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<String> getPedidos() {
		try {
			String jsonConfig = repository.getPedidos();
			logger.info("Se ejecuto exitosamente: /obtenerPedidos");
            return new ResponseEntity<>(jsonConfig, HttpStatus.OK);
		} catch (Exception e) {
			logger.error("Error al ejecutar /obtenerPedidos: {}", e.getMessage(), e);
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		}
	}
	
	@PostMapping(path = "/cancelarPedido",
            produces = {MediaType.APPLICATION_JSON_VALUE},
            consumes = {MediaType.APPLICATION_JSON_VALUE})
	public ResponseEntity<String> cancelarPedido(@RequestBody JsonNode json) {
		try {
			String jsonConfig = repository.cancelarPedido(json);
			logger.info("Se ejecuto exitosamente: /cancelarPedido{json}");
            return new ResponseEntity<>(jsonConfig, HttpStatus.OK);
		} catch (Exception e) {
			logger.error("Error al ejecutar /cancelarPedido{json}:{}", e.getMessage(), e);
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		}
	}
	
	@PostMapping(path = "/insertarPedido",
	        produces = {MediaType.APPLICATION_JSON_VALUE},
	        consumes = {MediaType.APPLICATION_JSON_VALUE})
	public ResponseEntity<String> insertarPedido(@RequestBody JsonNode json) {
	    try {
	        int idCliente = json.get("id_cliente").asInt(); 

	        String codigoSeguimiento = repository.insertarPedido(idCliente, json.get("detalles"));

	        logger.info("Se ejecuto exitosamente: /insertarPedido Codigo de Seguimiento: {}", codigoSeguimiento);
	        return new ResponseEntity<>(codigoSeguimiento, HttpStatus.OK);

	    } catch (Exception e) {
	        logger.error("Error al ejecutar /insertarPedido: {}", e.getMessage(), e);
	        return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
	    }
	}
}
