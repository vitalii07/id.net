require 'uri'
class UriValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    r = true
    begin
      uri = ::URI.parse value
      r &&= (uri.scheme || uri.host) if options[:absolute]
      r &&= (uri.scheme.in? options[:schemes]) if options[:schemes]
    rescue => e
      r = false
    end
    record.errors.add attribute, (options[:message] || "is invalid") unless r
  end

  def self.kind
    :custom
  end
end
