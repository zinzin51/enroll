  # enrollment type
# "tile": "left_enrollment_type",
# "auto_renewals_count": 12239,
# "auto_renewals_share": 0.49,
# "auto_renewals_yoy": -0.04,
# "active_renewals_count": 2971,
# "active_renewals_share": 0.12,
# "active_renewals_yoy": 0.09,
# "new_customers_count": 6484,
# "new_customers_share": 0.26,
# "new_customers_yoy": 0.21,
# "sep_count": 3530,
# "sep_share": 0.14,
# "sep_yoy": 0.07


count = 0
processed_count = 0
results = []
wf_ids = []
Family.by_enrollment_individual_market.by_enrollment_effective_date_range(Date.new(2016,1,1),Date.new(2016,12,31)).each do |family|
  processed_count+=1
  puts "processed #{processed_count} records :: #{count}" if processed_count%1000 == 0
  household = family.active_household
  enrollments = household.hbx_enrollments
  enrollments.each do |enr|
    if enr.coverage_kind == "health" && enr.effective_on >= Date.new(2016,1,1) && enr.effective_on <= Date.new(2016,12,31) && ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"].include?(enr.kind)
      wf = enr.workflow_state_transitions.where(to_state: "auto_renewing").first
      # enr.workflow_state_transitions.each do |wf|
        if wf.present?
          wf_ids << wf.id
          results << enr.id
          count+=1
        end
      # end
    end
  end
end

result = Family.collection.aggregate([
  {"$unwind" => '$households'},
  {"$unwind" => '$households.hbx_enrollments'},
  {"$unwind" => '$households.hbx_enrollments.workflow_state_transitions'},
  {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
  {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
  {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => Date.new(2016,1,1), "$lte" => Date.new(2016,12,31)}}},
  {"$match" => {"households.hbx_enrollments.workflow_state_transitions.to_state"=> "auto_renewing"}},
  {"$group" => { "_id" => {}, "enrollments" => { "$addToSet" => '$households.hbx_enrollments'} }},
  {"$unwind" => "$enrollments"},
  {"$group" => { "_id" => "$_id", "enrollmentCount" => { "$sum" =>1 }}}
  ], :allow_disk_use => true
).to_a


# {"$group" => { "_id" => {}, "enrollments" => { "$addToSet" => '$households.hbx_enrollments'} }},
  # {"$unwind" => "$enrollments"},
  # {"$group" => { "_id" => "$_id", "enrollmentCount" => { "$sum" =>1 }}}

# carrier
# "tile": "left_carrier",
# "carrier_first_name": "CareFirst",
# "carrier_first_count": 16315,
# "carrier_first_share": 0.81,
# "carrier_first_yoy": 0.0,
# "carrier_second_name": "Kaiser",
# "carrier_second_count": 3815,
# "carrier_second_share": 0.19,
# "carrier_second_yoy": 0.0

result = Plan.collection.raw_aggregate([
  {"$match" => {"active_year" =>  2016 }},
  {"$group" => {"_id" => {}, "planCount" => {"$sum" => 1} }}
]).to_a

carefirst_plan_ids_2017 = Plan.where(active_year: 2017, coverage_kind: "health", market: "individual", carrier_profile_id: "53e67210eb899a4603000004").map(&:_id)

