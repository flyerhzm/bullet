# frozen_string_literal: true

require 'spec_helper'

if active_record?
  describe Bullet::Detector::NPlusOneQuery, 'optional polymorphic belongs_to' do
    context 'with nil _type column on every host record' do
      it 'does not flag N+1 when accessed without preload' do
        roles = Role.all.to_a
        roles.each { |role| role.resource }

        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association)
          .not_to be_detecting_unpreloaded_association_for(Role, :resource)
        expect(Bullet::Detector::Association)
          .not_to be_has_unused_preload_associations
      end

      it 'does not flag N+1 when accessed after preload' do
        roles = Role.preload(:resource).to_a
        roles.each { |role| role.resource }

        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association)
          .not_to be_detecting_unpreloaded_association_for(Role, :resource)
        expect(Bullet::Detector::Association)
          .not_to be_has_unused_preload_associations
      end
    end

    context 'with non-nil _type column on host records' do
      before do
        post_id = Post.connection.select_value('SELECT id FROM posts LIMIT 1')
        Role.connection.execute(
          "UPDATE roles SET resource_type = 'Post', resource_id = #{post_id}"
        )
        Bullet.end_request
        Bullet.start_request
      end

      after do
        Role.connection.execute('UPDATE roles SET resource_type = NULL, resource_id = NULL')
      end

      it 'still flags N+1 when accessed without preload' do
        roles = Role.all.to_a
        roles.each { |role| role.resource }

        expect(Bullet::Detector::Association)
          .to be_detecting_unpreloaded_association_for(Role, :resource)
      end
    end
  end
end
