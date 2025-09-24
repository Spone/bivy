# frozen_string_literal: true

require "active_job"

module Bivy
  module Jobs
    class BaseJob < ActiveJob::Base
      # Base class for all Bivy background jobs
      # Provides common functionality and configuration for indexing jobs

      queue_as :default
    end
  end
end
