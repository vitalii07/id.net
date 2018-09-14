require 'spec_helper'

describe 'Feed factory' do
  describe 'build' do
    subject { build :feed }

    it { should be_valid }

    it 'includes request_information' do
      expect(subject.request_information).to be_present
      expect(subject.request_information.ip).to be_present
      expect(subject.request_information.user_agent).to be_present
      expect(subject.request_information.referer).to be_present
    end

    it 'has valid relations' do
      expect(subject.author).to be_valid
      expect(subject.recipient).to be_valid
    end
  end

  describe 'create' do
    subject { create :feed }

    it { should be_valid }

    it 'includes request_information' do
      expect(subject.request_information).to be_present
      expect(subject.request_information.ip).to be_present
      expect(subject.request_information.user_agent).to be_present
      expect(subject.request_information.referer).to be_present
    end
  end
end

describe 'SiteFeed factory' do
  describe 'attributes_for' do
    subject { attributes_for :site_feed }

    it 'does not include author and recipient' do
      expect(subject).not_to have_key :author
      expect(subject).not_to have_key :author_id
      expect(subject).not_to have_key :recipient
      expect(subject).not_to have_key :recipient_key
    end
  end
end

describe 'ApplicationRequest factory' do
  let(:client) { build_stubbed :client }
  subject do
    build :application_request,
      client:                   client
  end

  it { should be_valid }
end
