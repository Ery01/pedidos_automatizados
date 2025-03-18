import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

import { ServiciosService } from 'src/app/main/services/servicios.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  
  form: FormGroup;
  submitted = false;
  errorMessage = '';

  constructor(private fb: FormBuilder, private serviciosService: ServiciosService) {
    this.form = this.fb.group({
      usuario: ['', Validators.required],
      clave: ['', Validators.required]
    });
  }
  
  registrarLogin() {
    this.submitted = true;

    if (this.form.invalid) {
      return;
    }

    const { usuario, clave } = this.form.value;

    this.serviciosService.loginUsuario(usuario, clave).subscribe({
      next: (response) => {
        console.log('Respuesta del backend:', response);
        alert(response.message); 
      },
      error: (error) => {
        console.error('Error en el login:', error);
        this.errorMessage = 'Error al iniciar sesión';
      }
    });
  }
}
