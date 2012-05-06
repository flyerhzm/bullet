require 'spec_helper'

describe Bullet::Detector::Association, 'has_many' do
  before(:each) do
    Bullet.clear
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  context "for unused cases" do
    #If you have the same record created twice with different includes
    #  the hash value get's accumulated includes, which leads to false Unused eager loading
    #it "should not incorrectly mark associations as unused when multiple object instances" do
      #comments_with_author = Comment.includes(:author)
      #comments_with_post = Comment.includes(:post)
      #comments_with_author.each { |c| c.author.name }
      #comments_with_author.each { |c| c.post.name }
      #Bullet::Association.check_unused_preload_associations
      #Bullet::Association.should be_unused_preload_associations_for(Comment, :post)
      #Bullet::Association.should be_detecting_unpreloaded_association_for(Comment, :post)
    #end

    # same as above with different Models being queried
    #it "should not incorrectly mark associations as unused when multiple object instances different Model" do
      #post_with_comments = Post.includes(:comments)
      #comments_with_author = Comment.includes(:author)
      #post_with_comments.each { |p| p.comments.first.author.name }
      #comments_with_author.each { |c| c.name }
      #Bullet::Association.check_unused_preload_associations
      #Bullet::Association.should be_unused_preload_associations_for(Comment, :author)
      #Bullet::Association.should be_detecting_unpreloaded_association_for(Comment, :author)
    #end

    # this test passes right now. But is a regression test to ensure that if only a small set of returned records
    # is not used that a unused preload association error is not generated
    it  "should not have unused when small set of returned records are discarded" do
      comments_with_author = Comment.includes(:author)
      comment_collection = comments_with_author.limit(2)
      comment_collection.collect { |com| com.author.name }
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_unused_preload_associations_for(Comment, :author)
    end
  end


  context "comments => posts => category" do

    # this happens because the post isn't a possible object even though the writer is access through the post
    # which leads to an 1+N queries
    it "should detect unpreloaded writer" do
      Comment.includes([:author, :post]).where(["base_users.id = ?", BaseUser.first]).each do |com|
        com.post.writer.name
      end
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Post, :writer)
    end

    # this happens because the comment doesn't break down the hash into keys
    # properly creating an association from comment to post
    it "should detect preload of comment => post" do
      comments = Comment.includes([:author, {:post => :writer}]).where(["base_users.id = ?", BaseUser.first]).each do |com|
        com.post.writer.name
      end
      Bullet::Detector::Association.should_not be_detecting_unpreloaded_association_for(Comment, :post)
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect preload of post => writer" do
      comments = Comment.includes([:author, {:post => :writer}]).where(["base_users.id = ?", BaseUser.first]).each do |com|
        com.post.writer.name
      end
      Bullet::Detector::Association.should be_creating_object_association_for(comments.first, :author)
      Bullet::Detector::Association.should_not be_detecting_unpreloaded_association_for(Post, :writer)
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    # To flyerhzm: This does not detect that newspaper is unpreloaded. The association is
    # not within possible objects, and thus cannot be detected as unpreloaded
    it "should detect unpreloading of writer => newspaper" do
      comments = Comment.all(:include => {:post => :writer}, :conditions => "posts.name like '%first%'").each do |com|
        com.post.writer.newspaper.name
      end
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Writer, :newspaper)
    end

    # when we attempt to access category, there is an infinite overflow because load_target is hijacked leading to
    # a repeating loop of calls in this test
    it "should not raise a stack error from posts to category" do
      lambda {
        Comment.includes({:post => :category}).each do |com|
          com.post.category
        end
      }.should_not raise_error(SystemStackError)
    end
  end

  context "post => comments" do
    it "should detect non preload post => comments" do
      Post.all.each do |post|
        post.comments.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Post, :comments)
    end

    it "should detect preload with post => comments" do
      Post.includes(:comments).each do |post|
        post.comments.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload post => comments" do
      Post.includes(:comments).map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Post, :comments)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should not detect unused preload post => comments" do
      Post.all.map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end

  context "category => posts => comments" do
    it "should detect non preload category => posts => comments" do
      Category.all.each do |category|
        category.posts.each do |post|
          post.comments.map(&:name)
        end
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Post, :comments)
    end

    it "should detect preload category => posts, but no post => comments" do
      Category.includes(:posts).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should_not be_detecting_unpreloaded_association_for(Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Post, :comments)
    end

    it "should detect preload with category => posts => comments" do
      Category.includes({:posts => :comments}).each do |category|
        category.posts.each do |post|
          post.comments.map(&:name)
        end
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload with category => posts => comments" do
      Category.includes({:posts => :comments}).map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Post, :comments)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload with post => commnets, no category => posts" do
      Category.includes({:posts => :comments}).each do |category|
        category.posts.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Post, :comments)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end

  context "category => posts, category => entries" do
    it "should detect non preload with category => [posts, entries]" do
      Category.all.each do |category|
        category.posts.map(&:name)
        category.entries.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Category, :entries)
    end

    it "should detect preload with category => posts, but not with category => entries" do
      Category.includes(:posts).each do |category|
        category.posts.map(&:name)
        category.entries.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should_not be_detecting_unpreloaded_association_for(Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Category, :entries)
    end

    it "should detect preload with category => [posts, entries]" do
      Category.includes([:posts, :entries]).each do |category|
        category.posts.map(&:name)
        category.entries.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload with category => [posts, entries]" do
      Category.includes([:posts, :entries]).map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Category, :posts)
      Bullet::Detector::Association.should be_unused_preload_associations_for(Category, :entries)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload with category => entries, but not with category => posts" do
      Category.includes([:posts, :entries]).each do |category|
        category.posts.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_unused_preload_associations_for(Category, :posts)
      Bullet::Detector::Association.should be_unused_preload_associations_for(Category, :entries)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end

  context "post => comment" do
    it "should detect unused preload with post => comments" do
      Post.includes(:comments).each do |post|
        post.comments.first.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_unused_preload_associations_for(Post, :comments)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect preload with post => commnets" do
      Post.first.comments.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end

  context "scope for_category_name" do
    it "should detect preload with post => category" do
      Post.in_category_name('first').all.each do |post|
        post.category.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should not be unused preload post => category" do
      Post.in_category_name('first').all.map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end

  context "scope preload_comments" do
    it "should detect preload post => comments with scope" do
      Post.preload_comments.each do |post|
        post.comments.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload with scope" do
      Post.preload_comments.map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Post, :comments)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end
