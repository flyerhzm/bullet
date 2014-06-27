require 'spec_helper'

describe Bullet, focused: true do
  subject { Bullet }

  describe '#enable' do

    context 'enable Bullet' do
      before do
        # Bullet.enable
        # Do nothing. Bullet has already been enabled for the whole test suite.
      end

      it 'should be enabled' do
        expect(subject).to be_enable
      end

      context 'disable Bullet' do
        before do
          Bullet.enable = false
        end

        it 'should be disabled' do
          expect(subject).to_not be_enable
        end

        context 'enable Bullet again without patching again the orms' do
          before do
            expect(Bullet::Mongoid).not_to receive(:enable) if defined? Bullet::Mongoid
            expect(Bullet::ActiveRecord).not_to receive(:enable) if defined? Bullet::ActiveRecord
            Bullet.enable = true
          end

          it 'should be enabled again' do
            expect(subject).to be_enable
          end
        end
      end
    end
  end
end
