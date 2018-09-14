require 'spec_helper'

describe Idnet::Core::Utils do
  let(:subject){ Idnet::Core::Utils }
  describe '#to_ids' do
    it 'should return BSON::ObjectId' do
      s = Struct.new :id
      a = 4.times.map{ s.new(BSON::ObjectId.new) }
      subject.to_ids(a).should be_all{|i| BSON::ObjectId === i}
    end

    it 'should return an Array with single argument' do
      subject.to_ids(BSON::ObjectId.new).should be_an_instance_of Array
    end

    it 'should return an empty Array with nil' do
      subject.to_ids(nil).should == []
    end
  end

  describe '#to_models' do
    let!(:identities) {create_list :identity, 6}

    it 'should not modify array of models of given class' do
      subject.to_models(identities, Identity).should =~ identities
    end

    it 'should return empty list if other class is set' do
      subject.to_models(identities, Authorization).should == []
    end

    it 'should find models by id' do
      subject.to_models(identities.first.id, Identity).should == [identities.first]
    end
  end
end
