Feature: HBX-Admin needs to add a non self-attested SEP for an enrollment/household

	As an HBX-admin I need to be able to add a non self-attested SEP for an enrollment
	or household.

	Background:
		Given I have logged in as an HBX-Admin
		And I click the SEP link from the Admin DC Health Link login page


	Scenario Outline: add non self-attested SEP for an enrollment/household
		When I click on the Add SEP button
		Then the SEP add page is displayed with the following <field>

		Examples:
		| field 											 |
		|	IVL/EE Radio button 				 |
		| SEP Reason dropdown 				 |
		| Effective Date Rule dropdown |
		| CSL#												 |
		| comment											 |
		| submit button								 |
		| SEP start Date							 |
		| SEP end Date for IVL 				 |
		| SEP end Date for EE 				 |
		| Next Possible Effective Date |
		| Choice Date 1								 |
		| Choice Date 2								 |
		| Choice Date 3								 |


	Scenario Outline: edit Event date, SEP Start, SEP End and Effective dates
		When I click on the Add SEP button
		Then <button> is enabled

		Examples:
		| button 		 			|
		| Event date 			|
		| SEP Start  			|
		| SEP End 	 			|
		| Effective dates |