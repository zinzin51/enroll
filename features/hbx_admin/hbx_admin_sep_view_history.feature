Feature: view detailed SEP history for an enrollment/household

	As an HBX admin, when I navigate to the SEP dashboard/portal, I should be able to 
	view the detailed SEP history for an enrollment/household

	Background:
	  Given I have logged in as an HBX-Admin
		And I click the SEP link from the Admin DC Health Link login page

	Scenario Outline: view history for IVL, EE and All registrants
		The HBX admin should be able to view the SEP history regardless of the registration type
		
		Given <primary applicant> is registered as <registration type>
		When I click on the archive tab 
		Then I should see the SEP history for him in chronological order #newest to oldest
		And I should see <field>

		Examples: IVL
			primary applicant is registered as an IVL


			| primary applicant |  registration type |      field 				 										 |
			| John Smith				|      IVL					 | SEP reason dropdown 										 |
			| John Smith				|      IVL					 | Effective Date Rule 										 |
			| John Smith				|      IVL					 | Event Date					 										 |
			| John Smith				|      IVL					 | SEP Start Date			 										 |
			| John Smith				|      IVL					 | SEP End Date				 										 |
			| John Smith				|      IVL					 | Next Possible Effective Date 					 |
			| John Smith				|      IVL					 | Choice Date 1			 										 |
			| John Smith				|      IVL					 | Choice Date 2			 										 |
			| John Smith				|      IVL					 | Choice Date 3			 										 |
			| John Smith				|      IVL					 | CSL#												  					 |
			| John Smith				|      IVL					 | medical plan select and effective dates |
			| John Smith				|      IVL					 | dental plan select and effective dates	 |
			| John Smith				|      IVL					 | comments																 |


  	Examples: EE
			primary applicant is registered as an EE


			| primary applicant |  registration type |      field 				 										 |
			| Jan Doe						|      EE 					 | SEP reason dropdown 										 |
			| Jan Doe						|      EE 					 | Effective Date Rule 										 |
			| Jan Doe						|      EE 					 | Event Date					 										 |
			| Jan Doe						|      EE 					 | SEP Start Date			 										 |
			| Jan Doe						|      EE 					 | SEP End Date				 										 |
			| Jan Doe						|      EE 					 | Next Possible Effective Date 					 |
			| Jan Doe						|      EE 					 | Choice Date 1			 										 |
			| Jan Doe						|      EE 					 | Choice Date 2			 										 |
			| Jan Doe						|      EE 					 | Choice Date 3			 										 |
			| Jan Doe						|      EE 					 | CSL#												  					 |
			| Jan Doe						|      EE 					 | medical plan select and effective dates |
			| Jan Doe						|      EE 					 | dental plan select and effective dates	 |
			| Jan Doe						|      EE 					 | comments																 |

		Examples: All
			primary applicant is registered as both an IVL and an EE


			| primary applicant |  registration type |      field 				 										 |
			| Mark Jones				|      All					 | SEP reason dropdown 										 |
			| Mark Jones				|      All					 | Effective Date Rule 										 |
			| Mark Jones				|      All					 | Event Date					 										 |
			| Mark Jones				|      All					 | SEP Start Date			 										 |
			| Mark Jones				|      All					 | SEP End Date				 										 |
			| Mark Jones				|      All					 | Next Possible Effective Date 					 |
			| Mark Jones				|      All					 | Choice Date 1			 										 |
			| Mark Jones				|      All					 | Choice Date 2			 										 |
			| Mark Jones				|      All					 | Choice Date 3			 										 |
			| Mark Jones				|      All					 | CSL#												  					 |
			| Mark Jones				|      All					 | medical plan select and effective dates |
			| Mark Jones				|      All					 | dental plan select and effective dates	 |
			| Mark Jones				|      All					 | comments																 |
