import Vue from 'vue';
import { Prop } from 'vue-property-decorator'
import Component from 'vue-class-component';

@Component({
	template: require('../templates/address_component.html')
})
export class AddressComponent extends Vue {
	@Prop({required: true})
	kind : string;

	@Prop({required: true})
	namePrefix : string;

	@Prop()
	address_1 : string;
	@Prop()
	address_2 : string;
	@Prop()
	city : string;
	@Prop()
	zip : string;
	@Prop()
	state : string;
	@Prop()
	stateData : Array<string>;
	@Prop({default: false})
	hidden : boolean;
}
