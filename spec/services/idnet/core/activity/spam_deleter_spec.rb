require 'spec_helper'

describe Idnet::Core::Activity::SpamDeleter do
  describe '#delete' do
    let(:oldness_threshold) { Time.now - Idnet.config.application.spam_ttl.hours - 1.hour }
    let!(:feed) { create :site_comment }
    let!(:old_feed) { create :site_comment, updated_at: oldness_threshold }
    let!(:spam_feed) { create :site_comment, spam_state: :spam }
    let!(:old_spam_feed) { create :site_comment, spam_state: :spam, updated_at: oldness_threshold }

    it 'deletes only old spam Site_Feed record' do
      subject.delete

      expect do
        feed.reload
        old_feed.reload
        spam_feed.reload
      end.not_to raise_error
      expect { old_spam_feed.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
