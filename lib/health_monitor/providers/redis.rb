# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'redis'
require 'json'

module HealthMonitor
  module Providers

    class Redis < Base
      class Configuration
        DEFAULT_HOST = '127.0.0.1'
        DEFAULT_PORT = '6379'

        attr_accessor :host, :port, :connection

        def initialize
          @host = DEFAULT_HOST
          @port = DEFAULT_PORT
        end
      end

      class << self
        private

        def configuration_class
          ::HealthMonitor::Providers::Redis::Configuration
        end
      end

      STAT = %w[
        tcp_port
        uptime_in_seconds
        connected_clients
        blocked_clients
        used_memory
        total_system_memory
        instantaneous_input_kbps
        instantaneous_output_kbps
        rdb_changes_since_last_save
        total_conncetions_recieved
        total_commands_processed
        rejected_connections
      ].freeze

      STATUSES = {
        ok: 'OK',
        error: 'ERROR'
      }.freeze

      def redis
        @redis = configuration.connection || ::Redis.new(host: configuration.host, port: configuration.port)
      end

      def redis_check
        redis
        if check_keys.nil?
          if initial_test?
            STATUSES[:ok]
          else
            STATUSES[:error]
          end
        else
          STATUSES[:ok]
        end
      rescue StandardError
        STATUSES[:error]
      end

      def initial_test?
        @redis.setex('test', 5, 'testString')
        @redis.get('test').equal?('testString')
      end

      def check_keys
        @redis.keys.count
      end

      def fetch_info
        @redis.info
      end

      def check!
        @result = {}
        @result.store('status', redis_check)
        fetch_stats(fetch_info)
      rescue StandardError => e
        @result.store('message', e.message)
      ensure
        @result.store('keys', check_keys) unless check_keys.nil?
        @redis.close
        return @result
      end

      def fetch_stats(info)
        STAT.each do |stat|
          @result[stat] = info[stat]
        end
      end

    end
  end
end
