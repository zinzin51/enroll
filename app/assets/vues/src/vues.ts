import Vue from 'vue';
import { AddressComponent } from "./components/address_component";

export function initVueAddressFields(the_element : Element, options: Object) {
	new AddressComponent({propsData: options, el: the_element});
}

(<any>window).initVueAddressFields = initVueAddressFields;
