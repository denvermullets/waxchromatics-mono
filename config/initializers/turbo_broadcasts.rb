Rails.application.config.after_initialize do
  Turbo::Streams::BroadcastStreamJob.queue_as :messaging
  Turbo::Streams::ActionBroadcastJob.queue_as :messaging
end
