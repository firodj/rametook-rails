class CreateCmsSimples < ActiveRecord::Migration
  def self.up
      create_table "cms_simples", :force => true do |t|
    t.column "user_id",         :integer
    t.column "name",            :string
    t.column "content",         :text
    t.column "cms_category_id", :integer
    t.column "date",            :date
    t.column "is_published",    :boolean
  end

#    create_table :cms_simples do |t|
#    end
  end

  def self.down
    drop_table :cms_simples #rescue nil 
  end
end
