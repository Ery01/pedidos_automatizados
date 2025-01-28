package com.das.proveedoruno.rest.interceptor;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import com.das.proveedoruno.rest.controller.ProveedorController;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class TokenInterceptor implements HandlerInterceptor{

	@Value("${external.api.token}")
    private String externalToken;
	
	private static final Logger logger = LoggerFactory.getLogger(ProveedorController.class);
	
	@Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String token = request.getHeader("Authorization");
        if (token == null || !isTokenValid(token)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Token VACIO o INVALIDO.");
            logger.info("Se envio un TOKEN vacio o invalido. Acceso denegado");
            return false;
        }
        return true;
    }

    private boolean isTokenValid(String token) {
        return ("Bearer " + externalToken).equals(token);
    }
	
}
