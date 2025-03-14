import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { ServiciosService } from './services/servicios.service';
import { MainRoutingModule } from './main-routing.module';

import { MainComponent } from './main.component';
import { LoginComponent } from './pages/login/login.component';


@NgModule({
  declarations: [
    MainComponent,
    LoginComponent
  ],
  imports: [
    CommonModule,
    MainRoutingModule,
    FormsModule,
    ReactiveFormsModule
  ],
  providers: [
    ServiciosService
  ]
})
export class MainModule { }
