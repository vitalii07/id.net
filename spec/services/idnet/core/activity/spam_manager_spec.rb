require 'spec_helper'

describe Idnet::Core::Activity::SpamManager do
  describe '#check!', broken: true do
    let(:feed) { build :site_feed, spam_state: 'unknown' }
    let(:spam?) { true }
    subject { described_class.new(feed).check! }
    before { allow_any_instance_of(Idnet::Core::Activity::SpamCheckServiceConnection).to receive(:spam?).and_return(spam?) }

    it 'initializes SpamCheckServiceConnection with activity' do
      expect(Idnet::Core::Activity::SpamCheckServiceConnection).to receive(:new).with(feed).and_return double('conn', spam?: true)
      subject
    end

    it 'calls SpamCheckServiceConnection#spam?' do
      expect_any_instance_of(Idnet::Core::Activity::SpamCheckServiceConnection).to receive(:spam?)
      subject
    end

    context 'when SpamCheckServiceConnection#spam? returns true' do
      let(:spam?) { true }

      it { should be true }

      it 'calls Activity#schedule_for_review!' do
        expect(feed).to receive :schedule_for_review!
        subject
      end
    end

    context 'when SpamCheckServiceConnection#spam? returns false' do
      let(:spam?) { false }

      it { should be false }

      it 'calls Feed#mark_as_not_spam!' do
        expect(feed).to receive :mark_as_not_spam!
        subject
      end
    end

    context 'when SpamCheckServiceConnection#spam? returns nil' do
      let(:feed) { stub valid?: true}
      let(:spam?) { nil }

      it { should be_nil }

      it 'does nothing with feed' do
        # Calling any method on empty stub will fail test
        subject
      end
    end

    context 'when feed is invalid' do
      before { allow(feed).to receive(:valid?).and_return false }

      it { should be_nil }

      it 'does not use SpamCheckServiceConnection' do
        expect(Idnet::Core::Activity::SpamCheckServiceConnection).to_not receive(:new)
        subject
      end
    end
  end
end
