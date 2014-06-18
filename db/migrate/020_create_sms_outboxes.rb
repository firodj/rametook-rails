class CreateSmsOutboxes < ActiveRecord::Migration
  def self.up
      create_table "sms_outboxes", :force => true do |t|
    t.column "number",    :string
    t.column "message",   :text
    t.column "sent_time", :datetime
  end

#    create_table :sms_outboxes do |t|
#    end
  end

  def self.down
    drop_table :sms_outboxes #rescue nil 
  end
end
