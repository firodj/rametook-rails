class CreateSmsReplies < ActiveRecord::Migration
  def self.up
      create_table "sms_replies", :force => true do |t|
    t.column "function",  :string
    t.column "action",    :string
    t.column "message",   :string
    t.column "tags",      :string
    t.column "help_info", :text
    t.column "active",    :boolean, :default => true
  end

#    create_table :sms_replies do |t|
#    end
  end

  def self.down
    drop_table :sms_replies #rescue nil 
  end
end
