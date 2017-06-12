import Vue from 'vue';
import Component from 'vue-class-component';

export interface AddressComponentProps { 
	kind : string;
	namePrefix : string;
	address_1 : string;
	address_2 : string;
	city : string;
	zip : string;
	state : string;
	stateData : Array<string>;
	hidden : boolean;
}

@Component({
	template: require('../templates/address_component.html')
})
export class AddressComponent extends Vue {
}
