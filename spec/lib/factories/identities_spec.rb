require 'spec_helper'

describe 'Identities factories' do
  describe ':identity' do
    describe '#create' do
      subject { create :identity }

      it { should be_valid }
    end

    describe ':with_attributes trait' do
      describe '#create' do
        subject { create :identity, :with_attributes }

        it { should be_valid }
      end
    end
  end
end
