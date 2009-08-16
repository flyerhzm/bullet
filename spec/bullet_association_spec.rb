ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

describe Bullet::Association, 'has_many' do
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
    it "should no preload only one post => commnets" do
      Post.first.comments.collect(&:name)
      Bullet::Association.should_not be_has_unpreload_associations
    end
  end

  context "belongs_to" do
    it "should preload comments => post" do
      Comment.find(:all).each do |comment|
        comment.post.name
      end
      Bullet::Association.should be_has_unpreload_associations
    end

    it "should no preload comment => post" do
      Comment.first.post.name
      Bullet::Association.should_not be_has_unpreload_associations
    end
    
    it "should no preload comments => post" do
      Comment.find(:all, :include => :post).each do |comment|
        comment.post.name
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end
  end
end

describe Bullet::Association, 'has_and_belongs_to_many' do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :students do |t|
        t.column :name, :string
      end
      
      create_table :teachers do |t|
        t.column :name, :string
      end

      create_table :students_teachers, :id => false do |t|
        t.column :student_id, :integer
        t.column :teacher_id, :integer
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Student < ActiveRecord::Base
    has_and_belongs_to_many :teachers
  end

  class Teacher < ActiveRecord::Base
    has_and_belongs_to_many :students
  end

  before(:all) do
    setup_db
    student1 = Student.create(:name => 'first')
    student2 = Student.create(:name => 'second')
    teacher1 = Teacher.create(:name => 'first')
    teacher2 = Teacher.create(:name => 'second')
    student1.teachers = [teacher1, teacher2]
    student2.teachers = [teacher1, teacher2]
    teacher1.students << student1
    teacher2.students << student2
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

  it "should detect unpreload associatoins" do
    Student.find(:all).each do |student|
      student.teachers.collect(&:name)
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associatoins" do
    Student.find(:all, :include => :teachers).each do |student|
      student.teachers.collect(&:name)
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end
end

describe Bullet::Association, 'has_many :through' do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :firms do |t|
        t.column :name, :string
      end
      
      create_table :clients do |t|
        t.column :name, :string
      end

      create_table :relations do |t|
        t.column :firm_id, :integer
        t.column :client_id, :integer
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Firm < ActiveRecord::Base
    has_many :relations
    has_many :clients, :through => :relations
  end

  class Client < ActiveRecord::Base
    has_many :relations
    has_many :firms, :through => :relations
  end

  class Relation < ActiveRecord::Base
    belongs_to :firm
    belongs_to :client
  end

  before(:all) do
    setup_db
    firm1 = Firm.create(:name => 'first')
    firm2 = Firm.create(:name => 'second')
    client1 = Client.create(:name => 'first')
    client2 = Client.create(:name => 'second')
    firm1.clients = [client1, client2]
    firm2.clients = [client1, client2]
    client1.firms << firm1
    client2.firms << firm2
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

  it "should detect unpreload associatoins" do
    Firm.find(:all).each do |firm|
      firm.clients.collect(&:name)
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associatoins" do
    Firm.find(:all, :include => :clients).each do |firm|
      firm.clients.collect(&:name)
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end
end

describe Bullet::Association, 'has_many :as' do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :votes do |t|
        t.column :vote, :integer
        t.references :voteable, :polymorphic => true
      end
      
      create_table :users do |t|
        t.column :name, :string
      end

      create_table :news do |t|
        t.column :name, :string
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Vote < ActiveRecord::Base
    belongs_to :voteable, :polymorphic => true
  end

  class User < ActiveRecord::Base
    has_many :votes, :as => :voteable
  end

  class News < ActiveRecord::Base
    has_many :votes, :as => :voteable
  end

  before(:all) do
    setup_db
    user1 = User.create(:name => 'first')
    user2 = User.create(:name => 'second')
    user1.votes << Vote.create(:vote => 10)
    user1.votes << Vote.create(:vote => 20)
    user2.votes << Vote.create(:vote => 10)
    user2.votes << Vote.create(:vote => 20)

    news1 = News.create(:name => 'first')
    news2 = News.create(:name => 'second')
    news1.votes << Vote.create(:vote => 10)
    news1.votes << Vote.create(:vote => 20)
    news2.votes << Vote.create(:vote => 10)
    news2.votes << Vote.create(:vote => 20)
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

  it "should detect unpreload associatoins" do
    User.find(:all).each do |user|
      user.votes.collect(&:vote)
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associatoins" do
    User.find(:all, :include => :votes).each do |user|
      user.votes.collect(&:vote)
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end

  it "should detect unpreload associatoins with voteable" do
    Vote.find(:all).each do |vote|
      vote.voteable.name
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associatoins with voteable" do
    Vote.find(:all, :include => :voteable).each do |vote|
      vote.voteable.name
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end
end
