amqp_environment_name = "prod"
window_start = Time.now.midnight - 1.day
window_end = Time.now.midnight
coverage_start_window = Date.new(2016,9,1)
qs = Queries::PolicyAggregationPipeline.new

qs.filter_to_individual.filter_to_active.with_effective_date({"$gt" => coverage_start_window, "$lt" => Date.new(2017,1,1)}).eliminate_family_duplicates

qs.add({ "$match" => {"policy_purchased_at" => {"$gte" => window_start, "$lt" => window_end}}})

enroll_pol_ids = []

qs.evaluate.each do |r|
  if r['policy_purchased_at'] > window_start
    enroll_pol_ids << r['hbx_id']
  end
end

active_selection_new_enrollments = []

enroll_pol_ids.each do |m|
  pol = HbxEnrollment.by_hbx_id(m).first
  if pol.subscriber.present?
      active_selection_new_enrollments << m
  end
end

remote_broker_uri = Rails.application.config.acapi.remote_broker_uri
target_queue = "dc0.#{amqp_environment_name}.q.gluedb.enrollment_query_result_handler"

conn = Bunny.new(remote_broker_uri, :heartbeat => 15)
conn.start
chan = conn.create_channel
chan.confirm_select
dex = chan.default_exchange
active_selection_new_enrollments.each do |pol_id|
 dex.publish(
   "",
   {
     :routing_key => target_queue,
     :headers => {
       "hbx_enrollment_id" => pol_id.to_s,
       "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#initial"
     }
   }
 )
 chan.wait_for_confirms
end
conn.close