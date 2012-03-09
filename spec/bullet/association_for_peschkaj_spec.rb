require File.dirname(__FILE__) + '/../spec_helper'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
# This test is just used for http://github.com/flyerhzm/bullet/issues#issue/20
describe Bullet::Detector::Association do

  describe "for peschkaj" do
    it "should not detect unused preload associations" do
      category = Category.includes({:submissions => :user}).order("id DESC").find_by_name('first')
      category.submissions.map do |submission|
        submission.name
        submission.user.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_unused_preload_associations_for(Category, :submissions)
      Bullet::Detector::Association.should_not be_unused_preload_associations_for(Submission, :user)
    end
  end
end
