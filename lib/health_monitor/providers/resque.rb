# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'resque'

module HealthMonitor
  module Providers

    class Resque < Base

      STATUSES = {
        ok: 'OK',
        error: 'ERROR'
      }.freeze


      def resque_check!
        status(STATUSES[:ok])
        @result.merge!(::Resque.info)
      rescue StandardError => e
        status(STATUSES[:error])
        message(e.message)
      end

      def status(arg)
        @result.store('status', arg)
      end

      def message(msg)
        @result.store('message', msg)
      end

      def check!
        @result = {}
        resque_check!
        final_result = { 'Resque' => @result }
      end

    end
  end
end
