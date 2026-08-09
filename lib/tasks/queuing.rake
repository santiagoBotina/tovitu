# frozen_string_literal: true

namespace :queuing do
  desc "Consume SQS queues and execute jobs (long-poll; Ctrl-C to stop)"
  task work: :environment do
    Queuing::Worker.new.run
  end
end
