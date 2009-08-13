require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/associations'
require File.join(File.dirname(__FILE__), '../lib/bullet')

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

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

class BulletTest < Test::Unit::Testcase
  def setup
    setup_db
  end

  def teardown
    teardown_db
  end

  def test_detect_preload
    assert true
  end
end
