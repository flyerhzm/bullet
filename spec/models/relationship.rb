class Relationship < ActiveRecord::Base
  belongs_to :firm
  belongs_to :client
end
