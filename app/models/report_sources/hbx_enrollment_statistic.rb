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
  end
end
