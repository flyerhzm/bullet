require File.dirname(__FILE__) + '/../spec_helper'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

describe Bullet::Association, 'has_many' do

  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :categories do |t|
        t.column :name, :string
      end

      create_table :posts do |t|
        t.column :name, :string
        t.column :category_id, :integer
        t.column :writer_id, :integer
      end

      create_table :comments do |t|
        t.column :name, :string
        t.column :post_id, :integer
        t.column :author_id, :integer
      end

      create_table :entries do |t|
        t.column :name, :string
        t.column :category_id, :integer
      end

      create_table :base_users do |t|
        t.column :name, :string
        t.column :type, :string
        t.column :newspaper_id, :integer
      end
      create_table :newspapers do |t|
        t.column :name, :string
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
    belongs_to :writer


    named_scope :preload_posts, lambda { {:include => :comments} }
    named_scope :in_category_name, lambda { |name|
      { :conditions => ['categories.name = ?', name], :include => :category }
    }
  end

  class Entry < ActiveRecord::Base
    belongs_to :category
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
    belongs_to :author, :class_name => "BaseUser"
  end

  class BaseUser < ActiveRecord::Base
    has_many :comments
    has_many :posts
    belongs_to :newspaper
  end
  
  class Newspaper < ActiveRecord::Base
    has_many :writers, :class_name => "BaseUser"
  end

  class Writer < BaseUser
  end

  before(:all) do
    setup_db
    
    newspaper1 = Newspaper.create(:name => "First Newspaper")
    newspaper2 = Newspaper.create(:name => "Second Newspaper")

    writer1 = Writer.create(:name => 'first', :newspaper => newspaper1)
    writer2 = Writer.create(:name => 'second', :newspaper => newspaper2)
    user1 = BaseUser.create(:name => 'third', :newspaper => newspaper1)
    user2 = BaseUser.create(:name => 'fourth', :newspaper => newspaper2)


    category1 = Category.create(:name => 'first')
    category2 = Category.create(:name => 'second')

    post1 = category1.posts.create(:name => 'first', :writer => writer1)
    post1a = category1.posts.create(:name => 'like first', :writer => writer2)
    post2 = category2.posts.create(:name => 'second', :writer => writer2)

    comment1 = post1.comments.create(:name => 'first', :author => writer1)
    comment2 = post1.comments.create(:name => 'first2', :author => writer1)
    comment3 = post1.comments.create(:name => 'first3', :author => writer1)
    comment4 = post1.comments.create(:name => 'second', :author => writer2)
    comment8 = post1a.comments.create(:name => "like first 1", :author => writer1)
    comment9 = post1a.comments.create(:name => "like first 2", :author => writer2)
    comment5 = post2.comments.create(:name => 'third', :author => user1)
    comment6 = post2.comments.create(:name => 'fourth', :author => user2)
    comment7 = post2.comments.create(:name => 'fourth', :author => writer1)

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

  context "for unused cases" do
    #If you have the same record created twice with different includes
    #  the hash value get's accumulated includes, which leads to false Unused eager loading
    it "should not incorrectly mark associations as unused when multiple object instances" do
      comments_with_author = Comment.all(:include => :author)
      comments_with_post = Comment.all(:include => :post)
      comments_with_author.each { |c| c.author.name }
      comments_with_author.each { |c| c.post.name }
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_unused_preload_associations_for(Comment, :post)
      Bullet::Association.should be_detecting_unpreloaded_association_for(Comment, :post)
    end

    # same as above with different Models being queried
    it "should not incorrectly mark associations as unused when multiple object instances different Model" do
      post_with_comments = Post.all(:include => :comments)
      comments_with_author = Comment.all(:include => :author)
      post_with_comments.each { |p| p.comments.first.author.name }
      comments_with_author.each { |c| c.name }
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_unused_preload_associations_for(Comment, :author)
      Bullet::Association.should be_detecting_unpreloaded_association_for(Comment, :author)
    end

    # this test passes right now. But is a regression test to ensure that if only a small set of returned records
    # is not used that a unused preload association error is not generated
    it  "should not have unused when small set of returned records are discarded" do
      comments_with_author = Comment.all(:include => :author)
      comment_collection = comments_with_author.first(2)
      comment_collection.collect { |com| com.author.name }
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_unused_preload_associations_for(Comment, :author)
    end
  end


  context "comments => posts => category" do

    # this happens because the post isn't a possible object even though the writer is access through the post
    # which leads to an 1+N queries
    it "should detect unpreloaded writer" do
      Comment.all(:include => [:author, :post],
        :conditions => ["base_users.id = ?", BaseUser.first]).each do |com|
        com.post.writer.name
      end
      Bullet::Association.should be_detecting_unpreloaded_association_for(Post, :writer)
    end

    # this happens because the comment doesn't break down the hash into keys
    # properly creating an association from comment to post
    it "should detect preload of comment => post" do
      comments = Comment.all(:include => [:author, {:post => :writer}],
        :conditions => ["base_users.id = ?", BaseUser.first]).each do |com|
        com.post.writer.name
      end
      Bullet::Association.should_not be_detecting_unpreloaded_association_for(Comment, :post)
      Bullet::Association.should be_completely_preloading_associations
    end

    it "should detect preload of post => writer" do
      comments = Comment.all(:include => [:author, {:post => :writer}],
        :conditions => ["base_users.id = ?", BaseUser.first]).each do |com|
        com.post.writer.name
      end
      Bullet::Association.should be_creating_object_association_for(comments.first, :author)
      Bullet::Association.should_not be_detecting_unpreloaded_association_for(Post, :writer)
      Bullet::Association.should be_completely_preloading_associations
    end

    # To flyerhzm: This does not detect that newspaper is unpreloaded. The association is
    # not within possible objects, and thus cannot be detected as unpreloaded
    it "should detect unpreloading of writer => newspaper" do
      comments = Comment.all(:include => {:post => :writer}, :conditions => "posts.name like '%first%'").each do |com|
        com.post.writer.newspaper.name
      end
      Bullet::Association.should be_detecting_unpreloaded_association_for(Writer, :newspaper)
    end

    # when we attempt to access category, there is an infinite overflow because load_target is hijacked leading to
    # a repeating loop of calls in this test
    it "should not raise a stack error from posts to category" do
      lambda {
        Comment.all(:include => {:post => :category}).each do |com|
          com.post.category
        end
      }.should_not raise_error(SystemStackError)
    end
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

    it "should detect unused preload post => comments for post" do
      Post.find(:all, :include => :comments).collect(&:name)
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_has_unused_preload_associations
    end

    it "should detect no unused preload post => comments for post" do
      Post.find(:all).collect(&:name)
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
    end

    it "should detect no unused preload post => comments for comment" do
      Post.find(:all).each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations

      Bullet::Association.end_request
      Bullet::Association.start_request

      Post.find(:all).each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
    end
  end

  context "category => posts => comments" do
    it "should detect preload with category => posts => comments" do
      Category.find(:all, :include => {:posts => :comments}).each do |category|
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

    it "should detect unused preload with category => posts => comments" do
      Category.find(:all, :include => {:posts => :comments}).collect(&:name)
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_has_unused_preload_associations
    end

    it "should detect unused preload with post => commnets, no category => posts" do
      Category.find(:all, :include => {:posts => :comments}).each do |category|
        category.posts.collect(&:name)
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_has_unused_preload_associations
    end

    it "should no detect preload with category => posts => comments" do
      Category.find(:all).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
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

    it "should detect unused with category => [posts, entries]" do
      Category.find(:all, :include => [:posts, :entries]).collect(&:name)
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_has_unused_preload_associations
    end

    it "should detect unused preload with category => entries, but no category => posts" do
      Category.find(:all, :include => [:posts, :entries]).each do |category|
        category.posts.collect(&:name)
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_has_unused_preload_associations
    end

    it "should detect no unused preload" do
      Category.find(:all).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
    end
  end

  context "no preload" do
    it "should no preload only display only one post => comment" do
      Post.find(:all, :include => :comments).each do |post|
        post.comments.first.name
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end

    it "should no preload only one post => commnets" do
      Post.first.comments.collect(&:name)
      Bullet::Association.should_not be_has_unpreload_associations
    end
  end

  context "named_scope for_category_name" do
    it "should detect preload with post => category" do
      Post.in_category_name('first').all.each do |post|
        post.category.name
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end

    it "should not be unused preload post => category" do
      Post.in_category_name('first').all.collect(&:name)
      Bullet::Association.should_not be_has_unpreload_associations
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
    end
  end

  context "named_scope preload_posts" do
    it "should no preload post => comments with named_scope" do
      Post.preload_posts.each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Association.should_not be_has_unpreload_associations
    end

    it "should unused preload with named_scope" do
      Post.preload_posts.collect(&:name)
      Bullet::Association.should_not be_has_unpreload_associations
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_has_unused_preload_associations
    end
  end

  context "no unused" do
    it "should no unused only display only one post => comment" do
      Post.find(:all, :include => :comments).each do |post|
        i = 0
        post.comments.each do |comment|
          if i == 0
            comment.name
          else
            i += 1
          end
        end
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
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

    it "should detect no unused preload comments => post" do
      Comment.find(:all).collect(&:name)
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
    end

    it "should detect unused preload comments => post" do
      Comment.find(:all, :include => :post).collect(&:name)
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should be_has_unused_preload_associations
    end

    it "should dectect no unused preload comments => post" do
      Comment.find(:all).each do |comment|
        comment.post.name
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
    end

    it "should dectect no unused preload comments => post" do
      Comment.find(:all, :include => :post).each do |comment|
        comment.post.name
      end
      Bullet::Association.check_unused_preload_associations
      Bullet::Association.should_not be_has_unused_preload_associations
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

  it "should detect unpreload associations" do
    Student.find(:all).each do |student|
      student.teachers.collect(&:name)
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associations" do
    Student.find(:all, :include => :teachers).each do |student|
      student.teachers.collect(&:name)
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end

  it "should detect unused preload associations" do
    Student.find(:all, :include => :teachers).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should be_has_unused_preload_associations
  end

  it "should detect no unused preload associations" do
    Student.find(:all).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
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

  it "should detect unpreload associations" do
    Firm.find(:all).each do |firm|
      firm.clients.collect(&:name)
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associations" do
    Firm.find(:all, :include => :clients).each do |firm|
      firm.clients.collect(&:name)
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end

  it "should detect no unused preload associations" do
    Firm.find(:all).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
  end

  it "should detect unused preload associations" do
    Firm.find(:all, :include => :clients).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should be_has_unused_preload_associations
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

      create_table :pets do |t|
        t.column :name, :string
        t.column :user_id, :integer
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
    has_many :pets
  end

  class Pet < ActiveRecord::Base
    belongs_to :user
  end

  class News < ActiveRecord::Base
    has_many :votes, :as => :voteable
  end

  before(:all) do
    setup_db
    user1 = User.create(:name => 'first')
    user2 = User.create(:name => 'second')
    user3 = User.create(:name => 'third')
    user4 = User.create(:name => 'fourth')

    pet1 = User.create(:name => "dog")
    pet2 = User.create(:name => "dog")
    pet3 = User.create(:name => "cat")
    pet4 = User.create(:name => "cat")

    user1.votes << Vote.create(:vote => 10)
    user1.votes << Vote.create(:vote => 20)
    user2.votes << Vote.create(:vote => 10)
    user2.votes << Vote.create(:vote => 20)
    user3.votes << Vote.create(:vote => 10)
    user3.votes << Vote.create(:vote => 20)
    user4.votes << Vote.create(:vote => 10)
    user4.votes << Vote.create(:vote => 20)

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

  # this happens only when a polymorphic association is included along with another table which is being referenced in the query
  it "should not have unused preloaded associations with conditions" do
    all_users = User.all(:include => :pets)
    users_with_ten_votes = User.all(:include => :votes, :conditions => ["votes.vote = ?", 10])
    users_without_ten_votes = User.all(:conditions => ["users.id not in (?)", users_with_ten_votes.collect(&:id)])
    all_users.collect { |t| t.pets.collect(&:name) }
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_unused_preload_associations_for(User, :pets)
    Bullet::Association.should_not be_unused_preload_associations_for(User, :votes)
  end

  it "should detect unpreload associations" do
    User.find(:all).each do |user|
      user.votes.collect(&:vote)
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associations" do
    User.find(:all, :include => :votes).each do |user|
      user.votes.collect(&:vote)
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end

  it "should detect unpreload associations with voteable" do
    Vote.find(:all).each do |vote|
      vote.voteable.name
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload associations with voteable" do
    Vote.find(:all, :include => :voteable).each do |vote|
      vote.voteable.name
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end

  it "should detect no unused preload associations" do
    User.find(:all).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
  end

  it "should detect unused preload associations" do
    User.find(:all, :include => :votes).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should be_has_unused_preload_associations
  end

  it "should detect no unused preload associations with voteable" do
    Vote.find(:all).collect(&:vote)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
  end

  it "should detect unused preload associations with voteable" do
    Vote.find(:all, :include => :voteable).collect(&:vote)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should be_has_unused_preload_associations
  end
