import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { AddressModule } from './app/address.module';

export function initAngularAddressFields() {
  platformBrowserDynamic().bootstrapModule(AddressModule);
  }

(<any>window).initAngularAddressFields = initAngularAddressFields;
