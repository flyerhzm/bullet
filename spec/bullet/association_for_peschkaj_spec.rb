require File.dirname(__FILE__) + '/../spec_helper'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
# This test is just used for http://github.com/flyerhzm/bullet/issues#issue/20
describe Bullet::Association, 'for peschkaj' do

  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :categories do |t|
        t.column :name, :string
      end

      create_table :submissions do |t|
        t.column :name, :string
        t.column :category_id, :integer
        t.column :user_id, :integer
      end

      create_table :users do |t|
        t.column :name, :string
        t.column :category_id, :integer
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Category < ActiveRecord::Base
    has_many :submissions
    has_many :users
  end
  
  class Submission < ActiveRecord::Base
    belongs_to :category
    belongs_to :user
  end
  
  class User < ActiveRecord::Base
    has_one :submission
    belongs_to :category
  end

  before(:all) do
    setup_db
    
    category1 = Category.create(:name => "category1")
    category2 = Category.create(:name => "category2")
    
    user1 = User.create(:name => 'user1', :category => category1)
    user2 = User.create(:name => 'user2', :category => category1)
    
    submission1 = category1.submissions.create(:name => "submission1", :user => user1)
    submission2 = category1.submissions.create(:name => "submission2", :user => user2)
    submission3 = category2.submissions.create(:name => "submission3", :user => user1)
    submission4 = category2.submissions.create(:name => "submission4", :user => user2)
  end

  after(:all) do
    teardown_db
  end

  before(:each) do
    Bullet::Association.start_request
  end

  after(:each) do
    Bullet::Association.end_request
  end
  
  it "should not detect unused preload associations" do
    category = Category.find_by_name('category1', :include => {:submissions => :user}, :order => "id DESC")
    category.submissions.map do |submission|
      submission.name
      submission.user.name
    end
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_unused_preload_associations_for(Category, :submissions)
    Bullet::Association.should_not be_unused_preload_associations_for(Submission, :user)
  end
end
