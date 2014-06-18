class CreateSmsTemplates < ActiveRecord::Migration
  def self.up
      create_table "sms_templates", :force => true do |t|
    t.column "name",     :string, :default => "", :null => false
    t.column "template", :string, :default => "", :null => false
  end

#    create_table :sms_templates do |t|
#    end
  end

  def self.down
    drop_table :sms_templates #rescue nil 
  end
end
