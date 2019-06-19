# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'active_support/core_ext/hash'
require 'json'
require 'mysql'

module HealthMonitor
  module Providers

    class Sql < Base

      STATUSES = {
        ok: 'OK',
        error: 'ERROR'
      }.freeze

      def initialize(host,user,pass,port)
        @dbh = Mysql.real_connect(host, user, pass, "information_schema", port, "/var/run/mysqld/mysqld.sock", 0)
        @result = {}
      end

      def databaser #List the number of dbs, lists them, and gives the id, name of the db along with the number of tables in each db
        dbnum=0
        db_lst = []
        @dbh.list_dbs.each do |dbl|
          db_lst << dbl
          dbnum += 1
        end
        @result.store('db_count', dbnum)
        @result.store('db_list', db_lst)
        rs = @dbh.query   "SELECT IFNULL(table_schema,'Total') 'Database',TableCount FROM (SELECT COUNT(1) TableCount,table_schema FROM information_schema.tables WHERE table_schema NOT IN ('information_schema','mysql', 'performance_schema', 'sys') GROUP BY table_schema WITH ROLLUP) A;"
        rs.each_hash do |tab|
          @result.store(db_name(tab), tab['TableCount'])
        end
      end

      def db_name(arg)
        arg['Database'] + '_tableCount'
      end

      def proclister #Lists all the processes of all users
        pl = @dbh.query "show processlist;"
        pl.each_hash do |pcl|
          @result.store(pcl['db'], pcl.except!('db'))
        end
        pl = @dbh.query "show status like '%onn%';"
        pl.each_hash do |pcl|
          @result.store(pcl['Variable_name'],pcl['Value'])
        end
      end

      def check!
        databaser
        proclister
        @dbh.close
        @result.store('status', STATUSES[:ok])
      rescue StandardError => e #Handles errors if any
        @result.store('status', STATUSES[:error])
        @result.store('message', e.message)
      ensure
        return @result
      end

    end
  end
end