def carrier(start_date, end_date, carrier_name)
  carrier_profile_id = carrier_name.downcase == "carefirst" ? "53e67210eb899a4603000004" : "53e67210eb899a460300000d"
  plan_ids = Plan.where(active_year: start_date.year, coverage_kind: "health", market: "individual", carrier_profile_id: carrier_profile_id).map(&:_id)

  Family.collection.aggregate([
    {"$unwind" => '$households'},
    {"$unwind" => '$households.hbx_enrollments'},
    {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
    {"$match" => {"households.hbx_enrollments.aasm_state"=> {"$in" => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + ["coverage_expired"] } }},
    {"$match" => {"households.hbx_enrollments.plan_id"=> { "$in" => plan_ids }}},
    {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
    {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
    {"$group" => { "_id" => {}, "enrollments" => { "$addToSet" => '$households.hbx_enrollments'} }},
    {"$unwind" => "$enrollments"},
    {"$group" => { "_id" => "$_id", "enrollment_count" => { "$sum" =>1 }}}
    ], :allow_disk_use => true
  ).first[:enrollment_count].to_f
end

def total_carrier_count(start_date, end_date)
  Family.collection.aggregate([
    {"$unwind" => '$households'},
    {"$unwind" => '$households.hbx_enrollments'},
    {"$match" => {"households.hbx_enrollments.aasm_state"=> {"$in" => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + ["coverage_expired"] } }},
    {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
    {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
    {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
    {"$group" => { "_id" => {}, "enrollments" => { "$addToSet" => '$households.hbx_enrollments'} }},
    {"$unwind" => "$enrollments"},
    {"$group" => { "_id" => "$_id", "enrollment_count" => { "$sum" =>1 }}}
    ], :allow_disk_use => true
  ).first[:enrollment_count].to_f
end

start_date = Date.new(2016,1,1)
end_date = Date.new(2016,12,31)

carrier_name = "carefirst"
carrier_first_count = carrier(start_date, end_date, carrier_name)
total_carrier_count = total_carrier_count(start_date, end_date)
carrier_first_share = (carrier_first_count/total_carrier_count).round(2)

start_date = Date.new(2015,1,1)
end_date = Date.new(2015,12,31)

carrier_name = "carefirst"
carrier_first_year_ago_count = carrier(start_date, end_date, carrier_name)
total_carrier_year_ago_count = total_carrier_count(start_date, end_date)
carrier_first_year_ago_share = (carrier_first_year_ago_count/total_carrier_year_ago_count).round(2)

carrier_first_yoy = ((carrier_first_share - carrier_first_year_ago_share)/(carrier_first_year_ago_share)).round(2)

# kaiser

start_date = Date.new(2016,1,1)
end_date = Date.new(2016,12,31)

carrier_name = "kaiser"
carrier_second_count = carrier(start_date, end_date, carrier_name)
total_carrier_count = total_carrier_count(start_date, end_date)
carrier_second_share = (carrier_second_count.to_f/total_carrier_count.to_f).round(2)

start_date = Date.new(2015,1,1)
end_date = Date.new(2015,12,31)

carrier_name = "kaiser"
carrier_second_year_ago_count = carrier(start_date, end_date, carrier_name)
total_carrier_year_ago_count = total_carrier_count(start_date, end_date)
carrier_second_year_ago_share = (carrier_second_year_ago_count.to_f/total_carrier_year_ago_count.to_f).round(2)

carrier_second_yoy = ((carrier_second_share - carrier_second_year_ago_share)/(carrier_second_year_ago_share)).round(2)


{
  carrier_first_name: "CareFirst", carrier_first_count: carrier_first_count, carrier_first_share: carrier_first_share, carrier_first_yoy: carrier_first_yoy,
  carrier_second_name: "Kaiser", carrier_second_count: carrier_second_count, carrier_second_share: carrier_second_share, carrier_second_yoy: carrier_second_yoy,
}

# metal level

# "tile": "left_metal",
# "platinum_count": 3337,
# "platinum_share": 0.16,
# "platinum_yoy": 0.01,
# "gold_count": 4277,
# "gold_share": 0.20,
# "gold_yoy": -0.15,
# "silver_count": 6333,
# "silver_share": 0.30,
# "silver_yoy": -0.07,
# "bronze_count": 5854,
# "bronze_share": 0.28,
# "bronze_yoy": 0.08,
# "catastrophic_count": 1465,
# "catastrophic_share": 0.07,
# "catastrophic_yoy": 0.09

def metal_level(start_date, end_date, metal_level_kind)
  plan_ids = Plan.where(active_year: start_date.year, coverage_kind: "health", market: "individual", metal_level: metal_level_kind).map(&:_id)

  Family.collection.aggregate([
    {"$unwind" => '$households'},
    {"$unwind" => '$households.hbx_enrollments'},
    {"$match" => {"households.hbx_enrollments.aasm_state"=> {"$in" => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + ["coverage_expired"] } }},
    {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
    {"$match" => {"households.hbx_enrollments.plan_id"=> { "$in" => plan_ids }}},
    {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
    {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
    {"$group" => { "_id" => {}, "enrollments" => { "$addToSet" => '$households.hbx_enrollments'} }},
    {"$unwind" => "$enrollments"},
    {"$group" => { "_id" => "$_id", "enrollment_count" => { "$sum" =>1 }}}
    ], :allow_disk_use => true
  ).first[:enrollment_count].to_f
end

def total_carrier_count(start_date, end_date)
  Family.collection.aggregate([
    {"$unwind" => '$households'},
    {"$unwind" => '$households.hbx_enrollments'},
    {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
    {"$match" => {"households.hbx_enrollments.aasm_state"=> {"$in" => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + ["coverage_expired"] } }},
    {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
    {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
    {"$group" => { "_id" => {}, "enrollments" => { "$addToSet" => '$households.hbx_enrollments'} }},
    {"$unwind" => "$enrollments"},
    {"$group" => { "_id" => "$_id", "enrollment_count" => { "$sum" =>1 }}}
    ], :allow_disk_use => true
  ).first[:enrollment_count].to_f
end

start_date = Date.new(2016,1,1)
end_date = Date.new(2016,12,31)

metal_level = "platinum"
current_year_count = metal_level(start_date, end_date, carrier_name)
current_year_total = total_carrier_count(start_date, end_date)
current_year_share = (current_year_count/current_year_total).round(2)

start_date = Date.new(2015,1,1)
end_date = Date.new(2015,12,31)

past_year_count = metal_level(start_date, end_date, carrier_name)
past_year_total = total_carrier_count(start_date, end_date)
past_year_share = (past_year_count/past_year_total).round(2)

metal_level_yoy = ((current_year_share - past_year_share)/(past_year_share)).round(2)


# status(primary/dependent percentage)
# "tile": "left_status",
# "primary_count": 19850,
# "primary_share": 0.82,
# "primary_yoy": 0.05,
# "dependent_count": 2445,
# "dependent_share": 0.18,
# "dependent_yoy": -0.10

def count_primary_members(start_date, end_date, metal_level_kind)
    result = Family.collection.aggregate([
      {"$unwind" => '$households'},
      {"$unwind" => '$households.hbx_enrollments'},
      {"$unwind" => '$households.hbx_enrollments.hbx_enrollment_members'},
      {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
      {"$match" => {"households.hbx_enrollments.aasm_state"=> {"$in" => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + ["coverage_expired"] } }},
      {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
      {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
      {"$match" => {"households.hbx_enrollments.hbx_enrollment_members.is_subscriber"=> true}},
      {"$group" => { "_id" => {}, "enrollments" => { "$addToSet" => '$households.hbx_enrollments._id'} }},
      {"$unwind" => "$enrollments"},
      {"$group" => { "_id" => "$_id", "enrollment_count" => { "$sum" =>1 }}}
      ], :allow_disk_use => true
    ).first[:enrollment_count].to_f
end

