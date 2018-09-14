# Validates {Identity} in context of a {Client}
# (based on {IdentityForm} of a {Client})
class IdentityForClientValidator
  FIELD_VALIDATORS = {
    email:      [[EmailFormatValidator]],
    first_name: [[ActiveModel::Validations::LengthValidator, {maximum: 255, minimum: 2}]],
    last_name:  [[ActiveModel::Validations::LengthValidator, {maximum: 255, minimum: 2}]],
    language:   [[ActiveModel::Validations::LengthValidator, {maximum: 5,   minimum: 2}]],
    gender:     [[ActiveModel::Validations::InclusionValidator, {in: %w(male female)}]]
  }

  # @param client [Client]
  # @param identity [Identity]
  def initialize(client, identity)
    @client, @identity = client, identity
  end

  # Runs validations of {Identity} based on
  # {Client}'s {IdentityForm} and adds errors if any
  # of them fail
  #
  # @return [Boolean]
  def validate
    # To reset all errors
    @identity.valid?

    if identity_fields_to_validate.present?
      validate_minimum_age
      validate_presence_of_fields
      validate_fields
    end

    @identity.errors.blank?
  end

  private

    # @return [void]
    def validate_minimum_age
      if @client.requires_minimum_age?
        ActiveModel::Validations::NumericalityValidator.new(
          attributes: [:age],
          greater_than_or_equal_to: @client.minimum_age
        ).validate @identity
      end
    end

    # @return [void]
    def validate_presence_of_fields
      ActiveModel::Validations::PresenceValidator.new(attributes: identity_fields_to_validate).validate @identity
    end

    # @return [void]
    def validate_fields
      FIELD_VALIDATORS.slice(*identity_fields_to_validate.map(&:to_sym)).each do |key, validators|
        validators.each do |validator, options|
          validator.new((options || {}).merge attributes: [key], allow_blank: true).validate @identity
        end
      end
    end

    # Excluding MANDATORY_FIELDS from validations because we assume that
    # MANDATORY_FIELDS are validated on {Identity} model itself
    #
    # @return [Array<String>, nil]
    def identity_fields_to_validate
      if @client.identity_form
        @client.identity_form.required_fields - IdentityForm::MANDATORY_FIELDS - ['generated_nickname']
      end
    end
end
