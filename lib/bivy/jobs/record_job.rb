# frozen_string_literal: true

module Bivy
  module Jobs
    class RecordJob < Bivy::Jobs::BaseJob
      def perform(object, method)
        object.send(method)
      end
    end
  end
end
