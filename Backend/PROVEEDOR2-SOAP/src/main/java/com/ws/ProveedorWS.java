package com.ws;

import java.sql.SQLException;
import java.util.List;

import org.apache.cxf.interceptor.Fault;

import ar.edu.ubp.das.db.Dao;
import ar.edu.ubp.das.db.DaoFactory;

public class ProveedorWS {

	public  List<String> getConfiguracion(){
		try (Dao<String, String, String> dao = DaoFactory.getDao("Configuracion", "com")){
			return dao.select(null);
		} catch (SQLException e) {
			throw new Fault(e);
		}
	}
	
	public List<String> getProductos(){
		try (Dao<String, String, String> dao = DaoFactory.getDao("Productos", "com")){
			return dao.select(null);
		} catch (SQLException e) {
			throw new Fault(e);
		}
	}
	
	public List<String> getEscala(){
		try (Dao<String, String, String> dao = DaoFactory.getDao("Escala", "com")){
			return dao.select(null);
		} catch (SQLException e) {
			throw new Fault(e);
		}
	}
	
	public List<String> getPedido(String json){
		try (Dao<String, String, String> dao = DaoFactory.getDao("Pedido", "com")){
			return dao.select(json);
		} catch (SQLException e) {
			throw new Fault(e);
		}
	}
	
	public  List<String> getPedidos(){
		try (Dao<String, String, String> dao = DaoFactory.getDao("Pedidos", "com")) {
            return dao.select(null);
        } catch (SQLException e) {
            throw new Fault(e);
        }
	}
	
	public String cancelarPedido(String json){
		try (Dao<String, String, String> dao = DaoFactory.getDao("CancelarPedido", "com")){
			return dao.update(json);
		} catch (SQLException e) {
			throw new Fault(e);
		}
	}
	
	public String insertarPedido(String json){
		try (Dao<String, String, String> dao = DaoFactory.getDao("InsertarPedido", "com")){
			return dao.insert(json);
		} catch (SQLException e) {
			throw new Fault(e);
		}
	}
	
}
