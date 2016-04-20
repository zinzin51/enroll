Feature: search IVL enrollment for SEP information

	As an HBX admin, I want to be able to search an IVL enrollment for SEP information. I should be able
	to filter based on the staus of the primary subscriber.

	Background:
		Given I have logged in as an HBX-Admin
		And I click the SEP link from the Admin DC Health Link login page

	Scenario: successfully navigate to SEP page
		Then the SEP page is displayed
		#assert default text is search box is "Name, SSN"
		And a search box is displayed where I can search by name or ssn 
		And the ALL, IVL and EE buttons appear above the display list
		And I see columns with headings HBX ID, Last Name, First Name, SSN, Consumer and Employee
		And I see the Add SEP and History buttons
	
	Scenario: primary subscriber is registered only as a consumer
		Given I search for a subscriber who is only registered as a consumer
		When I enter his name in the search box
		Then I see Yes in the Consumer Field and No in the Employee field for his search results

	Scenario: primary subscriber is registered only as an employee
		Given I search for a subscriber who is only registered as an employee
		When I enter his name in the search box
		Then I see No in the Consumer Field and Yes in the Employee field for his search results
	
	Scenario: primary subscriber is registered as both a consumer and as an employee
		Given I search for a subscriber who is only registered as a consumer and as an employee
		When I enter his name in the search box
		Then I see Yes in the Consumer Field and Yes in the Employee field for his search results

	Scenario: filter using the filter buttons
		Given I have searched for 2 consumer only subscribers, 3 employee only subscribers and 3 both subscribers
		When I push the IVL button
		Then I should see the 2 consumber only and 3 both subscribers
		When I push the EE button
		Then I should see the 3 employee only and 3 both subscribers
		When I push the ALL button
		Then I should see the 2 consumer only, 3 employee only and 3 both subscribers	