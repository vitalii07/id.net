class NicknameValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    return unless value.present?
    r = %r@
    (?!.*[-_.]{2,}.*) # Does not contain two consecutives dashes, underscores, dots
    (?!^[-_.]) # Does not start with dash or undescore
    ^([-_.a-zA-Z0-9]+)$ # Does include a underscore, dash, dot, alnums only
    (?<![-_.]$) # Does not end with dash or underscore or dot
    @mx # Multiline, commentable
    unless value =~ r
      object.errors.add(attribute, :corrected_nickname, :previous => value)
    end
  end
end
