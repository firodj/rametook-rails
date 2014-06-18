# UPDATED: 25 Agustus 2008
module Toombila
module SummaryCalculations
  class ValueType
    COUNT = :count
    SUM = :sum
    MAX = :max
    MIN = :mix 
    INDEX = :index 
    
    def self.by_name(name, is_function = true)
      case name
        when /^count/i
          COUNT
        when /^sum/i
          SUM
        when /^max/i
          MAX
        when /^min/i
          MIN
        when /_id$/i 
          INDEX     
      end
    end
    
    def self.by_field(field)
      case field
        when /count\(.*?\)/i
          COUNT
        when /sum\(.*?\)/i
          SUM
        when /max\(.*?\)/i
          MAX
        when /min\(.*?\)/i
          MIN
        when /_id[^0-9a-z_.]$/i 
          INDEX   
      end
    end
    
    def self.build(names = [])
      value_types = {}
      names.each do |k|
        vtype = by_name(k.to_s)
        value_types[k] = vtype if vtype
      end
      value_types
    end
  end
  
  # used by Query.results
  class QueryResult
    attr_reader :name, :index, :groups, :values, :value_types
    
    def initialize(name, index, sub_categories = [], values = {}, value_types = nil)
      @name = name
      @index = index
      @groups = {}
      sub_categories.each { |n| @groups[n] = {} }
      @values = {}
      @value_types = value_types || ValueType.build(values.keys)
      add_values_by(values)
    end
    
    def empty?
      @name == nil && @index == nil && @groups.empty?
    end
        
    def add(name, index, sub_categories = [], values = {}) #, value_types = nil)
      return nil if not @groups.has_key?(name)
      if @groups[name].has_key?(index) then
        @groups[name][index].add_values_by(values)
      else
        @groups[name][index] = QueryResult.new(name, index, sub_categories, values, @value_types) # value_types || @...
      end        
      @groups[name][index]
    end
    
    # after_rollup : Proc with 1 argument (this QueryResult) will be called at the end
    def rollup(after_rollup = nil)
      unless @groups.empty? then #zgroups
        k_first = nil
        @groups.each_key do |k| #zgroups
          k_first = k if k_first.nil? # remove duplicate calculete with this
          
          @groups[k].each_value do |e| # e is QueryResult
            e.rollup(after_rollup)            
            add_values_by(e.values) if k == k_first 
          end if @groups.has_key?(k)
        end
      end
      after_rollup.call(self) if after_rollup.class <= Proc
      # puts "#{@name}.#{@index}"
    end    
  
    # values : hash of values to be added, field-alias and field-value pairs
    def add_values_by(values)
      @value_types.each_key do |k|    
        next if values[k].nil?
        
        if not @values.has_key?(k) then
          @values[k] = 0 
        end
        
        case @value_types[k]
          when ValueType::COUNT
            @values[k] += values[k].to_i            
          when ValueType::SUM
            @values[k] += values[k].to_f
          when ValueType::MAX
            @values[k] = values[k].to_f if values[k] > @values[k]
          when ValueType::MIN
            @values[k] = values[k].to_f if values[k] < @values[k]
        end
      end
    end
    
    def values_get(name)
      @values.has_key?(name) ? @values[name] : 0    
    end
  end
  
  # used by Query.rollups
  class QueryCategorize
    attr_reader :name, :parent, :sub_categories
    
    # name : nil/field-alises in rollup
    # parent : other QueryCategorize
    def initialize(name, parent = nil)
      @sub_categories = {} # hash of QueryCatogirize.name => QueryCatogorize
      @name = name
      @parent = parent
      if @parent then
        @parent.sub_categories[name] = self
      end
    end
  end
  
  class QueryJoin
    attr_reader :index, :reflect_list, :model, :join_from, :join_reflection
    def initialize(index, reflect_list, model_or_reflection, join_from = nil)
      @index = index
      @reflect_list = reflect_list
      
      @join_from = join_from
      
      @model = model_or_reflection
      
      case @model
        when ActiveRecord::Base
          @join_reflection = nil
        when ActiveRecord::Reflection::AssociationReflection
          @join_reflection = model_or_reflection
          @model = @join_reflection.class_name.constantize
      end
    end
    
    def to_s
      if @join_reflection then
        #WARNING: only belongs_to
        join_condition = case @join_reflection.macro
          when :belongs_to
            "t#{@index}.`#{@model.primary_key}` = t#{@join_from.index}.`#{@join_reflection.primary_key_name}`"
          when :has_many
            "t#{@join_from.index}.`#{@join_from.model.primary_key}` = t#{@index}.`#{@join_reflection.primary_key_name}`"
        end
        "LEFT OUTER JOIN `#{@model.table_name}` AS t#{@index} ON #{join_condition}"
      else
        "`#{@model.table_name}` AS t#{@index}"
      end
    end
  end
  
  class Query    
    attr_reader :sql, :results, :groups, :rollups, :results
    
    # model: an ActiveRecord::Base model, also for FROM caluse in a SQL fragement
    # options is a hash which keys:
    # :selects : a SQL fragment for SELECT clause like {:element => 'opex_rkm_activities.opex_rkm_unit_id', :sum_cost => 'SUM(`cost`)'}, key and value pairs of field-alias and select-statment
    # :conditions : a SQL fragment for WHERE clause like ["user_name = ?", username]
    # :groups : a SQL fragment for GROUP BY clause like [:segment, :cc], array of field-alias (see options[:selects])
    # :rollups : array/hash of string/symbol like [{:department => :monthly}, :monthly] for rolling up calculate. String/symbol in key or value is field-alias (see options[:selects])
    # :share : other Query instance for share result calculation, sharing roll-ups
    # :finish : a Proc callback when rolling up
    def initialize(model, options={})
      @model = model
      
      @share = options[:share]  
      @finish = options[:finish] 
      @groups = options[:groups] || (@share.nil? ? [] : @share.groups)
      @joins  = [ QueryJoin.new(0, [], @model) ]
      @assocs = { @joins.last.reflect_list => @joins.last }
      
      #build_joins( options[:joins] || {} )
      value_types = build_selects( options[:selects] || {} )
      build_conditions( options[:conditions] || [] )
      
      if @share then 
        @rollups = @share.rollups
        @results = @share.results
        @results.value_types.update value_types
      else
        @rollups = QueryCategorize.new(nil) # create a root, @rollups, hold collection of QueryCategorize
        build_rollups( options[:rollups] || [], @rollups )        
        @results = QueryResult.new(nil, nil, @rollups.sub_categories.keys, {}, value_types)
      end
      
      @sql = construct_sql    
    end
    
    def execute(rollup = true)
      rows = nil
      tq, tc, tr = nil, nil, nil
      tq = Benchmark.measure('query') { rows = @model.connection.select_all(@sql) }
      tc = Benchmark.measure('collect') { rows.each { |record| merge_result(@rollups, @results, record) } }
      tr = Benchmark.measure('rollup') { @results.rollup(@finish) } if rollup
      [tq, tc, tr]
    end

    private
    
    def construct_sql()
      select_fields = []
      @selects.keys.each { |k| select_fields << @selects[k] + " AS `#{k}`" }
      
      sql = "SELECT #{select_fields.join(', ')} FROM #{@joins.join(' ')} "
      sql += "WHERE #{@conditions} " unless @conditions.empty?
      sql += "GROUP BY " + @groups.map{ |k| "`#{k}`" }.join(', ')
      sql
    end
    
    # TODO become assoc
    # field : an SQL select-statment
    # if field is 'opex_rkm_activities.opex_rkm_unit_id', then it should become:
    #   table_name = 'opex_rkm_activities'
    #   name = 'opex_rkm_unit_id'
    #   function = nil
    # if field is 'SUM(`cost`)', then it should become:
    #  table_name = @model.table_name
    #  name = 'cost'
    #  function = 'SUM(?)'
    def transform_field(field)
      field = field.to_s
      
      # see if field consists of SQL function, then get table-field inside ``
      field.scan(/\`[a-z0-9_\.]+\`/i).uniq.each do |field_scan|
        
        j, f = parse_assoc_field( field_scan[1...-1] )

        if j then         
          field.gsub!(field_scan, "t#{j.index}.`#{f}`")
        else
          puts "WARNING: uknown #{field_scan}"
        end
      end
      
      field
    end
    
    def parse_assoc_field(field)
      assocs = field.split('.')
		  field = assocs.pop
		  assocs.shift if assocs.first == 'self'
		  
		  #puts "scanned: #{field} #{assocs.inspect}"
		  unless @assocs[ assocs ] then
		    l = @joins.first
		    s = []
		    assocs.each { |deep|
		      s << deep
		      unless @assocs[ s ] then
		        r = l.model.reflections[deep.to_sym] #WARNING: only belongs_to
		        return if r.nil?
		        @joins << QueryJoin.new(@joins.size, s, r, l)
		        @assocs[ @joins.last.reflect_list ] = @joins.last
		      end
		      l = @assocs[ s ]
		    }
		  end
		  return if @assocs[ assocs ].model.columns_hash[field].nil?
		  [ @assocs[ assocs ], field ]
    end
    
    # borrowed from JoinDependency#build (find options[:include])
    # recurse function
    # rollups : see options[:rollups]
    def build_rollups(rollups, parent)
      case rollups
        when String, Symbol
          QueryCategorize.new(rollups, parent)
        when Array
          rollups.each do |r|
            build_rollups(r, parent)
          end
        when Hash
          rollups.each_pair do |k,r|
            build_rollups(r, build_rollups(k, parent) )
          end
      end      
    end
    
    # selects : see options[:select]
    # as a result, instance variable @selects being set
    def build_selects(selects)
      @selects = {}
      value_types = {}
      selects.each do |k,v|
        @selects[k] = transform_field(v)
        if not @groups.include?(k) then
          vtype = ValueType.by_name(k) || ValueType.by_field(@selects[k])
          value_types[k.to_s] = vtype if vtype
        end
      end
      value_types
    end
    
    # conditions : see options[:conditions]
    # as a result, instance variable @conditions being set, hash of SQL string
    def build_conditions(conditions)
      @conditions = ''
      return if conditions.empty?
      
      @conditions = transform_field(conditions[0])
      
      for i in (1...conditions.size) do
        @conditions.sub!('?', "'"+@model.connection.quote_string(conditions[i].to_s)+"'")
      end   
    end

    #    
    def merge_result(rollup, result, record)      
      rollup.sub_categories.each_pair do |k,r|
        t = result.add(k, record[k.to_s].to_i, r.sub_categories.keys, {}) #, @value_types)
        # t.groups is from result, r.sub_categories is from rollup
        if t.groups.empty? # only add at the node not when in branch
          t.add_values_by(record) #, @value_types)
        else
          merge_result(r, t, record)
        end
      end
    end
  end

end # SummaryCalculations
end # Toombila
