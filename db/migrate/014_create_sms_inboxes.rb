class CreateSmsInboxes < ActiveRecord::Migration
  def self.up
      create_table "sms_inboxes", :force => true do |t|
    t.column "number",     :string
    t.column "message",    :string
    t.column "time",       :datetime
    t.column "has_read",   :integer,  :limit => 1
    t.column "message_fb", :string
    t.column "time_fb",    :datetime
  end

#    create_table :sms_inboxes do |t|
#    end
  end

  def self.down
    drop_table :sms_inboxes #rescue nil 
  end
end
