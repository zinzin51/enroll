import * as React from "react";
import * as ReactDOM from "react-dom";

import { AddressComponent, AddressComponentProps } from "./components/address_component";

export function initReactAddressFields(item : Element, data : AddressComponentProps) {
  ReactDOM.render(React.createElement(AddressComponent, data), item);
}

(window as any).initReactAddressFields = initReactAddressFields;
