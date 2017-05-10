import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpModule } from '@angular/http';

import { AddressComponent } from './address.component';

@NgModule({
declarations: [
AddressComponent
],
imports: [
BrowserModule,
FormsModule,
HttpModule
],
providers: [],
bootstrap: [AddressComponent]
})
export class AddressModule { }
