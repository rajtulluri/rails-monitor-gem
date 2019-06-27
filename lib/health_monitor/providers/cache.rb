# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'benchmark'

module HealthMonitor
  module Providers

    class Cache < Base

      STATUSES = {
        ok: 'OK',
        error: 'ERROR'
      }.freeze


      def cache_io
        start_time = time
        Rails.cache.write(key, start_time)
        if Rails.cache.read(key).equal?(start_time)
          @result.store('latency', time - start_time)
          STATUSES[:ok]
        else
          raise StandardError
        end
      rescue StandardError => e
        @result.store('message', e.message)
        STATUSES[:error]
      end

      def key
        @key ||= 'Periodic health test of cache memory'
      end

      def time
        Time.now
      end

      def check!
        @result = {}
        @result.store('status', cache_io)
        final_result = { 'Cache' => @result }
      end
    end
  end
end
