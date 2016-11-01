require 'csv'

namespace :qle do
  desc "Add a new SEP"
  task add_new_sep: :environment do
    QualifyingLifeEventKind.create!(
        title: "Agent Broker Info",
        tool_tip: "",
        action_kind: "",
        reason: "",
        edi_code: "",
        market_kind: "",
        effective_on_kinds: [""],
        pre_event_sep_in_days: 0,
        post_event_sep_in_days: 30,
        is_self_attested: true,
        ordinal_position: 25,
        event_kind_label: ''
    )
  end
end