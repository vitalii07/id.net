# coding: utf-8

require 'spec_helper'
class Person
  include ActiveModel::Validations
  attr_reader :attributes

  validates :nickname, nickname: true

  def initialize(attributes = {})
    @attributes = attributes
  end

  def nickname
    @attributes[:nickname]
  end

  def nickname=(nick)
    @attributes[:nickname] = nick
  end

end

describe NicknameValidator, no_mongo: true do
  let!(:person){ Person.new nickname: 'john' }
  let!(:validator){ NicknameValidator.new(attributes: [:nickname])}

  it 'should not allow utf-8' do
    person.nickname = 'Jürgen'
    person.should be_invalid
  end

  it 'should allow valid nickname' do
    person.nickname = 'Jean'
    person.should be_valid
  end

  it 'should not allow spaces' do
    person.nickname = 'Jean Dupont'
    person.should be_invalid
  end

  it 'should not allow dash at start' do
    person.nickname = '-minus10'
    person.should be_invalid
  end

  it 'should not start with underscore' do
    person.nickname = '_minus10'
    person.should be_invalid
  end

  it 'should not start with space' do
    person.nickname = ' minus10'
    person.should be_invalid
  end

  it 'should not end with dash' do
    person.nickname = 'minus10-'
    person.should be_invalid
  end

  it 'should not end with underscore' do
    person.nickname = 'minus10_'
    person.should be_invalid
  end

  it 'should allow dash and underscores' do
    person.nickname = 'hello_world-minus10'
    person.should be_valid
  end

  it 'should allow one letter' do
    person.nickname = 'a'
    person.should be_valid
  end

  it 'should not allow 2 consecutives dashes or underscores or points' do
    person.nickname = 'Hello--World'
    person.should be_invalid
    person.nickname = 'Hello-_World'
    person.should be_invalid
    person.nickname = 'Hello..World'
    person.should be_invalid
  end
end
