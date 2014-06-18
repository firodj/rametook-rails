class CreateSmsOutboxGroups < ActiveRecord::Migration
  def self.up
    create_table :sms_outbox_groups do |t|
    end
  end

  def self.down
    drop_table :sms_outbox_groups
  end
end
