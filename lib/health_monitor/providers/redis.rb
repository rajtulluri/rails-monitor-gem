# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'redis'

module HealthMonitor
  module Providers

    class Redis < Base
      class Configuration

        attr_accessor :connection

        def initialize
          @connection = []
        end
      end

      class << self
        private

        def configuration_class
          ::HealthMonitor::Providers::Redis::Configuration
        end
      end

      DEFAULT_HOST = 'localhost'
      DEFAULT_PORT = '6379'

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

      def parse_url(instance)
        instance.split(':')
      end

      def redis_connection(host = DEFAULT_HOST, port = DEFAULT_PORT)
        @redis = ::Redis.new(host: host, port: port)
      rescue CannotConnectError => e
        @result.store('message', e.message)
      end

      def redis_check
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

      def connect(instance)
        connection = parse_url(instance)
        redis_connection(connection[0], connection[1])
      end

      def check!
        final_result = {}
        configuration.connection.each do |instance|
          @result = {}
          connect(instance)
          @result.store('status', redis_check)
          @result.store('keys', check_keys) unless check_keys.nil?
          fetch_stats(fetch_info)
        rescue StandardError => e
          @result.store('message', e.message)
        ensure
          final_result.store("Redis:#{instance}", @result)
          @redis.close
        end
        final_result
      end

      def fetch_stats(info)
        STAT.each do |stat|
          @result[stat] = info[stat]
        end
      end

    end
  end
end