end

describe Bullet::Association, "has_one" do

  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :companies do |t|
        t.column :name, :string
      end

      create_table :addresses do |t|
        t.column :name, :string
        t.column :company_id, :integer
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Company < ActiveRecord::Base
    has_one :address
  end

  class Address < ActiveRecord::Base
    belongs_to :company
  end

  before(:all) do
    setup_db

    company1 = Company.create(:name => 'first')
    company2 = Company.create(:name => 'second')

    Address.create(:name => 'first', :company => company1)
    Address.create(:name => 'second', :company => company2)
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

  it "should detect unpreload association" do
    Company.find(:all).each do |company|
      company.address.name
    end
    Bullet::Association.should be_has_unpreload_associations
  end

  it "should detect no unpreload association" do
    Company.find(:all, :include => :address).each do |company|
      company.address.name
    end
    Bullet::Association.should_not be_has_unpreload_associations
  end

  it "should detect no unused preload association" do
    Company.find(:all).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
  end

  it "should detect unused preload association" do
    Company.find(:all, :include => :address).collect(&:name)
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should be_has_unused_preload_associations
  end
end

describe Bullet::Association, "call one association that in possible objects" do

  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :contacts do |t|
        t.column :name, :string
      end

      create_table :emails do |t|
        t.column :name, :string
        t.column :contact_id, :integer
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Contact < ActiveRecord::Base
    has_many :emails
  end

  class Email < ActiveRecord::Base
    belongs_to :contact
  end

  before(:all) do
    setup_db

    contact1 = Contact.create(:name => 'first')
    contact2 = Contact.create(:name => 'second')

    email1 = contact1.emails.create(:name => 'first')
    email2 = contact1.emails.create(:name => 'second')
    email3 = contact2.emails.create(:name => 'third')
    email4 = contact2.emails.create(:name => 'fourth')
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

  it "should detect no unpreload association" do
    Contact.find(:all)
    Contact.first.emails.collect(&:name)
    Bullet::Association.should_not be_has_unpreload_associations
  end
