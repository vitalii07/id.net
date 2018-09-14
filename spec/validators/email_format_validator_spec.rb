require 'spec_helper'

describe EmailFormatValidator, no_mongo: true do
  Person = Class.new do
    include ActiveModel::Validations
    def initialize(attributes = {})
      @attributes = attributes
      super
    end

    def email
      @attributes[:email]
    end
  end

  subject { EmailFormatValidator.new(attributes: [:email]) }

  it 'should validate real email' do
    person = Person.new email: 'test@id.net'
    subject.validate_each(person, :email, person.email)
    expect(person.errors.to_a).to be_blank
  end

  shared_examples_for 'bad email' do |email|
    it %Q("#{email}" should be invalid) do
      object = Person.new email: email
      subject.validate_each(object, :email, email)
      expect(object.errors.to_a).not_to be_blank
    end
  end

  it_should_behave_like 'bad email', 'test@-id.net'
  it_should_behave_like 'bad email', 'test@id,net'
  it_should_behave_like 'bad email', 'test@id'
  it_should_behave_like 'bad email', 'test'
  it_should_behave_like 'bad email', 'test-'
end
