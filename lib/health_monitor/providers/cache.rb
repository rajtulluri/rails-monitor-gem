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

      def initialize
        @result = {}
      end

      def cache_check!
        test = Benchmark.bm do |x|
          x.report('Caching: '){
            100.times { cache_io }
          }
        end
        JSON.generate(test)
      end

      def cache_io
        Rails.cache.write(key, time)
        if Rails.cache.read(key).equal?(time)
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
        Time.now.to_s
      end

      def check!
        @result.store('status', cache_check!)
        @result
      end
    end
  end
end
