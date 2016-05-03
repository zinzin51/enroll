Feature: Consumer views effective date and any choice dates entered
	As an HBX-admin, when I enter custom choice dates then the consumer should see them 
	along with the effective dates in a drop down. They should also only be able to select 
	a single date.

	Background:
		Given I have logged in as an HBX-Admin
		And I click the SEP link from the Admin DC Health Link login page
		And I have entered Choice Date 1
		When a consumer naviagtes to plan shopping


	Scenario: view choice date as a Consumer
		Given the SEP is still open
		Then an effective drop-down is displayed
		And contains the effective date and any choice dates entered by the HBX-admin

	Scenario: consumer can only select a single date
		Given the SEP is still open
		When the consumer selects the effective date
		And then selects the Choice date
		Then the choice date is the one that will be applied to the consumer


	