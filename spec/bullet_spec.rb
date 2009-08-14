ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

describe Bullet do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :posts do |t|
        t.column :name, :string
      end

      create_table :comments do |t|
        t.column :name, :string
        t.column :post_id, :string
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Post < ActiveRecord::Base
    has_many :comments
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
  end
  
  before(:all) do
    setup_db
    
    post = Post.create(:name => 'first')
    Comment.create(:name => 'first', :post => post)
    Comment.create(:name => 'second', :post => post)
    # post.comments.create(:name => 'first')
    # post.comments.create(:name => 'second')
    post = Post.create(:name => 'second')
    Comment.create(:name => 'third', :post => post)
    Comment.create(:name => 'fourth', :post => post)
    # post.comments.create(:name => 'third')
    # post.comments.create(:name => 'fourth')
  end
  
  after(:all) do
    teardown_db
  end
  
  it "should detect preload" do
    Bullet::Association.start_request
    Post.find(:all, :include => :comments).each do |post|
      post.comments
    end
    Bullet::Association.unpreload_associations.should be_empty
    Bullet::Association.end_request
  end

  it "should detect preload" do
    Bullet::Association.start_request
    Post.find(:all).each do |post|
      post.comments
    end
    Bullet::Association.unpreload_associations.should_not be_empty
    Bullet::Association.end_request
  end
end