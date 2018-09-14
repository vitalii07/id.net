class AdminMessagesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if attribute.to_s == 'documents'
      record.documents.each do |d|
        if record.messages["documents_#{d.id}"].present?
          record.errors[:base] << I18n.t('mongoid.errors.models.idnet/core/attachment.rejected_document') and return
        end
      end
    end

    if record.messages[attribute.to_s].present?
      record.errors[attribute] << I18n.t('mongoid.errors.models.idnet/core/attachment.rejected')
    end
  end
end
