# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'active_support/core_ext/hash'

module HealthMonitor
  module Providers

    class Sql < Base

      STATUSES = {
        ok: 'OK',
        error: 'ERROR'
      }.freeze

      def connect
        @environment = ENV['RACK_ENV'] || 'development'
        @dbconfig = YAML.load(File.read('config/database.yml'))
        ActiveRecord::Base.establish_connection @dbconfig[@environment]
        #ActiveRecord::Base.connection.current_database
      end

      def check!
        result = {}
        connect
        result.store('status', STATUSES[:ok])
      rescue StandardError => e
        result.store('status', STATUSES[:error])
        result.store('message', e.message)
      ensure
        ActiveRecord::Base.remove_connection
        result.store('name', 'Database')
        return result
      end

    end
  end
end
