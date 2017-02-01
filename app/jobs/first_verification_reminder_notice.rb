class FirstVerificationReminderNotice < ActiveJob::Base
  queue_as :default

  def perform(consumer_role_id)
    Resque.logger.level = Logger::DEBUG
    consumer_role = ConsumerRole.find(consumer_role_id)
    event_kind = ApplicationEventKind.where(:event_name => "first_verifications_reminder").first
    notice_trigger = event_kind.notice_triggers.first
    builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver

  end
end