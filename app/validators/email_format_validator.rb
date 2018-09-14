# # Formerly it was like this
# class EmailFormatValidator < ActiveModel::EachValidator
#   def validate_each(object, attribute, value)
#     unless value =~ /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i
#       object.errors[attribute] << (options[:message] || I18n.t('errors.messages.invalid'))
#     end
#   end
# end
#
class EmailFormatValidator < ActiveModel::EachValidator
  RE_DOMAIN = %r(^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)+$)

  def validate_each(record, attribute, value)
    r = true
    r &&= value =~ /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i
    begin
      m = Mail::Address.new(value)
      # We must check that value contains a domain and that value is an email address
      r &&= m.domain && m.address == value
      r &&= m.domain =~ RE_DOMAIN
      t = m.__send__(:tree)
      # We need to dig into treetop
      # A valid domain must have dot_atom_text elements size > 1
      # user@localhost is excluded
      # treetop must respond to domain
      # We exclude valid email values like <user@localhost.com>
      # Hence we use m.__send__(tree).domain
      r &&= (t.domain.dot_atom_text.elements.size > 1)
    rescue
      r = false
    end
    record.errors[attribute] << (options[:message] || I18n.t('errors.messages.invalid')) unless r
  end
end
