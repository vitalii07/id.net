require 'spec_helper'

describe Idnet::Api::V1::ApplicationScoresAuthorizationsQuery do
  describe '#fetch' do
    let(:score) { 256 }
    let(:friends_score) { 123 }
    let(:strangers_score) { 456 }
    let(:friends_authorization) do
      create :authorization, :with_references,
        client: client,
        score_value: friends_score,
        nickname: 'NicksFriend',
        friend_identity: authorization.identity
    end
    let(:strangers_authorization) { create :authorization, :with_references, client: client, score_value: strangers_score, nickname: 'Stranger' }
    subject { described_class.new(client).fetch }
    let!(:authorization) { create :authorization, :with_references, client: client, score_value: score, nickname: 'Nick' }

    it { should eq [authorization] }

    context 'when user has no score set' do
      let(:score) {}

      it { should eq [] }

      context 'and has friend' do
        before { friends_authorization }

        context 'with score set' do
          it { should eq [friends_authorization] }
        end

        context 'without score set' do
          let(:friends_score) {}

          it { should eq [] }
        end
      end
    end

    context 'when user has a friend' do
      before { friends_authorization }

      context 'and user has score bigger than score of friend' do
        let(:score) { 10 }
        let(:friends_score) { 5 }

        it { should eq [authorization, friends_authorization] }
      end

      context 'and friend has bigger score' do
        let(:score) { 512 }
        let(:friends_score) { 1024 }

        it { should eq [friends_authorization, authorization] }
      end

      context 'and friend does not have score' do
        let(:friends_score) {}

        it { should eq [authorization] }
      end
    end

    context 'when there is an unrelated user present' do
      before { strangers_authorization }

      context 'with scores present' do
        it { should eq [strangers_authorization, authorization] }
      end

      context 'without score present' do
        let(:strangers_score) {}

        it { should eq [authorization] }
      end

      context 'and user has a friend' do
        before { friends_authorization }

        it { should eq [strangers_authorization, authorization, friends_authorization] }
      end
    end

    context 'when there are no authorizations' do
      let(:authorization) {}

      it { should eq [] }
    end
  end
end
