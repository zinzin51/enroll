module NavigationHelper
  TABS_WITH_TITLE = {"accountRegistration" => { "title" => "Account Registration", "steps" => [{"title"=>"Personal Info", "id"=>"personalInfo"}] }, "moreAboutYou" => { "title" => "More About You", "steps" => [{"title"=>"More About You", "id"=>"moreAboutYouStep"}, {"title"=>"Authorization & Consent", "id"=>"ridpAgreement"}, {"title"=>"Verify Identity", "id"=>"verifyIdentity"}, {"title"=>"", "id"=>"experianError"}] }, "householdInfo" => { "title"=> "Household Info", "steps"=> [{"title"=>"Help paying Coverage", "id"=>"helpPayingCoverage"}, {"title"=>"Application Checklist", "id"=>"applicationChecklist"}, {"title"=>"Household Info", "id"=>"householdInfoStep"}] } }
  
  def self.getStepsOfTab(tab)
    TABS_WITH_TITLE[tab]["steps"]
  end

  def self.getAllTabs
    TABS_WITH_TITLE.map {|tab, tabValue| {"title" => tabValue["title"], "id"=> tab}}
  end
end