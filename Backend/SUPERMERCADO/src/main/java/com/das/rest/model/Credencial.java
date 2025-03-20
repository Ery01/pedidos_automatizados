package com.das.rest.model;

import com.google.gson.annotations.SerializedName;

public class Credencial {
	
	@SerializedName("nombre_url")
	private String nombreUrl;
	
	@SerializedName("token")
	private String token;
	
	public Credencial(String nombreUrl, String token) {
		this.setNombreUrl(nombreUrl);
		this.setToken(token);
	}

	public String getNombreUrl() {
		return nombreUrl;
	}

	public void setNombreUrl(String nombreUrl) {
		this.nombreUrl = nombreUrl;
	}

	public String getToken() {
		return token;
	}

	public void setToken(String token) {
		this.token = token;
	}	
}
