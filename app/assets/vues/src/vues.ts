import * as Vue from 'vue';
import { AddressComponent } from "./components/address_component";

export function initVueAddressFields(the_element : string) {
	return(new Vue({
		el: the_element,
		components: {
			address: AddressComponent
		}
	}));
}

(<any>window).initVueAddressFields = initVueAddressFields;