end

describe Bullet::Association, "STI" do

  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :documents do |t|
        t.string :name
        t.string :type
        t.integer :parent_id
        t.integer :author_id
      end

      create_table :authors do |t|
        t.string :name
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Document < ActiveRecord::Base
    has_many :children, :class_name => "Document", :foreign_key => 'parent_id'
    belongs_to :parent, :class_name => "Document", :foreign_key => 'parent_id'
    belongs_to :author
  end

  class Page < Document
  end

  class Folder < Document
  end

  class Author < ActiveRecord::Base
    has_many :documents
  end

  before(:all) do
    setup_db
    author1 = Author.create(:name => 'author1')
    author2 = Author.create(:name => 'author2')
    folder1 = Folder.create(:name => 'folder1', :author_id => author1.id)
    folder2 = Folder.create(:name => 'folder2', :author_id => author2.id)
    page1 = Page.create(:name => 'page1', :parent_id => folder1.id, :author_id => author1.id)
    page2 = Page.create(:name => 'page2', :parent_id => folder1.id, :author_id => author1.id)
    page3 = Page.create(:name => 'page3', :parent_id => folder2.id, :author_id => author2.id)
    page4 = Page.create(:name => 'page4', :parent_id => folder2.id, :author_id => author2.id)
  end

  before(:each) do
    Bullet::Association.start_request
  end

  after(:each) do
    Bullet::Association.end_request
  end

  it "should detect unpreload associations" do
    Page.find(:all).each do |page|
      page.author.name
    end
    Bullet::Association.should be_has_unpreload_associations
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
  end

  it "should not detect unpreload associations" do
    Page.find(:all, :include => :author).each do |page|
      page.author.name
    end
    Bullet::Association.should_not be_has_unpreload_associations
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
  end

  it "should detect unused preload associations" do
    Page.find(:all, :include => :author).collect(&:name)
    Bullet::Association.should_not be_has_unpreload_associations
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should be_has_unused_preload_associations
  end

  it "should not detect unused preload associations" do
    Page.find(:all).collect(&:name)
    Bullet::Association.should_not be_has_unpreload_associations
    Bullet::Association.check_unused_preload_associations
    Bullet::Association.should_not be_has_unused_preload_associations
  end
end
