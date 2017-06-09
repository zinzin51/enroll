import * as React from "react";

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

export class AddressComponent extends React.Component<AddressComponentProps, undefined> {
        inputName(fName: string) {
          return(this.props.namePrefix + "[" + fName + "]")
        }

	render() {
                var address_kind = "";
		var kind_input_name = this.inputName("kind");
		var address_1_input_name = this.inputName("address_1");
		var address_2_input_name = this.inputName("address_2");
		var city_input_name = this.inputName("city");
		var zip_input_name = this.inputName("zip");
		var state_input_name = this.inputName("state");
                var state_data = this.props.stateData;
                var address_1 = this.props.address_1; 
                var address_2 = this.props.address_2; 
                var city = this.props.city; 
                var zip = this.props.zip;
                var state_value = this.props.state;
                var hidden = this.props.hidden;
		return(reactTemplate("address_component.tsx.html"));
	}

        componentDidMount() {
          eval("$(\"select[name='\" + this.props.namePrefix + \"[state]']\").selectric();");
        }

}
