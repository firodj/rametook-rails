class CreateCmsCategories < ActiveRecord::Migration
  def self.up
      create_table "cms_categories", :force => true do |t|
    t.column "name", :string
  end
     say_with_time "Creating news cms_category..." do
      	CmsCategory.create :name => 'news'
      	CmsCategory.create :name => 'article'	
     end
  end

  def self.down
    drop_table :cms_categories
  end
end
