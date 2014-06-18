module Toombila

  module ActiveRecordCalculations
    def self.included(base) #:nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods
      # options is a hash which keys:
      # :selects : a SQL fragment for SELECT clause like {:element => 'opex_rkm_activities.opex_rkm_unit_id', :sum_cost => 'SUM(`cost`)'}, key and value pairs of field-alias and select-statment
      # :conditions : a SQL fragment for WHERE clause like ["user_name = ?", username]
      # :joins : a SQL fragment for JOIN clause like {'opex_activities' => nil, 'opex_rkm_activities' => 'opex_activities'}, key and value pairs of join-to-table and join-from-table
      # :groups : a SQL fragment for GROUP BY clause like [:segment, :cc], array of field-alias (see options[:selects])
      # :rollups : array/hash of string/symbol like [{:department => :monthly}, :monthly] for rolling up calculate. String/symbol in key or value is field-alias (see options[:selects])
      # :share : other CalcQuery instance for share result calculation, sharing roll-ups
      # :finish : a Proc callback when rolling up
      def summary(options = {})
        Toombila::SummaryCalculations::Query.new(self, options)
      end
    end
  end
  
end