end

describe Bullet::Detector::Association, 'belongs_to' do
  before(:each) do
    Bullet.clear
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  context "comment => post" do
    it "should detect non preload with comment => post" do
      Comment.all.each do |comment|
        comment.post.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Comment, :post)
    end

    it "should detect preload with one comment => post" do
      Comment.first.post.name
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should dtect preload with comment => post" do
      Comment.includes(:post).each do |comment|
        comment.post.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should not detect preload with comment => post" do
      Comment.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload with comments => post" do
      Comment.includes(:post).map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Comment, :post)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end
end

describe Bullet::Detector::Association, 'has_and_belongs_to_many' do
  before(:each) do
    Bullet.clear
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  context "students <=> teachers" do
    it "should detect non preload associations" do
      Student.all.each do |student|
        student.teachers.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Student, :teachers)
    end

    it "should detect preload associations" do
      Student.includes(:teachers).each do |student|
        student.teachers.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload associations" do
      Student.includes(:teachers).map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Student, :teachers)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect no unused preload associations" do
      Student.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end
end

describe Bullet::Detector::Association, 'has_many :through' do
  before(:each) do
    Bullet.clear
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  context "firm => clients" do
    it "should detect non preload associations" do
      Firm.all.each do |firm|
        firm.clients.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Firm, :clients)
    end

    it "should detect preload associations" do
      Firm.includes(:clients).each do |firm|
        firm.clients.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should not detect preload associations" do
      Firm.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload associations" do
      Firm.includes(:clients).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Firm, :clients)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end
end

describe Bullet::Detector::Association, "has_one" do
  before(:each) do
    Bullet.clear
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  context "compay => address" do
    it "should detect non preload association" do
      Company.all.each do |company|
        company.address.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Company, :address)
    end

    it "should detect preload association" do
      Company.find(:all, :include => :address).each do |company|
        company.address.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should not detect preload association" do
      Company.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload association" do
      Company.find(:all, :include => :address).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Company, :address)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end
end

describe Bullet::Detector::Association, "call one association that in possible objects" do
  before(:each) do
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  it "should detect no unpreload association" do
    Contact.all
    Contact.first.emails.collect(&:name)
    Bullet::Detector::Association.should be_completely_preloading_associations
  end
end

describe Bullet::Detector::Association, "STI" do
  before(:each) do
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  it "should detect unpreload associations" do
    Page.all.each do |page|
      page.author.name
    end
    Bullet::Detector::Association.should_not be_completely_preloading_associations
    Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
    Bullet::Detector::Association.should_not be_has_unused_preload_associations
  end

  it "should not detect unpreload associations" do
    Page.find(:all, :include => :author).each do |page|
      page.author.name
    end
    Bullet::Detector::Association.should be_completely_preloading_associations
    Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
    Bullet::Detector::Association.should_not be_has_unused_preload_associations
  end

  it "should detect unused preload associations" do
    Page.find(:all, :include => :author).collect(&:name)
    Bullet::Detector::Association.should be_completely_preloading_associations
    Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
    Bullet::Detector::Association.should be_has_unused_preload_associations
  end

  it "should not detect unused preload associations" do
    Page.all.collect(&:name)
    Bullet::Detector::Association.should be_completely_preloading_associations
    Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
    Bullet::Detector::Association.should_not be_has_unused_preload_associations
  end
end
