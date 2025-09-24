# frozen_string_literal: true

module Bivy
  module Callbacks
    class AfterDestroyCommit
      class << self
        def after_commit(record)
          Bivy::Jobs::RecordJob.perform_later(record, :bivy_destroy)
        end
      end
    end
  end
end
