require 'spec_helper'

describe Bullet::Detector::Association do
  before :each do
    Bullet.start_request
  end

  after :each do
    Bullet.end_request
  end

  context 'has_many' do
    before :all do
      newspaper1 = Newspaper.create(:name => "First Newspaper")
      newspaper2 = Newspaper.create(:name => "Second Newspaper")

      writer1 = Writer.create(:name => 'first', :newspaper => newspaper1)
      writer2 = Writer.create(:name => 'second', :newspaper => newspaper2)
      # user1 = BaseUser.create(:name => 'third', :newspaper => newspaper1)
      # user2 = BaseUser.create(:name => 'fourth', :newspaper => newspaper2)

      category1 = Category.create(:name => 'first')
      category2 = Category.create(:name => 'second')

      post1 = category1.posts.create(:title => 'first', :writer => writer1)
      post1a = category1.posts.create(:title => 'like first', :writer => writer2)
      post2 = category2.posts.create(:title => 'second', :writer => writer2)

      comment1 = post1.comments.create(:body => 'first', :user => writer1)
      comment2 = post1.comments.create(:body => 'first2', :user => writer1)
      comment3 = post1.comments.create(:body => 'first3', :user => writer1)
      comment4 = post1.comments.create(:body => 'second', :user => writer2)
      comment8 = post1a.comments.create(:body => "like first 1", :user => writer1)
      comment9 = post1a.comments.create(:body => "like first 2", :user => writer2)
      # comment5 = post2.comments.create(:name => 'third', :author => user1)
      # comment6 = post2.comments.create(:name => 'fourth', :author => user2)
      comment7 = post2.comments.create(:body => 'fourth', :user => writer1)

      entry1 = category1.entries.create(:title => 'first')
      entry2 = category1.entries.create(:title => 'second')
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
        #Bullet::Association.should be_detecting_unpreload_association_for(Comment, :post)
      #end

      # same as above with different Models being queried
      #it "should not incorrectly mark associations as unused when multiple object instances different Model" do
        #post_with_comments = Post.includes(:comments)
        #comments_with_author = Comment.includes(:author)
        #post_with_comments.each { |p| p.comments.first.author.name }
        #comments_with_author.each { |c| c.name }
        #Bullet::Association.check_unused_preload_associations
        #Bullet::Association.should be_unused_preload_associations_for(Comment, :author)
        #Bullet::Association.should be_detecting_unpreload_association_for(Comment, :author)
      #end

      it  "should not have unused when small set of returned records are discarded" do
        comments_with_user = Comment.includes(:user)
        comment_collection = comments_with_user.limit(2)
        comment_collection.collect { |comment| comment.user.name }
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should_not be_has_unused_preload_associations
      end
    end

    context "inlcude with conditions" do
      # this happens because the post isn't a possible object even though the writer is access through the post
      # which leads to an N+1 queries
      it "should detect unpreload writer" do
        Comment.includes([:user, :post]).where("users.id = ?", User.first).each do |comment|
          comment.post.writer.name
        end
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Post, :writer)
      end

      # this happens because the comment doesn't break down the hash into keys
      # properly creating an association from comment to post
      it "should detect preload of comment => post" do
        Comment.includes([:user, {:post => :writer}]).where("users.id = ?", User.first).each do |comment|
          comment.post.writer.name
        end
        Bullet::Detector::Association.should be_completely_preloading_associations
      end

      # This does not detect that newspaper is unpreload. The association is
      # not within possible objects, and thus cannot be detected as unpreload
      it "should detect unpreloading of writer => newspaper" do
        Comment.includes({:post => :writer}).where("posts.title like '%first%'").each do |comment|
          comment.post.writer.newspaper.name
        end
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Writer, :newspaper)
      end
    end

    context "without error" do
      # when we attempt to access category, there is an infinite overflow because load_target is hijacked leading to
      # a repeating loop of calls in this test
      it "should not raise a stack error from posts to category" do
        lambda {
          Comment.includes({:post => :category}).each do |comment|
            comment.post.category
          end
        }.should_not raise_error(SystemStackError)
      end
    end

    context "post => comments" do
      it "should detect preload with post => comments" do
        Post.includes(:comments).each do |post|
          post.comments.collect(&:body)
        end
        Bullet::Detector::Association.should be_completely_preloading_associations
      end

      it "should detect no preload post => comments" do
        Post.all.each do |post|
          post.comments.collect(&:body)
        end
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Post, :comments)
      end

      it "should detect unused preload post => comments for post" do
        Post.includes(:comments).collect(&:title)
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should be_unused_preload_association_for(Post, :comments)
      end

      it "should detect no unused preload post => comments for post" do
        Post.all.collect(&:title)
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should_not be_has_unused_preload_associations
      end
    end

    context "category => posts => comments" do
      it "should detect preload with category => posts => comments" do
        Category.includes({:posts => :comments}).each do |category|
          category.posts.each do |post|
            post.comments.collect(&:body)
          end
        end
        Bullet::Detector::Association.should be_completely_preloading_associations
      end

      it "should detect preload category => posts, but no post => comments" do
        Category.includes(:posts).each do |category|
          category.posts.each do |post|
            post.comments.collect(&:body)
          end
        end
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Post, :comments)
      end

      it "should detect no preload category => posts => comments" do
        Category.all.each do |category|
          category.posts.each do |post|
            post.comments.collect(&:body)
          end
        end
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Category, :posts)
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Post, :comments)
      end

      it "should detect unused preload with category => posts => comments" do
        Category.includes({:posts => :comments}).collect(&:name)
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should be_unused_preload_association_for(Post, :comments)
      end

      it "should detect unused preload with post => commnets, no category => posts" do
        Category.includes({:posts => :comments}).each do |category|
          category.posts.collect(&:title)
        end
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should be_unused_preload_association_for(Post, :comments)
      end

      it "should no detect preload with category => posts => comments" do
        Category.all.each do |category|
          category.posts.each do |post|
            post.comments.collect(&:body)
          end
        end
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should_not be_has_unused_preload_associations
      end
    end

    context "category => posts, category => entries" do
      it "should detect preload with category => [posts, entries]" do
        Category.includes([:posts, :entries]).each do |category|
          category.posts.collect(&:title)
          category.entries.collect(&:title)
        end
        Bullet::Detector::Association.should be_completely_preloading_associations
      end

      it "should detect preload with category => posts, but no category => entries" do
        Category.includes(:posts).each do |category|
          category.posts.collect(&:title)
          category.entries.collect(&:title)
        end
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Category, :entries)
      end

      it "should detect no preload with category => [posts, entries]" do
        Category.all.each do |category|
          category.posts.collect(&:title)
          category.entries.collect(&:title)
        end
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Category, :posts)
        Bullet::Detector::Association.should be_detecting_unpreload_association_for(Category, :entries)
      end

      it "should detect unused with category => [posts, entries]" do
        Category.includes([:posts, :entries]).collect(&:name)
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should be_unused_preload_association_for(Category, :posts)
        Bullet::Detector::Association.should be_unused_preload_association_for(Category, :entries)
      end

      it "should detect unused preload with category => entries, but no category => posts" do
        Category.includes([:posts, :entries]).each do |category|
          category.posts.collect(&:title)
        end
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should be_unused_preload_association_for(Category, :entries)
      end

      it "should detect no unused preload" do
        Category.all.each do |category|
          category.posts.collect(&:title)
          category.entries.collect(&:title)
        end
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should_not be_has_unused_preload_associations
      end
    end

    context "no preload" do
      it "should no preload only display only one post => comment" do
        Post.includes(:comments).each do |post|
          post.comments.first.body
        end
        Bullet::Detector::Association.should be_completely_preloading_associations
      end

      it "should no preload only one post => commnets" do
        Post.first.comments.collect(&:body)
        Bullet::Detector::Association.should be_completely_preloading_associations
      end
    end

    context "scope preload_posts" do
      it "should no preload post => comments with scope" do
        Post.preload_posts.each do |post|
          post.comments.collect(&:body)
        end
        Bullet::Detector::Association.should be_completely_preloading_associations
      end

      it "should unused preload with scope" do
        Post.preload_posts.collect(&:title)
        Bullet::Detector::Association.should be_completely_preloading_associations
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should be_unused_preload_association_for(Post, :comments)
      end
    end

    context "no unused" do
      it "should no unused only display only one post => comment" do
        Post.includes(:comments).each do |post|
          i = 0
          post.comments.each do |comment|
            if i == 0
              comment.body
            else
              i += 1
            end
          end
        end
        Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
        Bullet::Detector::Association.should_not be_has_unused_preload_associations
      end
    end
  end

  context "belongs_to" do
    it "should preload comments => post" do
      Comment.all.each do |comment|
        comment.post.title
      end
      Bullet::Detector::Association.should be_detecting_unpreload_association_for(Comment, :post)
    end

    it "should no preload comment => post" do
      Comment.first.post.title
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should no preload comments => post" do
      Comment.includes(:post).each do |comment|
        comment.post.title
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect no unused preload comments => post" do
      Comment.all.collect(&:body)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should detect unused preload comments => post" do
      Comment.includes(:post).collect(&:body)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_association_for(Comment, :post)
    end

    it "should dectect no unused preload comments => post" do
      Comment.all.each do |comment|
        comment.post.title
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should dectect no unused preload comments => post" do
      Comment.includes(:post).each do |comment|
        comment.post.title
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end

  context "has_and_belongs_to_many" do
    before :all do
      student1 = Student.create(:name => 'first')
      student2 = Student.create(:name => 'second')
      teacher1 = Teacher.create(:name => 'first')
      teacher2 = Teacher.create(:name => 'second')
      student1.teachers = [teacher1, teacher2]
      student2.teachers = [teacher1, teacher2]
      teacher1.students << student1
      teacher2.students << student2
    end

    it "should detect unpreload associations" do
      Student.all.each do |student|
        student.teachers.collect(&:name)
      end
      Bullet::Detector::Association.should be_detecting_unpreload_association_for(Student, :teachers)
    end

    it "should detect no unpreload associations" do
      Student.includes(:teachers).each do |student|
        student.teachers.collect(&:name)
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload associations" do
      Student.includes(:teachers).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_association_for(Student, :teachers)
    end

    it "should detect no unused preload associations" do
      Student.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end

  context "has_many :through" do
    before :all do
      firm1 = Firm.create(:name => 'first')
      firm2 = Firm.create(:name => 'second')
      client1 = Client.create(:name => 'first')
      client2 = Client.create(:name => 'second')
      firm1.clients = [client1, client2]
      firm2.clients = [client1, client2]
      client1.firms << firm1
      client2.firms << firm2
    end

    it "should detect unpreload associations" do
      Firm.all.each do |firm|
        firm.clients.collect(&:name)
      end
      Bullet::Detector::Association.should be_detecting_unpreload_association_for(Firm, :clients)
    end

    it "should detect no unpreload associations" do
      Firm.includes(:clients).each do |firm|
        firm.clients.collect(&:name)
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect no unused preload associations" do
      Firm.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should detect unused preload associations" do
      Firm.includes(:clients).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_association_for(Firm, :clients)
    end
  end

  context "has_one" do
    before :all do
      company1 = Company.create(:name => 'first')
      company2 = Company.create(:name => 'second')

      Address.create(:name => 'first', :company => company1)
      Address.create(:name => 'second', :company => company2)
    end

    it "should detect unpreload association" do
      Company.all.each do |company|
        company.address.name
      end
      Bullet::Detector::Association.should be_detecting_unpreload_association_for(Company, :address)
    end

    it "should detect no unpreload association" do
      Company.includes(:address).each do |company|
        company.address.name
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect no unused preload association" do
      Company.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should detect unused preload association" do
      Company.includes(:address).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_association_for(Company, :address)
    end
  end

  context "call one association that in possible objects" do
    before :all do
      post1 = Post.create(:title => 'first')
      post2 = Post.create(:title => 'second')

      comment1 = post1.comments.create(:body => 'first')
      comment2 = post1.comments.create(:body => 'second')
      comment3 = post2.comments.create(:body => 'third')
      comment4 = post2.comments.create(:body => 'fourth')
    end

    it "should detect no unpreload association" do
      Post.all
      Post.first.comments.collect(&:body)
      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end

  context "STI" do
    before :all do
      user1 = User.create(:name => 'user1')
      user2 = User.create(:name => 'user2')
      folder1 = Folder.create(:name => 'folder1', :user_id => user1.id)
      folder2 = Folder.create(:name => 'folder2', :user_id => user2.id)
      page1 = Page.create(:name => 'page1', :parent_id => folder1.id, :user_id => user1.id)
      page2 = Page.create(:name => 'page2', :parent_id => folder1.id, :user_id => user1.id)
      page3 = Page.create(:name => 'page3', :parent_id => folder2.id, :user_id => user2.id)
      page4 = Page.create(:name => 'page4', :parent_id => folder2.id, :user_id => user2.id)
    end

    it "should detect unpreload associations" do
      Page.all.each do |page|
        page.user.name
      end
      Bullet::Detector::Association.should be_detecting_unpreload_association_for(Page, :user)
    end

    it "should not detect unpreload associations" do
      Page.includes(:user).each do |page|
        page.user.name
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should detect unused preload associations" do
      Page.includes(:user).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_association_for(Page, :user)
    end

    it "should not detect unused preload associations" do
      Page.all.collect(&:name)
      Bullet::Detector::Association.should be_completely_preloading_associations
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end
end
