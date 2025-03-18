package com.das.rest.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.das.rest.repository.SupermercadoRepository;
import com.fasterxml.jackson.databind.JsonNode;

@RestController
@RequestMapping(value = "/super", produces = MediaType.APPLICATION_JSON_VALUE)
public class SupermercadoController {
	
	@Autowired
	private SupermercadoRepository repository;
	
	@PostMapping(
			path="/login",
			consumes= {MediaType.APPLICATION_JSON_VALUE},
			produces= {MediaType.APPLICATION_JSON_VALUE})
	public ResponseEntity<String> getLogin (@RequestBody JsonNode json) {
		try {
			String jsonConfig = repository.getLogin(json);
			
			return new ResponseEntity<>(jsonConfig,HttpStatus.OK);
		} catch (Exception e) {
			System.out.println("Exception: " + e.getMessage());
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
	}
}
