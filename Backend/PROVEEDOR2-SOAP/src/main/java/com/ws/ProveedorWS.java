package com.ws;

import java.sql.SQLException;
import java.util.List;

import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebResult;
import javax.jws.WebService;
import javax.naming.AuthenticationException;

import org.apache.cxf.interceptor.Fault;

import ar.edu.ubp.das.db.Dao;
import ar.edu.ubp.das.db.DaoFactory;

@WebService(targetNamespace = "http://ws.com/", portName = "ProveedorWSPort", serviceName = "ProveedorWSService")
public class ProveedorWS {

	private void validarToken(String token) throws AuthenticationException, SQLException {
        try (Dao<String, String, String> dao = DaoFactory.getDao("VerificarToken", "com")) {
            if (!dao.valid(token)) {
                throw new AuthenticationException("Token no válido " + token);
            }
        }
    }
	
	@WebMethod(operationName = "getConfiguracion", action = "urn:GetConfiguracion")
	@WebResult(name = "return")
	public  List<String> getConfiguracion(@WebParam(name = "arg0") String token){
		try {
			validarToken(token);
			try (Dao<String, String, String> dao = DaoFactory.getDao("Configuracion", "com")){
				return dao.select(null);
			} catch (SQLException e) {
				throw new Fault(e);
			}
		} catch (AuthenticationException | SQLException e) {
			throw new Fault(e);
		}
		
	}
	
	@WebMethod(operationName = "getProductos", action = "urn:GetProductos")
	@WebResult(name = "return")
	public List<String> getProductos(@WebParam(name = "arg0") String token){
		try {
			validarToken(token);
			try (Dao<String, String, String> dao = DaoFactory.getDao("Productos", "com")){
				return dao.select(null);
			} catch (SQLException e) {
				throw new Fault(e);
			}
		} catch (AuthenticationException | SQLException e) {
			throw new Fault(e);
		}		
	}
	
	@WebMethod(operationName = "getEscala", action = "urn:GetEscala")
	@WebResult(name = "return")
	public List<String> getEscala(@WebParam(name = "arg0") String token){
		try {
			validarToken(token);
			try (Dao<String, String, String> dao = DaoFactory.getDao("Escala", "com")){
				return dao.select(null);
			} catch (SQLException e) {
				throw new Fault(e);
			}
		} catch (AuthenticationException | SQLException e) {
			throw new Fault(e);
		}		
	}
	
	@WebMethod(operationName = "getPedido", action = "urn:GetPedido")
	@WebResult(name = "return")
	public List<String> getPedido(@WebParam(name = "arg0") String token, @WebParam(name = "arg1") String json){
		try {
			validarToken(token);
			try (Dao<String, String, String> dao = DaoFactory.getDao("Pedido", "com")){
				return dao.select(json);
			} catch (SQLException e) {
				throw new Fault(e);
			}
		} catch (AuthenticationException | SQLException e) {
			throw new Fault(e);
		}
	}
	
	@WebMethod(operationName = "getPedidos", action = "urn:GetPedidos")
	@WebResult(name = "return")
	public  List<String> getPedidos(@WebParam(name = "arg0") String token){
		try {
			validarToken(token);
			try (Dao<String, String, String> dao = DaoFactory.getDao("Pedidos", "com")) {
	            return dao.select(null);
	        } catch (SQLException e) {
	            throw new Fault(e);
	        }
		} catch (AuthenticationException | SQLException e) {
			throw new Fault(e);
		}		
	}
	
	@WebMethod(operationName = "cancelarPedido", action = "urn:CancelarPedido")
	@WebResult(name = "return")
	public String cancelarPedido(@WebParam(name = "arg0") String token, @WebParam(name = "arg1") String json){
		try {
			validarToken(token);
			try (Dao<String, String, String> dao = DaoFactory.getDao("CancelarPedido", "com")){
				return dao.update(json);
			} catch (SQLException e) {
				throw new Fault(e);
			}
		} catch (AuthenticationException | SQLException e) {
			throw new Fault(e);
		}		
	}
	
	@WebMethod(operationName = "insertarPedido", action = "urn:InsertarPedido")
	@WebResult(name = "return")
	public String insertarPedido(@WebParam(name = "arg0") String token, @WebParam(name = "arg1") String json){
		try {
			validarToken(token);
			try (Dao<String, String, String> dao = DaoFactory.getDao("InsertarPedido", "com")){
				return dao.insert(json);
			} catch (SQLException e) {
				throw new Fault(e);
			}
		} catch (AuthenticationException | SQLException e) {
			throw new Fault(e);
		}		
	}
	
}
