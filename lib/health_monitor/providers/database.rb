# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'active_support/core_ext/hash'


module HealthMonitor
  module Providers

    class Database < Base

      def check!
        return
      end

    end
  end
end
