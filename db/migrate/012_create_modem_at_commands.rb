class CreateModemAtCommands < ActiveRecord::Migration
  def self.up
    create_table :modem_at_commands do |t|
    end
  end

  def self.down
    drop_table :modem_at_commands
  end
end
