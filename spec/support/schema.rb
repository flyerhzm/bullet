module Bullet
  module Schema
    extend self

    def setup_db
      ::ActiveRecord::Schema.define(:version => 1) do
        create_table :categories do |t|
          t.string :name
        end

        create_table :posts do |t|
          t.string :title
          t.integer :category_id
          t.integer :user_id
        end

        create_table :entries do |t|
          t.string :title
          t.integer :category_id
        end

        create_table :comments do |t|
          t.text :body
          t.integer :post_id
          t.integer :user_id
        end

        create_table :newspapers do |t|
          t.string :name
        end

        create_table :countries do |t|
          t.string :name
        end

        create_table :cities do |t|
          t.string :name
          t.integer :country_id
        end

        create_table :users do |t|
          t.string :name
          t.string :type
          t.integer :pets_count
          t.integer :newspaper_id
        end

        create_table :pets do |t|
          t.string :name
          t.integer :user_id
        end

        create_table :students do |t|
          t.string :name
        end

        create_table :teachers do |t|
          t.string :name
        end

        create_table :students_teachers, :id => false do |t|
          t.integer :student_id
          t.integer :teacher_id
        end

        create_table :firms do |t|
          t.string :name
        end

        create_table :clients do |t|
          t.string :name
        end

        create_table :relationships do |t|
          t.integer :firm_id
          t.integer :client_id
        end

        create_table :companies do |t|
          t.string :name
        end

        create_table :addresses do |t|
          t.string :name
          t.integer :company_id
        end

        create_table :documents do |t|
          t.string :name
          t.string :type
          t.integer :parent_id
          t.integer :user_id
        end
      end
    end

    def teardown_db
      ::ActiveRecord::Base.connection.tables.each do |table|
        ::ActiveRecord::Base.connection.drop_table(table)
      end
    end
  end
end
