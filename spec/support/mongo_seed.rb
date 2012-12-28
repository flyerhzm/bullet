module Support
  module MongoSeed
    def seed_db
      category1 = Mongoid::Category.create(:name => 'first')
      category2 = Mongoid::Category.create(:name => 'second')

      post1 = category1.posts.create(:name => 'first')
      post1a = category1.posts.create(:name => 'like first')
      post2 = category2.posts.create(:name => 'second')

      post1.users << Mongoid::User.create(:name => 'first')
      post1.users << Mongoid::User.create(:name => 'another')
      post2.users << Mongoid::User.create(:name => 'second')

      comment1 = post1.comments.create(:name => 'first')
      comment2 = post1.comments.create(:name => 'first2')
      comment3 = post1.comments.create(:name => 'first3')
      comment4 = post1.comments.create(:name => 'second')
      comment8 = post1a.comments.create(:name => "like first 1")
      comment9 = post1a.comments.create(:name => "like first 2")
      comment5 = post2.comments.create(:name => 'third')
      comment6 = post2.comments.create(:name => 'fourth')
      comment7 = post2.comments.create(:name => 'fourth')

      entry1 = category1.entries.create(:name => 'first')
      entry2 = category1.entries.create(:name => 'second')

      company1 = Mongoid::Company.create(:name => 'first')
      company2 = Mongoid::Company.create(:name => 'second')

      Mongoid::Address.create(:name => 'first', :company => company1)
      Mongoid::Address.create(:name => 'second', :company => company2)
    end

    def setup_db
      if Mongoid::VERSION =~ /\A2\.([4-9]|[1-9][0-9]+)/
        Mongoid.configure do |config|
          config.master = Mongo::Connection.new.db("bullet")
        end
      elsif Mongoid::VERSION =~ /\A3/
        Mongoid.configure do |config|
          config.connect_to("bullet")
        end
      end
    end

    def teardown_db
      Mongoid.purge!
    end

    extend self
  end
end
