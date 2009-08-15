ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

describe Bullet do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :categories do |t|
        t.column :name, :string
      end
      
      create_table :posts do |t|
        t.column :name, :string
        t.column :category_id, :integer
      end

      create_table :comments do |t|
        t.column :name, :string
        t.column :post_id, :integer
      end

      create_table :entries do |t|
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
    has_many :posts
    has_many :entries
  end

  class Post < ActiveRecord::Base
    belongs_to :category
    has_many :comments
  end
  
  class Entry < ActiveRecord::Base
    belongs_to :category
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
  end
  
  before(:all) do
    setup_db
    
    category1 = Category.create(:name => 'first')
    category2 = Category.create(:name => 'second')
    
    post1 = category1.posts.create(:name => 'first')
    post2 = category1.posts.create(:name => 'second')
    post3 = category2.posts.create(:name => 'third')
    post4 = category2.posts.create(:name => 'fourth')
    
    comment1 = post1.comments.create(:name => 'first')
    comment2 = post1.comments.create(:name => 'second')
    comment3 = post2.comments.create(:name => 'third')
    comment4 = post2.comments.create(:name => 'fourth')
    
    entry1 = category1.entries.create(:name => 'first')
    entry2 = category1.entries.create(:name => 'second')
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
  
  context "post => comments" do
    it "should detect preload with post => comments" do
      Post.find(:all, :include => :comments).each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end
  
    it "should detect no preload post => comments" do
      Post.find(:all).each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Association.should be_has_unpreload_associations
    end
  end
  
  context "category => posts => comments" do
    it "should detect preload with category => posts => comments" do
      Category.find(:all, :include => {:posts => :comments}) do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end
  
    it "should detect preload category => posts, but no post => comments" do
      Category.find(:all, :include => :posts).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Association.should be_has_unpreload_associations
    end
  
    it "should detect no preload category => posts => comments" do
      Category.find(:all).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Association.should be_has_unpreload_associations
    end
  end
  
  context "category => posts, category => entries" do
    it "should detect preload with category => [posts, entries]" do
      Category.find(:all, :include => [:posts, :entries]).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end

    it "should detect preload with category => posts, but no category => entries" do
      Category.find(:all, :include => :posts).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Association.should be_has_unpreload_associations
    end

    it "should detect no preload with category => [posts, entries]" do
      Category.find(:all).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Association.should be_has_unpreload_associations
    end
  end

  context "no preload" do
    it "should no preload comments => post" do
      Comment.find(:all).each do |comment|
        comment.post.name
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end

    it "should no preload only one post => commnets" do
      Post.first.comments.collect(&:name)
      Bullet::Association.should_not be_has_unpreload_associations
    end
  end
end
