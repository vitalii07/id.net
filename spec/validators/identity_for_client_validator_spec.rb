require 'spec_helper'

describe IdentityForClientValidator do
  describe '#validate' do
    let(:identity_form) { build :identity_form }
    let(:field_name) { nil }
    let(:required_fields) { [field_name].compact.map &:to_s }
    let(:client) { build :client, identity_form: identity_form }
    let(:attributes) { {} }
    let(:identity) { build :identity, :with_attributes, attributes.merge(account: nil) }
    subject { described_class.new(client, identity).validate }
    before do
      allow(identity).to receive(:valid?)
      allow(identity_form).to receive(:required_fields).and_return required_fields
    end

    it { should be true }

    it 'does not add errors' do
      subject
      expect(identity.errors).to be_blank
    end

    context 'when identity has errors' do
      before { identity.errors[:nickname] << 'error' }

      it { should be false }
    end

    context 'when MANDATORY_FIELD #nickname is required' do
      let(:field_name) { :nickname }

      it { should be true }

      it 'does not add errors' do
        subject
        expect(identity.errors).to be_blank
      end

      context 'when #nickname is blank' do
        let(:attributes) { {nickname: nil} }

        it { should be true }

        it 'does not add errors' do
          subject
          expect(identity.errors).to be_blank
        end
      end
    end

    shared_examples_for 'required field' do
      it { should be true }

      it 'does not add errors' do
        subject
        expect(identity.errors).to be_blank
      end

      context 'and it is blank' do
        let(:attributes) { {field_name => nil} }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[field_name]).to eq ["can't be blank"]
        end
      end
    end

    context 'when #email field is required in IdentityForm' do
      let(:field_name) { :email }

      it_behaves_like 'required field'

      context 'and has bad format' do
        let(:attributes) { {email: 'bad email address'} }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:email]).to eq ['is invalid']
        end
      end
    end

    context 'when #first_name field is required in IdentityForm' do
      let(:field_name) { :first_name }

      it_behaves_like 'required field'

      context 'and is too short' do
        let(:attributes) { {first_name: 'b'} }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:first_name][0]).to match /too short/
        end
      end

      context 'and is too long' do
        let(:attributes) { {first_name: 'name' * 100 } }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:first_name][0]).to match /too long/
        end
      end
    end

    context 'when #last_name field is required in IdentityForm' do
      let(:field_name) { :last_name }

      it_behaves_like 'required field'

      context 'and is too short' do
        let(:attributes) { {last_name: 'b'} }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:last_name][0]).to match /too short/
        end
      end

      context 'and is too long' do
        let(:attributes) { {last_name: 'name' * 100 } }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:last_name][0]).to match /too long/
        end
      end
    end

    context 'when #date_of_birth field is required in IdentityForm' do
      let(:field_name) { :date_of_birth }
      let(:age) { 5 }
      let(:attributes) { {date_of_birth: Time.now - age.years - 1} }

      it_behaves_like 'required field'

      context 'when client has #minimum_age set to 5' do
        before { client.minimum_age = 5 }

        context 'and identity has age of 4' do
          let(:age) { 4 }

          it { should be false }

          it 'adds error' do
            subject
            expect(identity.errors[:age][0]).to match /must be greater.*5/
          end
        end

        context 'and identity has age of 5' do
          let(:age) { 5 }

          it { should be true }

          it 'does not add errors' do
            subject
            expect(identity.errors).to be_blank
          end
        end

        context 'and identity has age of 6' do
          let(:age) { 6 }

          it { should be true }

          it 'does not add errors' do
            subject
            expect(identity.errors).to be_blank
          end
        end
      end


      context 'when client has #minimum_age set to 25' do
        before { client.minimum_age = 25 }

        context 'and identity has age of 4' do
          let(:age) { 4 }

          it { should be false }

          it 'adds error' do
            subject
            expect(identity.errors[:age][0]).to match /must be greater.*25/
          end
        end

        context 'and identity has #age set to 25' do
          let(:age) { 25 }

          it { should be true }

          it 'does not add errors' do
            subject
            expect(identity.errors).to be_blank
          end
        end

        context 'and identity has age of 46' do
          let(:age) { 46 }

          it { should be true }

          it 'does not add errors' do
            subject
            expect(identity.errors).to be_blank
          end
        end
      end
    end

    context 'when #language field is required in IdentityForm' do
      let(:field_name) { :language }

      it_behaves_like 'required field'

      context 'and is too short' do
        let(:attributes) { {language: 'b'} }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:language][0]).to match /too short/
        end
      end

      context 'and is too long' do
        let(:attributes) { {language: 'language' } }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:language][0]).to match /too long/
        end
      end
    end

    context 'when #gender field is required in IdentityForm' do
      let(:field_name) { :gender }

      it_behaves_like 'required field'

      context 'and is not among allowed values' do
        let(:attributes) { {gender: 'hermofrodite'} }

        it { should be false }

        it 'adds error' do
          subject
          expect(identity.errors[:gender][0]).to match /not included/
        end
      end
    end
  end
end
