import { Injectable } from '@angular/core';
import { IResourceMethodObservable, Resource, ResourceAction, ResourceHandler, ResourceParams, ResourceRequestBodyType, ResourceRequestMethod } from '@ngx-resource/core';
import { environment } from 'src/environments/environment';
import { Login } from 'src/app/models/login.model';

@Injectable({
  providedIn: 'root'
})

@ResourceParams({
  pathPrefix: `${environment.apiUrl}` 
})

export class ServiciosService extends Resource {

  constructor(handler: ResourceHandler) {
    super(handler);
  }

  @ResourceAction({
    method: ResourceRequestMethod.Post,
    path: '/login',
    requestBodyType: ResourceRequestBodyType.JSON 
  })
  loginUsuario!: IResourceMethodObservable<Login, any>;
}