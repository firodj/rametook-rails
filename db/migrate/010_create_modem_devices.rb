class CreateModemDevices < ActiveRecord::Migration
  def self.up
      create_table "modem_devices", :force => true do |t|
    t.column "identifier",     :string
    t.column "modem_type_id",  :integer
    t.column "device",         :string
    t.column "hostname",       :string
    t.column "appname",        :string
    t.column "baudrate",       :integer
    t.column "databits",       :integer
    t.column "stopbits",       :integer
    t.column "parity",         :integer
    t.column "active",         :integer
    t.column "init_command",   :string
    t.column "signal_quality", :integer
    t.column "last_refresh",   :datetime
  end

#    create_table :modem_devices do |t|
#    end
  end

  def self.down
    drop_table :modem_devices #rescue nil 
  end
end
