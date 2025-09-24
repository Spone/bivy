# frozen_string_literal: true

module Bivy
  module Callbacks
    class AfterSaveCommit
      class << self
        def after_commit(record)
          Bivy::Jobs::RecordJob.perform_later(record, :bivy_save)
        end
      end
    end
  end
end
