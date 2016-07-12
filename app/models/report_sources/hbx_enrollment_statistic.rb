module ReportSources
  class HbxEnrollmentStatistic
    include Mongoid::Document

    field :policy_start_on, type: DateTime
    field :family_created_at, type: DateTime
    field :policy_purchased_at, type: DateTime
    field :plan_id, type: BSON::ObjectId
    field :hbx_id, type: String
    field :enrollment_kind, type: String
    field :aasm_state, type: String
    field :coverage_kind, type: String
    field :family_id, type: BSON::ObjectId
    field :rp_ids, type: Array, default: []
    field :consumer_role_id, type: Array, default: []
    field :benefit_group_id, type: Array, default: []
    field :benefit_group_assignment_id, type: Array, default: []
    field :state_transitions, type: Array, default: []
    field :market, type: String
    field :member_count, type: Integer, default: 0
    field :is_standard_plan, type: Boolean, default: false
    field :carrier_profile_id, type: BSON::ObjectId
    field :metal_level, type: String
    field :plan_type, type: String
    field :csr_variant_id, type: String
    field :plan_name, type: String



    def self.populate_historic_data!
      q = Queries::PolicyAggregationPipeline.new
      q.denormalize
      q.evaluate.each
    end

    def self.populate_time_dimensions!
      self.all.each do |rec|
        rec.populate_applicable_dimensions!
      end
    end

    def populate_applicable_dimensions!
      eligible_dimensions.each_pair do |k, v|
        ::Analytics::AggregateEvent.increment_time(subject: k, moment: self.send(v))
      end
    end

    def eligible_dimensions
      dimensions = {}
      subject_specifications.each do |ts|
        if self.send(ts.last)
          dimensions[ts.first + " - Submitted At"] = :policy_purchased_at
          dimensions[ts.first + " - Effective Date"] = :policy_start_on
        end
      end
      dimensions
    end

    def subject_specifications
      [
        ["SHOP Enrollment", :shop_purchase?],
        ["IVL Enrollment", :ivl_purchase?],
        ["SHOP Renewal", :shop_renewal?],
        ["IVL Renewal", :ivl_renewal?]
      ]
    end

    def shop_purchase?
      completed_shopping? && (consumer_role_id.blank?)
    end

    def shop_renewal?
      shop_purchase? && renewal?
    end

    def ivl_renewal?
      ivl_purchase? && renewal?
    end

    def ivl_purchase?
      completed_shopping? && (!consumer_role_id.blank?)
    end

    def health?
      coverage_kind == "health"
    end

    def renewal?
      (HbxEnrollment::RENEWAL_STATUSES & state_transitions).any?
    end

    def completed_shopping?
      !["shopping", "inactive"].include?(:aasm_state)
    end

    def self.new_enrollments_by_month
      ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$project': {
          month: {'$month': "$policy_start_on"},
          market: '$market',
          coverage_kind: '$coverage_kind',
          aasm_state: '$aasm_state',
          fmonth: {'$month': '$family_created_at'},
          policy_start_on: '$policy_start_on',
          samemonth: {'$cmp': [{'$month': "$policy_start_on"}, {'$month': '$family_created_at'}] }
        }},
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: 'coverage_selected'}}, 
        {'$match': {policy_start_on: {"$gte" => Date.new(2016,1,1)}}},
        {'$match': {samemonth: 0}},
        {'$group': {_id:{month: '$month'}, count: {'$sum':1}}},
        {'$sort': {'_id.month':1}}
      ],
      :allow_disk_use => true).entries
    end

    def self.purchase_frequency_by_day_of_week
      ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: 'coverage_selected'}}, 
        {'$match': {policy_purchased_at: {"$gte" => Date.new(2016,1,1)}}},
        {'$project': {
          day_of_week: {'$dayOfWeek': "$policy_purchased_at"}
        }},
        {'$group': {_id:{day_of_week: '$day_of_week'}, count: {'$sum':1}}},
        {'$sort': {'_id.day_of_week':1}}
      ],
      :allow_disk_use => true).entries
    end

    def self.purchase_frequency_by_time_of_day
      ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: 'coverage_selected'}}, 
        {'$match': {policy_purchased_at: {"$gte" => Date.new(2016,1,1)}}},
        {'$project': {
          hour: {'$hour': "$policy_purchased_at"},
          minute: {'$minute': "$policy_purchased_at"},
        }},
        {'$group': {_id:{hour: '$hour', minute: '$minute'}, count: {'$sum':1}}},
        {'$sort': {'_id.hour':1, '_id.minute':1}}
      ],
      :allow_disk_use => true).entries
    end

    def self.report_for_chart_by(type='month')
      case type
      when 'month'
        records = self.new_enrollments_by_month
        options = records.map{|r| r["_id"]["month"]}
        report_data = [{:name=>'month', :data=>records.map{|r| r['count']}}]
      when 'week'
        records = self.purchase_frequency_by_day_of_week
        options = records.map{|r| r["_id"]["day_of_week"]}
        report_data = [{:name=>'day of week', :data=>records.map{|r| r['count']}}]
      when 'day'
        records = self.purchase_frequency_by_time_of_day
        options = nil
        report_data_arr = records.map{|r| [r['_id']['hour'] + (r['_id']['minute']/60.0).round(2), r['count']]}
        report_data = [{:name=>'individual', :color=>'rgba(223, 83, 83, .5)', :data=>report_data_arr}]
      end
      [options, report_data]
    end

    def self.health_covered_lives_by_year
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          year: {'$year': "$policy_start_on"},
          hbx_id: '$hbx_id',
        }},
        {'$group': {_id:{year: '$year', hbx_id: '$hbx_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}
      report_data = [{name: 'year', data: reports.map{|r| r['distinctCount']}}]
      [options, report_data, 'Year']
    end

    def self.health_covered_lives_by_age
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {consumer_role_id: {"$ne" => []}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          consumer_role_id: '$consumer_role_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', consumer_role_id: '$consumer_role_id'}, count: {'$sum':1}}},
        {'$group': {_id:{consumer_role_id: '$_id.consumer_role_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      age_hash = {
        '<18'   => {'count'=>0, 'range'=>[0,17]},
        '18-25' => {'count'=>0, 'range'=>[18,25]},
        '26-34' => {'count'=>0, 'range'=>[26,34]},
        '35-44' => {'count'=>0, 'range'=>[35,44]},
        '45-54' => {'count'=>0, 'range'=>[45,54]},
        '55-64' => {'count'=>0, 'range'=>[55,64]},
        '65+'   => {'count'=>0, 'range'=>[65,150]}
      }
      reports.each do |re|
        consumer_role = ConsumerRole.find(re["_id"]["consumer_role_id"].first) rescue nil
        if consumer_role.present?
          age = age_on_next_effective_date(consumer_role.dob)
          age_hash.each do |key, value|
            if age >= value['range'].first && age <= value['range'].last
              age_hash[key]['count'] += re['distinctCount']
            end
          end
        end
      end

      options = age_hash.keys
      report_data = [{name: 'Age', data: age_hash.map{|k, v| v['count']}}]
      [options, report_data, 'Age']
    end

    def self.health_covered_lives_by_gender
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {consumer_role_id: {"$ne" => []}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          consumer_role_id: '$consumer_role_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', consumer_role_id: '$consumer_role_id'}, count: {'$sum':1}}},
        {'$group': {_id:{consumer_role_id: '$_id.consumer_role_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      gender_hash = {
        'male' => 0,
        'female' => 0
      }
      reports.each do |re|
        consumer_role = ConsumerRole.find(re["_id"]["consumer_role_id"].first) rescue nil
        gender_hash[consumer_role.gender] += re['distinctCount'] if consumer_role.present?
      end

      options = gender_hash.keys
      report_data = [{name: 'Gender', data: gender_hash.values}]
      [options, report_data, 'Gender']
    end

    def self.health_covered_lives_by_zipcode
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {consumer_role_id: {"$ne" => []}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          consumer_role_id: '$consumer_role_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', consumer_role_id: '$consumer_role_id'}, count: {'$sum':1}}},
        {'$group': {_id:{consumer_role_id: '$_id.consumer_role_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      zipcode_hash = {}
      reports.each do |re|
        consumer_role = ConsumerRole.find(re["_id"]["consumer_role_id"].first) rescue nil
        if consumer_role.present?
          zipcode = consumer_role.person.home_address.zip rescue nil
          if zipcode.present?
            if zipcode_hash[zipcode].present?
              zipcode_hash[zipcode] += re['distinctCount']
            else
              zipcode_hash[zipcode] = re['distinctCount']
            end
          end
        end
      end
      zips = zipcode_hash.keys.uniq
      zip_site_hash = {}
      zips.each do |zip|
        geo = Geocoder.search(zip)
        if geo.present?
          zip_site_hash[zip] = geo.first.data['geometry']['location'].values
        end
      end

      location_arr = []
      zipcode_hash.each do |zipcode, count|
        location = zip_site_hash[zipcode]
        if zipcode.present?
          count.to_i.times { location_arr << location }
        end
      end

      options = zipcode_hash.keys
      report_data = [{name: 'Zip Code', data: zipcode_hash.values}]
      [options, report_data, 'zipcode', 'zipcode', location_arr]
    end

    def self.health_plans_by_year
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          year: {'$year': "$policy_start_on"},
          plan_id: '$plan_id',
        }},
        {'$group': {_id:{year: '$year', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}
      report_data = [{name: 'year', data: reports.map{|r| r['distinctCount']}}]
      [options, report_data, 'Year']
    end

    def self.health_plans_by_month
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {enrollment_kind: 'special_enrollment'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          month: {'$month': "$policy_start_on"},
        }},
        {'$group': {_id:{month: '$month', hbx_id: '$hbx_id'}, count: {'$sum':1}}},
        #{'$group': {_id:{month: '$_id.month'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.month':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['month']}.uniq
      sep_hash = {}
      reports.each do |re|
        reason = HbxEnrollment.by_hbx_id(re['_id']['hbx_id']).last.special_enrollment_period.qualifying_life_event_kind.reason rescue 'other'
        if sep_hash[reason]
          month = re['_id']['month']
          if sep_hash[reason][month]
            sep_hash[reason][month] += re['count']
          else
            sep_hash[reason][month] = re['count']
          end
        else
          sep_hash[reason] = {}
          sep_hash[reason][month] = re['count']
        end
      end

      report_data = []
      sep_hash.each do |reason, values|
        data = options.map {|m| values[m] || 0}
        report_data << {name: reason, data: data}
      end

      #report_data = [{name: 'month', data: reports.map{|r| r['distinctCount']}}]
      [options, report_data, 'Month', 'double dimensional']
    end

    def self.health_plans_by_member_count
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          member_count: '$member_count',
        }},
        {'$group': {_id:{year: '$year', member_count: '$member_count', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', member_count: '$_id.member_count'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.member_count':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      member_count_options = reports.map{|r| r['_id']['member_count']}.uniq.sort
      report_data = []

      member_count_options.each do |mc|
        report_data_for_year = {name: mc, data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['member_count'] == mc}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end
      [options, report_data, 'Member Count', 'double dimensional']
    end

    def self.health_plans_by_standard
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          is_standard_plan: '$is_standard_plan',
        }},
        {'$group': {_id:{year: '$year', is_standard_plan: '$is_standard_plan', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', is_standard_plan: '$_id.is_standard_plan'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.is_standard_plan':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      standard_options = reports.map{|r| r['_id']['is_standard_plan']}.uniq
      report_data = []
      standard_options.each do |mc|
        report_data_for_year = {name: mc.to_s, data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['is_standard_plan'] == mc}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Standard', 'double dimensional']
    end

    def self.health_plans_by_carrier_profile
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          carrier_profile_id: '$carrier_profile_id',
        }},
        {'$group': {_id:{year: '$year', carrier_profile_id: '$carrier_profile_id', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', carrier_profile_id: '$_id.carrier_profile_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.carrier_profile_id':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      carrier_options = reports.map{|r| r['_id']['carrier_profile_id']}.uniq
      carrier_names = carrier_options.map{|c| CarrierProfile.find(c).try(:legal_name) || c }
      report_data = []
      carrier_options.each_with_index do |op, idx|
        report_data_for_year = {name: carrier_names[idx], data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['carrier_profile_id'] == op}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Carrier', 'double dimensional']
    end

    def self.health_plans_by_metal_level
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          metal_level: '$metal_level',
        }},
        {'$group': {_id:{year: '$year', metal_level: '$metal_level', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', metal_level: '$_id.metal_level'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.metal_level':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      metal_level_options = reports.map{|r| r['_id']['metal_level']}.uniq
      report_data = []
      metal_level_options.each do |op|
        report_data_for_year = {name: op.to_s, data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['metal_level'] == op}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Metal Level', 'double dimensional']
    end

    def self.health_plans_by_plan_type
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {plan_type: {"$ne" => nil}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          plan_type: '$plan_type',
        }},
        {'$group': {_id:{year: '$year', plan_type: '$plan_type', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', plan_type: '$_id.plan_type'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.plan_type':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      plan_type_options = reports.map{|r| r['_id']['plan_type']}.uniq
      report_data = []
      plan_type_options.each do |op|
        report_data_for_year = {name: op.to_s, data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['plan_type'] == op}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Plan Type', 'double dimensional']
    end

    def self.health_plans_by_csr
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {csr_variant_id: {"$ne" => nil}}},
        {'$match': {csr_variant_id: {"$ne" => ''}}},
        {'$project': {
          hbx_id: '$hbx_id',
          year: {'$year': "$policy_start_on"},
          csr_variant_id: '$csr_variant_id',
        }},
        {'$group': {_id:{year: '$year', csr_variant_id: '$csr_variant_id', hbx_id: '$hbx_id'}, count: {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.csr_variant_id':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      csr_variant_id_options = reports.map{|r| r['_id']['csr_variant_id']}.uniq
      report_data = []
      csr_variant_id_options.each do |op|
        report_data_for_year = {name: op.to_s, data:[]}
        options.each do |year|
          #re = reports.detect{|r| r['_id']['year'] == year && r['_id']['csr_variant_id'] == op}
          re_count = reports.select{|r| r['_id']['year'] == year && r['_id']['csr_variant_id'] == op}.select do |r|
            hbx = HbxEnrollment.by_hbx_id(re['_id']['hbx_id']).last rescue nil
            hbx.present? && hbx.applied_aptc_amount > 0
          end.map{|r| r['count']}.reduce(&:+).to_i
          #re_count = re.present? ? re['count'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'CSR', 'double dimensional']
    end

    def self.health_plans_by_name
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          plan_id: '$plan_id',
          plan_name: '$plan_name',
        }},
        {'$group': {_id:{plan_name: '$plan_name', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{plan_name: '$_id.plan_name'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'distinctCount':-1, '_id.plan_name':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['plan_name']}
      report_data = [{name: 'Plan Name', data: reports.map{|r| r['distinctCount']}}]
      [options, report_data, 'Plan Name']
    end

    def self.dental_covered_lives_by_year
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        #{'$match': {coverage_kind: 'dental'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          year: {'$year': "$policy_start_on"},
          hbx_id: '$hbx_id',
          coverage_kind: '$coverage_kind',
          family_id: '$family_id',
        }},
        {'$group': {_id:{year: '$year', coverage_kind: '$coverage_kind', family_id: '$family_id'}, count: {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.family_id':1, '_id.coverage_kind':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      kind_options = ['Health & Dental', 'Dental Only']
      report_data = [{name: 'Health & Dental', data: []}, {name: 'Dental Only', data: []}]

      options.each do |op|
        dental_family_ids = reports.select {|r| r['_id']['year'] == op && r['_id']['coverage_kind']=='dental'}.map{|r| r['_id']['family_id']}
        health_family_ids = reports.select {|r| r['_id']['year'] == op && r['_id']['coverage_kind']=='health'}.map{|r| r['_id']['family_id']}
        dental_and_health_count = (dental_family_ids & health_family_ids).count
        dental_only_count = (dental_family_ids - health_family_ids).count
        report_data.first[:data].push(dental_and_health_count)
        report_data.last[:data].push(dental_only_count)
      end

      [options, report_data, 'Coverage Kind', 'double dimensional']
    end

    def self.dental_covered_lives_by_age
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'dental'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {consumer_role_id: {"$ne" => []}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          consumer_role_id: '$consumer_role_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', consumer_role_id: '$consumer_role_id'}, count: {'$sum':1}}},
        {'$group': {_id:{consumer_role_id: '$_id.consumer_role_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      age_hash = {
        '<18'   => {'count'=>0, 'range'=>[0,17]},
        '18-25' => {'count'=>0, 'range'=>[18,25]},
        '26-34' => {'count'=>0, 'range'=>[26,34]},
        '35-44' => {'count'=>0, 'range'=>[35,44]},
        '45-54' => {'count'=>0, 'range'=>[45,54]},
        '55-64' => {'count'=>0, 'range'=>[55,64]},
        '65+'   => {'count'=>0, 'range'=>[65,150]}
      }
      reports.each do |re|
        consumer_role = ConsumerRole.find(re["_id"]["consumer_role_id"].first) rescue nil
        if consumer_role.present?
          age = age_on_next_effective_date(consumer_role.dob)
          age_hash.each do |key, value|
            if age >= value['range'].first && age <= value['range'].last
              age_hash[key]['count'] += re['distinctCount']
            end
          end
        end
      end

      options = age_hash.keys
      report_data = [{name: 'Age', data: age_hash.map{|k, v| v['count']}}]
      [options, report_data, 'Age']
    end

    def self.dental_covered_lives_by_gender
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'dental'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {consumer_role_id: {"$ne" => []}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          consumer_role_id: '$consumer_role_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', consumer_role_id: '$consumer_role_id'}, count: {'$sum':1}}},
        {'$group': {_id:{consumer_role_id: '$_id.consumer_role_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      gender_hash = {
        'male' => 0,
        'female' => 0
      }
      reports.each do |re|
        consumer_role = ConsumerRole.find(re["_id"]["consumer_role_id"].first) rescue nil
        gender_hash[consumer_role.gender] += re['distinctCount'] if consumer_role.present?
      end

      options = gender_hash.keys
      report_data = [{name: 'Gender', data: gender_hash.values}]
      [options, report_data, 'Gender']
    end

    def self.dental_plans_by_year
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'dental'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          year: {'$year': "$policy_start_on"},
          plan_id: '$plan_id',
        }},
        {'$group': {_id:{year: '$year', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}
      report_data = [{name: 'year', data: reports.map{|r| r['distinctCount']}}]
      [options, report_data, 'Year']
    end

    def self.dental_plans_by_carrier_profile
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'dental'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          carrier_profile_id: '$carrier_profile_id',
        }},
        {'$group': {_id:{year: '$year', carrier_profile_id: '$carrier_profile_id', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', carrier_profile_id: '$_id.carrier_profile_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.carrier_profile_id':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      carrier_options = reports.map{|r| r['_id']['carrier_profile_id']}.uniq
      carrier_names = carrier_options.map{|c| CarrierProfile.find(c).try(:legal_name) || c }
      report_data = []
      carrier_options.each_with_index do |op, idx|
        report_data_for_year = {name: carrier_names[idx], data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['carrier_profile_id'] == op}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Carrier', 'double dimensional']
    end

    def self.dental_plans_by_member_count
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$match': {market: 'individual'}}, 
        {'$match': {coverage_kind: 'dental'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          member_count: '$member_count',
        }},
        {'$group': {_id:{year: '$year', member_count: '$member_count', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', member_count: '$_id.member_count'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.member_count':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      member_count_options = reports.map{|r| r['_id']['member_count']}.uniq
      report_data = []
      member_count_options.each do |op|
        report_data_for_year = {name: op.to_s, data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['member_count'] == op}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Member Count', 'double dimensional']
    end

    def self.shop_enrollments_by_employer
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$ne" => nil}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          benefit_group_id: '$benefit_group_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', benefit_group_id: '$benefit_group_id'}, count: {'$sum':1}}},
        {'$group': {_id:{benefit_group_id: '$_id.benefit_group_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      org_hash = {}
      reports.each do |re|
        bg_id = re['_id']['benefit_group_id']
        bg_id = BSON::ObjectId.from_string(bg_id) if bg_id.is_a? String
        org = Organization.where({hbx_id: {'$nin': ['536002522','526002523','536002558']}}).where({"employer_profile.plan_years.benefit_groups._id" => bg_id }).last rescue nil
        if org.present?
          if org_hash[org.fein].present?
            org_hash[org.fein][1] += re['distinctCount']
          else
            org_hash[org.fein] = [org.legal_name, re['distinctCount']]
          end
        end
      end

      options = org_hash.map {|k, org| org.first }
      report_data = [{name: 'Employer', data: org_hash.map{|k, org| org.last}}]
      [options, report_data, 'Employer']
    end

    def self.shop_enrollments_by_month
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {enrollment_kind: 'special_enrollment'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          month: {'$month': "$policy_start_on"},
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', month: '$month'}, count: {'$sum':1}}},
        {'$sort': {'_id.month':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['month']}.uniq
      sep_hash = {}
      reports.each do |re|
        reason = HbxEnrollment.by_hbx_id(re['_id']['hbx_id']).last.special_enrollment_period.qualifying_life_event_kind.reason rescue 'other'
        if sep_hash[reason]
          month = re['_id']['month']
          if sep_hash[reason][month]
            sep_hash[reason][month] += re['count']
          else
            sep_hash[reason][month] = re['count']
          end
        else
          sep_hash[reason] = {}
          sep_hash[reason][month] = re['count']
        end
      end

      report_data = []
      sep_hash.each do |reason, values|
        data = options.map {|m| values[m] || 0}
        report_data << {name: reason, data: data}
      end

      [options, report_data, 'Month', 'double dimensional']
    end

    def self.shop_enrollments_by_age
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          family_id: '$family_id',
          policy_start_on: '$policy_start_on'
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', family_id: '$family_id', policy_start_on: '$policy_start_on'}, count: {'$sum':1}}},
        {'$group': {_id:{family_id: '$_id.family_id', policy_start_on: '$_id.policy_start_on'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      age_hash = {
        '<18'   => {'count'=>0, 'range'=>[0,17]},
        '18-25' => {'count'=>0, 'range'=>[18,25]},
        '26-34' => {'count'=>0, 'range'=>[26,34]},
        '35-44' => {'count'=>0, 'range'=>[35,44]},
        '45-54' => {'count'=>0, 'range'=>[45,54]},
        '55-64' => {'count'=>0, 'range'=>[55,64]},
        '65+'   => {'count'=>0, 'range'=>[65,150]}
      }
      reports.each do |re|
        family_member = Family.find(re['_id']['family_id']).primary_family_member rescue nil
        if family_member.present?
          age = age_on_next_effective_date(family_member.dob, re['_id']['policy_start_on'])
          age_hash.each do |key, value|
            if age >= value['range'].first && age <= value['range'].last
              age_hash[key]['count'] += re['distinctCount']
            end
          end
        end
      end

      options = age_hash.keys
      report_data = [{name: 'Age', data: age_hash.map{|k, v| v['count']}}]
      [options, report_data, 'Age']
    end

    def self.shop_enrollments_by_gender
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
          family_id: '$family_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id', family_id: '$family_id'}, count: {'$sum':1}}},
        {'$group': {_id:{family_id: '$_id.family_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
      ],
      :allow_disk_use => true).entries

      gender_hash = {
        'male' => 0,
        'female' => 0
      }
      reports.each do |re|
        family_member = Family.find(re['_id']['family_id']).primary_family_member rescue nil
        gender_hash[family_member.gender] += re['distinctCount'] if family_member.present?
      end

      options = gender_hash.keys
      report_data = [{name: 'Gender', data: gender_hash.values}]
      [options, report_data, 'Gender']
    end

    def self.shop_enrollments_by_member_count
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          member_count: '$member_count',
        }},
        {'$group': {_id:{year: '$year', member_count: '$member_count', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', member_count: '$_id.member_count'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.member_count':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      member_count_options = reports.map{|r| r['_id']['member_count']}.uniq.sort
      report_data = []

      member_count_options.each do |mc|
        report_data_for_year = {name: mc, data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['member_count'] == mc}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end
      [options, report_data, 'Member Count', 'double dimensional']
    end

    def self.shop_enrollments_by_carrier_profile
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          carrier_profile_id: '$carrier_profile_id',
        }},
        {'$group': {_id:{year: '$year', carrier_profile_id: '$carrier_profile_id', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', carrier_profile_id: '$_id.carrier_profile_id'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.carrier_profile_id':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      carrier_options = reports.map{|r| r['_id']['carrier_profile_id']}.uniq
      carrier_names = carrier_options.map{|c| CarrierProfile.find(c).try(:legal_name) || c }
      report_data = []
      carrier_options.each_with_index do |op, idx|
        report_data_for_year = {name: carrier_names[idx], data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['carrier_profile_id'] == op}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Carrier', 'double dimensional']
    end

    def self.shop_enrollments_by_metal_level
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$project': {
          plan_id: '$plan_id',
          year: {'$year': "$policy_start_on"},
          metal_level: '$metal_level',
        }},
        {'$group': {_id:{year: '$year', metal_level: '$metal_level', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{year: '$_id.year', metal_level: '$_id.metal_level'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'_id.year':1, '_id.metal_level':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['year']}.uniq
      metal_level_options = reports.map{|r| r['_id']['metal_level']}.uniq
      report_data = []
      metal_level_options.each do |op|
        report_data_for_year = {name: op.to_s, data:[]}
        options.each do |year|
          re = reports.detect{|r| r['_id']['year'] == year && r['_id']['metal_level'] == op}
          re_count = re.present? ? re['distinctCount'] : 0
          report_data_for_year[:data].push(re_count)
        end
        report_data.push(report_data_for_year)
      end

      [options, report_data, 'Metal Level', 'double dimensional']
    end

    def self.shop_enrollments_by_name
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          plan_id: '$plan_id',
          plan_name: '$plan_name',
        }},
        {'$group': {_id:{plan_name: '$plan_name', plan_id: '$plan_id'}, count: {'$sum':1}}},
        {'$group': {_id:{plan_name: '$_id.plan_name'}, 'totalCount': {'$sum': '$count'}, 'distinctCount': {'$sum':1}}},
        {'$sort': {'distinctCount':-1, '_id.plan_name':1}}
      ],
      :allow_disk_use => true).entries

      options = reports.map{|r| r['_id']['plan_name']}
      report_data = [{name: 'Plan Name', data: reports.map{|r| r['distinctCount']}}]
      [options, report_data, 'Plan Name']
    end

    def self.shop_enrollments_by_choice
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          benefit_group_id: '$benefit_group_id',
        }},
        {'$group': {_id:{benefit_group_id: '$benefit_group_id'}, count: {'$sum':1}}},
        {'$sort': {'count':-1, '_id.benefit_group_id':1}}
      ],
      :allow_disk_use => true).entries

      ch_hash = {}
      BenefitGroup::PLAN_OPTION_KINDS.each do |opt|
        ch_hash[opt] = 0
      end
      reports.each do |re|
        bg = BenefitGroup.find(re['_id']['benefit_group_id']) rescue nil
        if bg.present?
          ch_hash[bg.plan_option_kind] += re['count']
        end
      end

      options = ch_hash.keys
      report_data = [{name: 'Employee choice', data: ch_hash.values}]
      [options, report_data, 'Employer choice']
    end

    def self.shop_enrollments_by_contribution
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          hbx_id: '$hbx_id',
        }},
        {'$group': {_id:{hbx_id: '$hbx_id'}, count: {'$sum':1}}},
        #{'$sort': {'count':-1, '_id.hbx_id':1}}
      ],
      :allow_disk_use => true).entries

      contribution_hash = {
        '0-49%'  => {'count'=>0, 'range'=>[0,49]},
        '50-59%' => {'count'=>0, 'range'=>[50,59]},
        '60-69%' => {'count'=>0, 'range'=>[60,69]},
        '70-79%' => {'count'=>0, 'range'=>[70,79]},
        '80-89%' => {'count'=>0, 'range'=>[80,89]},
        '90-100%'=> {'count'=>0, 'range'=>[90,100]},
      }

      reports.each do |re|
        hbx = HbxEnrollment.by_hbx_id(re['_id']['hbx_id']).last rescue nil
        if hbx.present?
          percent = hbx.total_employer_contribution / hbx.total_premium rescue 0
          contribution_hash.each do |key, value|
            if percent >= value['range'].first && percent <= value['range'].last
              contribution_hash[key]['count'] += re['count']
            end
          end
        end
      end

      options = contribution_hash.keys
      report_data = [{name: 'Employer contribution', data: contribution_hash.map{|k, v| v['count']}}]
      [options, report_data, 'Employer contribution']
    end

    def self.shop_enrollments_by_bg_start
      except_bg_ids = Organization.where({hbx_id: {'$in': ['536002522','526002523','536002558']}}).map(&:employer_profile).map(&:plan_years).flatten.map(&:benefit_groups).flatten.map(&:id) rescue []
      reports = ReportSources::HbxEnrollmentStatistic.collection.aggregate([
        {'$unwind': "$benefit_group_id"},
        {'$match': {market: 'shop'}}, 
        {'$match': {coverage_kind: 'health'}}, 
        {'$match': {aasm_state: {'$ne' => 'shopping'}}}, 
        {'$match': {plan_id: {"$ne" => nil}}},
        {'$match': {benefit_group_id: {"$nin" => except_bg_ids}}},
        {'$match': {policy_start_on: {"$gte" => TimeKeeper.date_of_record.at_beginning_of_year}}},
        {'$project': {
          benefit_group_id: '$benefit_group_id',
        }},
        {'$group': {_id:{benefit_group_id: '$benefit_group_id'}, count: {'$sum':1}}},
        {'$sort': {'count':-1, '_id.benefit_group_id':1}}
      ],
      :allow_disk_use => true).entries

      ch_hash = {}
      BenefitGroup::OFFSET_KINDS.each do |opt|
        ch_hash[opt] = 0
      end
      reports.each do |re|
        bg = BenefitGroup.find(re['_id']['benefit_group_id']) rescue nil
        if bg.present?
          ch_hash[bg.effective_on_offset] += re['count']
        end
      end

      options = ['date of hire', "First of the month following date of hire", "First of the month following 30 days", "First of the month following 60 days"]
      report_data = [{name: 'Benefit start', data: ch_hash.values}]
      [options, report_data, 'Benefit start']
    end

    def self.age_on_next_effective_date(dob, today=TimeKeeper.date_of_record)
      today.day <= 15 ? age_on = today.end_of_month + 1.day : age_on = (today + 1.month).end_of_month + 1.day
      age_on.year - dob.year - ((age_on.month > dob.month || (age_on.month == dob.month && age_on.day >= dob.day)) ? 0 : 1)
    end
  end
end
