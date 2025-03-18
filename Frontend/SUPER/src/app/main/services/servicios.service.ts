import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ServiciosService {

  private apiUrl = 'http://localhost:8086/super/login';

  constructor(private http: HttpClient) { }

  loginUsuario(usuario: string, clave: string): Observable<any> {
    const body = { usuario, clave };

    return this.http.post<any>(this.apiUrl, body);
  }
}
