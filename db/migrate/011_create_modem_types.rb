class CreateModemTypes < ActiveRecord::Migration
  def self.up
      create_table "modem_types", :force => true do |t|
    t.column "name",         :string
    t.column "pdu_mode",     :boolean
    t.column "init_command", :string
  end

#    create_table :modem_types do |t|
#    end
  end

  def self.down
    drop_table :modem_types #rescue nil 
  end
end
