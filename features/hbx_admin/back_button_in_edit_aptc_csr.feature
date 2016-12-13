Feature: Edit APTC and CSR back button
    In order to check Edit APTC and CSR back button
    User should have the role of an admin
    
    Scenario: Admin enters credentials
        Given Hbx Admin exists
            When Hbx Admin logs on to the Hbx Portal
            When Hbx Admin created records
            And Hbx Admin clicks on the Families tab
            Then Hbx Admin should see the list of  applicants and an Individual Enrolled button
            When Hbx Admin clicks on the Individual Enrolled button
            Then Hbx Admin should see the Assited button
            Then Hbx Admin clicks on assited
            When Hbx Admin should see list of assited records
            Then Hbx Admin should see  actions buton
            When Hbx Admin clicks on edit Edit APTC / CSR 
            Then Hbx Admin should see the Editing APTC \ CSR page
            When Hbx Admin clicks on Back button
            Then assistance count should match with the tr count

           
