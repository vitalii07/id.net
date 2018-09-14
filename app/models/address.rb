class Address
  include Mongoid::Document

  store_in collection: 'idnet_core_addresses'

  embedded_in :identity, class_name: 'Identity'

  validates :street_address,    length: { minimum: 2, maximum: 500, allow_blank: true }
  validates :state_or_province, length: { minimum: 2, maximum: 255, allow_blank: true }
  validates :city,              length: { minimum: 2, maximum: 255, allow_blank: true }
  validates :zipcode, format: { with: /\A[-a-zA-Z0-9]+\z/, allow_blank: true }

  field :street_address
  field :state_or_province
  field :city
  field :zipcode
  field :country

  def self.fields_accessors
    accessors = fields.keys - ['_type', '_id']
    accessors.map{|i| [i, "#{i}="]}.flatten
  end

end
