# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'net/http'

module HealthMonitor
  module Providers

    class RailGun < Base
      class Configuration
        DEFAULT_URL='http://localhost:3000'

        attr_accessor :url

        def initialize
          @url = DEFAULT_URL
        end
      end

      class << self
        private

        def configuration_class
          ::HealthMonitor::Providers::RailGun::Configuration
        end
      end

      STATUSES = {
        ok: 'OK',
        error: 'ERROR'
      }.freeze

      def vars
        @ctr=0
        @avg=0
        @rescode={}
        @result = {}
      end

      def check!
        vars
        cal_lat
        cal_codes
        show_count
        @result.store('status', STATUSES[:ok])
      rescue StandardError => e
        @result.store('status', STATUSES[:error])
        @result.store('message', e.message)
      ensure
        @result.store('name', 'Rails app')
        return @result
      end

      def connection
        configuration.url || 'http://localhost:3000'
      end

      def cal_lat
        @ctr += 1
        start = Time.now
        uri = URI(connection)
        @res = Net::HTTP.get_response(uri)
        @latency = Time.now - start
        @avg += @latency
      end

      def cal_codes
        if @rescode.key?(@res.code)
          @rescode[@res.code]+=1
        else
          @rescode.store(@res.code,1)
        end
        @result.store('Status Codes', @rescode)
      end

      def ratecall
        rpmo = @latency/60.to_f
        rpmf = @latency/300.to_f
        @result.store('One Minute Rate', rpmo)
        @result.store('Five Minute Rate', rpmf)
      end

      def show_count
        ratecall
        totdur = @avg
        @avg /= @ctr
        @result.store('Count', @ctr)
        @result.store('Total Duration', totdur)
        @result.store('Average Latency', @avg)
      end

    end
  end
end
