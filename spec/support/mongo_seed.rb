module Support
  module MongoSeed
    def seed_db
      post1 = Mongoid::Post.create(:name => 'first')
      post2 = Mongoid::Post.create(:name => 'second')

      comment1 = post1.comments.create(:name => 'first')
      comment2 = post1.comments.create(:name => 'second')
      comment3 = post2.comments.create(:name => 'third')
      comment4 = post2.comments.create(:name => 'fourth')
    end

    def setup_db
      Mongoid.database = Mongo::Connection.new("localhost", 27017).db("bullet")
    end

    def teardown_db
      Mongoid.database.collections.select {|c| c.name !~ /system/ }.map(&:drop)
    end

    extend self
  end
end
