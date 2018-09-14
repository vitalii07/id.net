class LatinSymbolsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if attribute == :messages
      record.messages.each do |key, value|
        check_if_latin record, key, value
      end
    else
      check_if_latin record, attribute, value
    end
  end

  private

  def check_if_latin record, attribute, value
    if value.to_s =~ /[^-.a-zA-Z0-9, \/]/
      record.errors[attribute] << I18n.t('mongoid.errors.models.idnet/core/attachment.latin_only')
    end
  end
end