# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'net/http'
require 'json'

module HealthMonitor
  module Providers

    class RailGun < Base

      STATUSES = {
        ok: 'OK',
        error: 'ERROR'
      }.freeze

      DEFAULT_URL = 'http://localhost:3000'.freeze

      def initialize(req_url = nil)
        @count=0
        @avg=0
        @rescode={}
        @result={}
        @url = req_url || DEFAULT_URL
      end

      def check!
        cal_lat()
        cal_codes()
        show_count()
        @result.store('status', STATUSES[:ok])
      rescue StandardError => e
        @result.store('status', STATUSES[:error])
        @result.store('message', e.message)
      ensure
        return @result
      end

      def cal_lat
        @count+=1
        @start = Time.now
        uri = URI(@url)
        @res = Net::HTTP.get_response(uri)
        @latency = Time.now - @start
        @avg+=@latency
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
        ratecall()
        totdur = @avg
        @avg/=@count
        @result.store('Count', @count)
        @result.store('Total Duration', totdur)
        @result.store('Average Latency', @avg)
      end

    end
  end
end
