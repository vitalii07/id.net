class Score
  include Mongoid::Document
  include Mongoid::Timestamps
  include ScoreSearch

  belongs_to :client
  belongs_to :account
  belongs_to :authorization

  field :value, type: Integer, default: 0
  field :nickname, type: String
  field :country
  validates :value, numericality: {greater_than_or_equal_to: 0}

  attr_accessible :nickname, :country, :value

  index({client_id: 1})
  index({account_id: 1})
  index({authorization_id: 1})
  index({account_id: 1, client_id: 1}, unique: true)

  before_create do
    if authorization_id && authorization
      self.client_id ||= authorization.client_id
      self.account_id ||= authorization.account_id
    end
  end

  after_destroy { |record| client_reimport(record.client.id) if record.client }
  after_create  { |record| client_reimport(record.client.id) if record.client }
  after_update  { |record| client_reimport(record.client.id) if record.client }

  def client_reimport(client_id)
    ::Client.where(id: client_id).import
  end
end
