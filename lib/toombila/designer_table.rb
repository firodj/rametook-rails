module Toombila
  class DesignerTable
    EnumColumnTypes = [:primary_key, 
    :string, :text, 
    :integer, :float, :decimal, 
    :datetime, :timestamp, :time, :date, 
    :binary, :boolean]
    
    def self.connection
      ActiveRecord::Base.connection
    end
    
    def self.find_all_tables
      connection.tables.sort
    end
    
    def initialize(name)
      @connection = self.class.connection
      
      if @connection.tables.include?(name) then  
        if @connection.respond_to?(:pk_and_sequence_for)
          pk, pk_seq = @connection.pk_and_sequence_for(table_name)
        end
        pk ||= 'id'

        @name    = name
        @pk      = pk
      end
    end
    
    def name
      @name
    end
    
    def columns
       @columns ||= @connection.columns(name)
       @columns
    end
    
    def extras
      unless @extras then
        @extras = {}
        @connection.select_all("SHOW COLUMNS FROM `#{name}`").each { |column|
          @extras[column['Field']] = column if !column['Key'].nil? && !column['Key'].empty?
        }
      end
      @extras
    end
    
    def self.correct_name(name)
      name.downcase.gsub(/\A[^a-z]|[^_a-z0-9]+/, '_')
    end
    
    def self.create_table(name)
      begin
        connection.create_table(name, :id => true) do |t|
        end
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end
    
    def self.rename_table(name, new_name)
      begin
        connection.rename_table(name, new_name)
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end

    def self.drop_table(name)
      begin
        connection.drop_table(name)
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end
    
    def add_column(name, type = :string, options = {})
      begin
        @connection.add_column(@name, name, type, options)
        @columns = nil
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end
    
    def change_column(name, type, options = {})
      begin
        if name == :primary_key then
          result = change_column(name, :integer, {:default => nil})
          return result if result != true
        end
        
        @connection.change_column(@name, name, type, options)
        @columns = nil
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end
    
    def rename_column(name, new_name)
      begin
        @connection.rename_column(@name, name, new_name)
        @columns = nil
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end
    
    def move_column(from, to)
      return if from == to
      begin
        # MySQL (rename_column)
        current_type = @connection.select_one("SHOW COLUMNS FROM `#{@name}` LIKE '#{from}'")["Type"]
        @connection.execute "ALTER TABLE `#{@name}` CHANGE `#{from}` `#{from}` #{current_type} " + (to.empty? ? 'FIRST' : "AFTER `#{to}`")
        @columns = nil
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end
    
    def remove_column(name)
      begin
        @connection.remove_column(@name, name)
        @columns = nil
        true
      rescue Exception => e # ActiveRecord::StatementInvalid
        e.message
      end
    end    
    
    # SHOW COLUMNS FROM `#{table}` 
    # SHOW FIELDS FROM #{table_name}"
    
    def drop_primary_key
      begin
        @connection.execute "ALTER TABLE `#{@name}` DROP PRIMARY KEY"
        @columns = nil
        true
      rescue Exception => e
        e.message
      end
    end
  end
end
