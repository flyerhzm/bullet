require 'benchmark'
require 'rails'
require 'active_record'
require 'activerecord-import'
require 'bullet'

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
end

class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
end

# create database bullet_benchmark;
ActiveRecord::Base.establish_connection(:adapter => 'mysql', :database => 'bullet_benchmark', :server => '/tmp/mysql.socket', :username => 'root')

ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table(table)
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :posts do |t|
    t.column :title, :string
    t.column :body, :string
    t.column :user_id, :integer
  end

  create_table :comments do |t|
    t.column :body, :string
    t.column :post_id, :integer
    t.column :user_id, :integer
  end

  create_table :users do |t|
    t.column :name, :string
  end
end

users = []
100.times do |i|
  users << User.new(:name => "user#{i}")
end
User.import users
users = User.all

posts = []
1000.times do |i|
  posts << Post.new(:title => "Title #{i}", :body => "Body #{i}", :user => users[i%100])
end
Post.import posts
posts = Post.all

comments = []
10000.times do |i|
  comments << Comment.new(:body => "Comment #{i}", :post => posts[i%1000], :user => users[i%100])
end
Comment.import comments

puts "Start benchmarking..."

Benchmark.bm(70) do |bm|
  bm.report("Querying & Iterating 1000 Posts with 10000 Comments and 100 Users") do
    Bullet.start_request
    Post.select("SQL_NO_CACHE *").includes(:user, :comments => :user).each do |p|
      p.title
      p.user.name
      p.comments.each do |c|
        c.body
        c.user.name
      end
    end
    Bullet.end_request
  end
end

puts "End benchmarking..."


# 2.0.1
#                                                                             user     system      total        real
# Querying & Iterating 100 Posts with 10000 Comments and 100 Users        2.290000   0.050000   2.340000 (  2.366174)

