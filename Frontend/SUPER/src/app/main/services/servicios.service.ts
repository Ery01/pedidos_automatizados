import { Injectable } from '@angular/core';
import {
  Resource,
  ResourceAction,
  ResourceHandler,
  ResourceRequestMethod,
  IResourceMethodObservable
} from 'ngx-resource-core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class ServiciosService extends Resource {

  constructor(handler: ResourceHandler, private http: HttpClient) {
    super(handler);
  }

  @ResourceAction({
    method: ResourceRequestMethod.Post,
    path: '/login',
  })
  loginUsuario!: IResourceMethodObservable<{ usuario: any }, any>;
}