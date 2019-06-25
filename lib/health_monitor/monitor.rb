# frozen_string_literal: true

require 'health_monitor/configuration'

module HealthMonitor
  extend self

  attr_accessor :configuration

  def configure
    self.configuration = Configuration.new

    yield configuration if block_given?
  end

  def check(request: nil, params: {})
    providers = configuration.providers
    if params[:providers].present?
      providers = providers.select { |provider| params[:providers].include?(provider.provider_name.downcase) }
    end

    results = providers.map { |provider| provider_result(provider, request) }
    {
      results: results,
      timestamp: Time.now.to_s(:rfc2822)
    }
  end

  private

  def provider_result(provider, request)
    monitor = provider.new(request: request)
    monitor.check!
  end
end

HealthMonitor.configure
