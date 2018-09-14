class DocumentsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      if record.documents.cleared.blank?
        record.errors[:base] << I18n.t('mongoid.errors.models.idnet/core/attachment.blank')
      end
    else
      unless value.first.image? || value.first.pdf?
        message = I18n.t('mongoid.errors.models.idnet/core/attachment.image_pdf')
        record.errors[:base] << message
      end
    end
  end
end
