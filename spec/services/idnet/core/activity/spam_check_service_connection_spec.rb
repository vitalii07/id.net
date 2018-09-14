require 'spec_helper'

describe Idnet::Core::Activity::SpamCheckServiceConnection do
  let(:feed) { build :site_feed }

  describe '#spam?' do
    let(:spam?) { false }
    subject { described_class.new(feed).spam? }
    let! :stub_api_request do
      stub_request(:post, %r"\A[^.]+\.rest\.akismet\.com/[\d.]+/comment-check\Z").
        to_return body: spam?.to_s
    end

    it 'hits stubbed request' do
      subject
      expect(stub_api_request).to have_been_made
    end

    it { should be false }

    context 'when spam detected' do
      let(:spam?) { true }

      it { should be true }
    end

    context 'when there is some error' do
      let(:spam?) { 'Error message' }

      it { should be_nil }
    end

    context 'when request_information does not have IP' do
      before do
        feed.request_information.ip = nil
      end

      it { should be_nil }

      it 'does not make network request' do
        subject
        expect(stub_api_request).not_to have_been_made
      end
    end
  end

  describe '#spam_check_successful?' do
    let(:connection) { described_class.new(feed) }
    subject do
      connection.spam?
      connection.spam_check_successful?
    end
    let! :stub_api_request do
      stub_request(:post, %r"\A[^.]+\.rest\.akismet\.com/[\d.]+/comment-check\Z").
        to_return body: 'true'
    end

    it 'hits stubbed request' do
      subject
      expect(stub_api_request).to have_been_made
    end

    it { should be true }

    context 'when spam check failed' do
      let! :stub_api_request do
        stub_request(:post, %r"\A[^.]+\.rest\.akismet\.com/[\d.]+/comment-check\Z").
          to_return body: 'Error'
      end

      it 'hits stubbed request' do
        subject
        expect(stub_api_request).to have_been_made
      end

      it { should be false }
    end

    context 'when there was no spam check performed yet' do
      subject { connection.spam_check_successful? }

      it { should be_nil }
    end
  end
end
