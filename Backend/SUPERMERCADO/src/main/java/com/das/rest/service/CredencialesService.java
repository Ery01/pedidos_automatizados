package com.das.rest.service;

import org.springframework.stereotype.Service;

import com.das.rest.model.Credencial;
import com.das.rest.repository.CredencialesRepository;

@Service
public class CredencialesService {
	
	private final CredencialesRepository credencialesRepository;

    public CredencialesService(CredencialesRepository credencialesRepository) {
        this.credencialesRepository = credencialesRepository;
    }

    public Credencial obtenerCredenciales(String idProveedor) {
        return credencialesRepository.obtenerCredenciales(idProveedor);
    }
}
