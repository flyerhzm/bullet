require File.dirname(__FILE__) + '/../spec_helper'

describe Bullet::Detector::Association, 'has_many' do

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
  #
  ### FIXME: Please double check semantic equivalence with original
    it "should detect preload with post => comments" do
      Post.includes(:comments).each do |post|
        post.comments.collect(&:name)
      end
      # Bullet::Detector::Association.should_not be_has_unpreload_associations
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect no preload post => comments" do
      Post.all.each do |post|
        post.comments.collect(&:name)
      end
      # Bullet::Detector::Association.should be_has_unpreload_associations
      Bullet::Detector::Association.should_not be_completely_preloading_associations
    end

    it "should detect unused preload post => comments for post" do
      Post.includes(:comments).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_has_unused_preload_associations
    end

    it "should detect no unused preload post => comments for post" do
      Post.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should detect no unused preload post => comments for comment" do
      Post.all.each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet.end_request
      Bullet.start_request

      Post.all.each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end

  context "category => posts => comments" do
    it "should detect preload with category => posts => comments" do
      Category.includes({:posts => :comments}).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      # Bullet::Detector::Association.should_not be_has_unpreload_associations
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect preload category => posts, but no post => comments" do
      Category.includes(:posts).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      # Bullet::Detector::Association.should be_has_unpreload_associations
      Bullet::Detector::Association.should_not be_completely_preloading_associations
    end

    it "should detect no preload category => posts => comments" do
      Category.all.each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      # Bullet::Detector::Association.should be_has_unpreload_associations
      Bullet::Detector::Association.should_not be_completely_preloading_associations
    end

    it "should detect unused preload with category => posts => comments" do
      Category.includes({:posts => :comments}).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_has_unused_preload_associations
    end

    it "should detect unused preload with post => commnets, no category => posts" do
      Category.includes({:posts => :comments}).each do |category|
        category.posts.collect(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_has_unused_preload_associations
    end

    it "should no detect preload with category => posts => comments" do
      Category.all.each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end

  context "category => posts, category => entries" do
    it "should detect preload with category => [posts, entries]" do
      Category.includes([:posts, :entries]).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect preload with category => posts, but no category => entries" do
      Category.includes(:posts).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Detector::Association.should_not be_completely_preloading_associations
    end

    it "should detect no preload with category => [posts, entries]" do
      Category.all.each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Detector::Association.should_not be_completely_preloading_associations
    end

    it "should detect unused with category => [posts, entries]" do
      Category.includes([:posts, :entries]).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_has_unused_preload_associations
    end

    it "should detect unused preload with category => entries, but no category => posts" do
      Category.includes([:posts, :entries]).each do |category|
        category.posts.collect(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_has_unused_preload_associations
    end

    it "should detect no unused preload" do
      Category.all.each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end

  context "no preload" do
    it "should no preload only display only one post => comment" do
      Post.includes(:comments).each do |post|
        post.comments.first.name
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should no preload only one post => commnets" do
      Post.first.comments.collect(&:name)
      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end

  context "scope for_category_name" do
    it "should detect preload with post => category" do
      Post.in_category_name('first').all.each do |post|
        post.category.name
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should not be unused preload post => category" do
      Post.in_category_name('first').all.collect(&:name)
      Bullet::Detector::Association.should be_completely_preloading_associations
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end

  context "scope preload_posts" do
    it "should no preload post => comments with scope" do
      Post.preload_posts.each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should unused preload with scope" do
      Post.preload_posts.collect(&:name)
      Bullet::Detector::Association.should be_completely_preloading_associations
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_has_unused_preload_associations
    end
  end

  context "no unused" do
    it "should no unused only display only one post => comment" do
      Post.includes(:comments).each do |post|
        i = 0
        post.comments.each do |comment|
          if i == 0
            comment.name
          else
            i += 1
          end
        end
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end

  context "belongs_to" do
    it "should preload comments => post" do
      Comment.all.each do |comment|
        comment.post.name
      end
      Bullet::Detector::Association.should_not be_completely_preloading_associations
    end

    it "should no preload comment => post" do
      Comment.first.post.name
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should no preload comments => post" do
      Comment.includes(:post).each do |comment|
        comment.post.name
      end
      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect no unused preload comments => post" do
      Comment.all.collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should detect unused preload comments => post" do
      Comment.includes(:post).collect(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_has_unused_preload_associations
    end

    it "should dectect no unused preload comments => post" do
      Comment.all.each do |comment|
        comment.post.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end

    it "should dectect no unused preload comments => post" do
      Comment.includes(:post).each do |comment|
        comment.post.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end
end

describe Bullet::Detector::Association, 'has_and_belongs_to_many' do
  it "should detect unpreload associations" do
    Student.all.each do |student|
      student.teachers.collect(&:name)
    end
    Bullet::Detector::Association.should_not be_completely_preloading_associations
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
    Bullet::Detector::Association.should be_has_unused_preload_associations
  end

  it "should detect no unused preload associations" do
    Student.all.collect(&:name)
    Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
    Bullet::Detector::Association.should_not be_has_unused_preload_associations
  end
end

describe Bullet::Detector::Association, 'has_many :through' do
  it "should detect unpreload associations" do
    Firm.all.each do |firm|
      firm.clients.collect(&:name)
    end
    Bullet::Detector::Association.should_not be_completely_preloading_associations
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
    Bullet::Detector::Association.should be_has_unused_preload_associations
  end
end



describe Bullet::Detector::Association, "has_one" do
  it "should detect unpreload association" do
    Company.all.each do |company|
      company.address.name
    end
    Bullet::Detector::Association.should_not be_completely_preloading_associations
  end

  it "should detect no unpreload association" do
    Company.find(:all, :include => :address).each do |company|
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
    Company.find(:all, :include => :address).collect(&:name)
    Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
    Bullet::Detector::Association.should be_has_unused_preload_associations
  end
end

describe Bullet::Detector::Association, "call one association that in possible objects" do
  it "should detect no unpreload association" do
    Contact.all
    Contact.first.emails.collect(&:name)
    Bullet::Detector::Association.should be_completely_preloading_associations
  end
end

describe Bullet::Detector::Association, "STI" do
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
