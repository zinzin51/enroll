require "rails_helper"

describe Events::ResidencyVerificationRequestsController do
  describe "#call with a person" do
    let(:person) { double(hbx_id: "123") }
    let(:outbound_event_name) { "acapi.info.events.residency.verification_request" }
    let(:rendered_template) { double }
    let(:mock_end_time) { (mock_now + 24.hours).to_i }
    let(:mock_now) { Time.mktime(2015,5,21,12,29,39) }

    it "should send out a message to the bus with the request to validate ssa" do
      @event_name = ""
      @body = nil
      event_subscriber = ActiveSupport::Notifications.subscribe(outbound_event_name) do |e_name, s_at, e_at, m_id, payload|
        @event_name = e_name
        @body = payload
      end
      allow(TimeKeeper).to receive(:datetime_of_record).and_return(mock_now)
      expect(controller).to receive(:render_to_string).with(
        "events/residency/verification_request", {:formats => ["xml"], :locals => {
         :individual => person
        }}).and_return(rendered_template)
      controller.call(ConsumerRole::RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, nil, nil, nil, {:person => person} )
      ActiveSupport::Notifications.unsubscribe(event_subscriber)
      expect(@event_name).to eq outbound_event_name
      expect(@body).to eq ({:body => rendered_template, :individual_id => person.hbx_id, :retry_deadline => mock_end_time})
    end
  end
end
