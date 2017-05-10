import { Component, ElementRef } from '@angular/core';

@Component({
  selector: "[data-angular2-address-control=yes]",
  templateUrl: "./address.component.html"
})
export class AddressComponent { 
  kind : string = "";
  namePrefix : string = "";
  address_1 : string = "";
  address_2 : string = "";
  city : string = "";
  zip : string = "";
  state : string = "";
  stateList : string[] = [];
  visible : boolean = true;

  constructor(private elementRef: ElementRef) { }

  ngOnInit() {
    this.namePrefix = this.elementRef.nativeElement.getAttribute("data-angular2-address-prefix");
    var json_string = this.elementRef.nativeElement.getAttribute("data-angular2-address-data");
    var address_data = JSON.parse(json_string);
    var state_json = this.elementRef.nativeElement.getAttribute("data-angular2-address-state-data");
    var hidden_address_attribute = this.elementRef.nativeElement.getAttribute("data-angular2-address-hide");
    if (hidden_address_attribute) {
      this.visible = false;
    }
    this.stateList = JSON.parse(state_json);
    this.kind = address_data.kind;
    this.address_1 = address_data.address_1;
    this.address_2 = address_data.address_2;
    this.state = address_data.state;
    this.city = address_data.city;
    this.zip = address_data.zip;
  }

  ngAfterViewChecked() {
    eval("$(\"select[name='\" + this.namePrefix + \"[state]']\").selectric();");
  }
}
