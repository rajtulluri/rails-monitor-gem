# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'net/http'

module HealthMonitor
  module Providers

    class RailGun < Base
      class Configuration


        #if url.nil?
        attr_accessor :url

        def initialize
          @url = []
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

      DEFAULT_URL='http://localhost:3000'

      def vars
        $ctr = 0 if $ctr.nil?
        $totdur = 0 if $totdur.nil?
        puts "#{$ctr} ---- #{$totdur}"
        @result = {}
      end

      def check!
        @output = Hash.new{|hsh,key| hsh[key] = {} }
        configuration.url.each do |url|
          vars
          cal_lat(url)
          show_count
      rescue StandardError => e
        @result.store('status', STATUSES[:error])
        @result.store('message', e.message)
      ensure
        @result.store('name', 'Rails app')
        @output.store(url, @result)
        end
        return @output
      end

      def cal_lat(connection = DEFAULT_URL)
        $ctr += 1
        start = Time.now
        @uri = URI(connection)
        @res = Net::HTTP.get_response(@uri)
        @latency = Time.now - start
        $totdur += @latency
        @result.store('Status Codes', @res.code)
        if @res.code != "200"
          @result.store('status', STATUSES[:error])
          @result.store('message', @res.message)
        else
          @result.store('status', STATUSES[:ok])
        end
      end

      def ratecall
        rpmo = @latency/60.to_f
        rpmf = @latency/300.to_f
        @result.store('One Minute Rate', rpmo)
        @result.store('Five Minute Rate', rpmf)
      end

      def show_count
        ratecall
        avg = $totdur/$ctr
        @result.store('Count', $ctr)
        @result.store('Total Duration', $totdur)
        @result.store('Average Latency', avg)
      end

    end
  end
end
