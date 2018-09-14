require 'spec_helper'

describe 'Authorization factories' do
  describe ':authorization' do
    let(:factory) { :authorization }

    describe ':with_references trait' do
      let(:trait) { :with_references }

      describe '#create' do
        let(:options) { {} }
        subject { create factory, trait, options }

        it { should be_valid }

        it { should be_persisted }

        it 'creates account' do
          expect(subject.account).to be_valid
          expect(subject.account).to be_persisted
        end

        it 'creates identity with account and sets #identity to that identity' do
          accounts_identity = subject.account.identities.first
          expect(accounts_identity).to be_valid
          expect(accounts_identity).to be_persisted
          expect(subject.identity).to eq accounts_identity
        end

        context 'when #nickname attribute is provided' do
          let(:nickname) { 'Nick' }
          let(:options) { {nickname: nickname} }

          it 'sets #nickname of #identity' do
            expect(subject.identity.nickname).to eq nickname
          end
        end

        context 'when #friend_identity attribute is provided' do
          let(:identity) { create :identity }
          let(:options) { {friend_identity: identity} }

          it 'makes provided identity a friend with #identity' do
            expect(subject.identity.friends).to include identity.id
            expect(identity.friends).to include subject.identity.id
          end
        end
      end
    end
  end
end
