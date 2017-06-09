import * as React from "react";

export interface AddressComponentProps { 
rootUri : string;
kind : string;
namePrefix : string;
}

export class AddressComponent extends React.Component<AddressComponentProps, undefined> {
        inputName(fName: string) {
          return(this.props.namePrefix + "[" + fName + "]")
        }

	render() {
                var address_kind = "";
		var kind_input_name = this.inputName("kind");
		var address_1_input_name = this.inputName("address_1")
		var address_2_input_name = this.inputName("address_2")
		var city_input_name = this.inputName("city")
		var zip_input_name = this.inputName("zip")
		var state_input_name = this.inputName("state")
                var address_1 = "";
                var address_2 = "";
                var city = "";
                var state = "";
                var zip = "";
                var visible = true;
		return(reactTemplate("address_component.tsx.html"));
	}
}
