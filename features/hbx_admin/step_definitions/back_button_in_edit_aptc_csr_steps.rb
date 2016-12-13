When(/^Hbx Admin created records$/) do
	f = FactoryGirl.create(:individual_market_family)
	person_rec = f.primary_applicant.person
	FactoryGirl.create(:hbx_enrollment,
	household: person_rec.primary_family.active_household,
	coverage_kind: "health",
	enrollment_kind: "open_enrollment",
	kind: "insurance_assisted_qhp"
	)
	tx = FactoryGirl.create(:tax_household, :household => f.active_household )
	ed = FactoryGirl.create(:eligibility_determination, tax_household: tx)
end

When(/^Hbx Admin clicks on the Families link$/) do
  click_link "Families"
  wait_for_ajax
end

Then(/^Hbx Admin should see the list of  applicants and an Individual Enrolled button$/) do
 find('#Tab\\:by_enrollment_individual_market').visible?
end


When(/^Hbx Admin clicks on the Individual Enrolled button$/) do
  find('#Tab\\:by_enrollment_individual_market').click
  wait_for_ajax

end

Then(/^Hbx Admin should see the Assited button$/) do
 find('#Tab\\:by_enrollment_individual_market-all_assistance_receiving').visible?
end


Then(/^Hbx Admin clicks on assited$/) do
 find('#Tab\\:by_enrollment_individual_market-all_assistance_receiving').click
end

When(/^Hbx Admin should see list of assited records$/) do
  find('#Tab\\:by_enrollment_individual_market-all_assistance_receiving').visible?
  wait_for_ajax
end

Then(/^Hbx Admin should see  actions buton$/) do
    find_button('Actions').click
end


When(/^Hbx Admin clicks on edit Edit APTC \/ CSR$/) do
  page.find_link('Edit APTC / CSR').click
end

Then(/^Hbx Admin should see the Editing APTC \\ CSR page$/) do
    expect(page).to have_content('Editing APTC / CSR for')
end


Then(/^Hbx Admin clicks on Back button$/) do
  find_link('Back').visible?
  click_link('Back')
end

Then(/^assistance count should match with the tr count$/) do
	wait_for_ajax
	assistance_count = Family.all_assistance_receiving.count
	page.all('table.effective-datatable tbody tr').count.should == assistance_count
end

