class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    <%= begin
      ToombilaSchemaDumper.dump_table(table_name, StringIO.new).string
    rescue Exception => e
      puts e.message
      ''
    end -%>
#    create_table :<%= table_name %> do |t|
<% for attribute in attributes -%>
#      t.column :<%= attribute.name %>, :<%= attribute.type %>
<% end -%>
#    end
  end

  def self.down
    drop_table :<%= table_name %> #rescue nil 
  end
end
