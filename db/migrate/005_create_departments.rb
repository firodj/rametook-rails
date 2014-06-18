class CreateDepartments < ActiveRecord::Migration
  def self.up
    create_table :departments, :force => true do |t|
      t.column :name,       :string
      t.column :parent_id,  :integer
    end

    say_with_time "Creating uncategorized department..." do
      Department.create :name => 'Uncategorized'
    end
  end

  def self.down
    drop_table :departments
  end
end
