class MigrateHardCodedFieldsToIdentityForm < Mongoid::Migration
  # This migration need to be fixed with api v1
  # We do not need all the fields in address for each client
  def self.up
    Client.update()
    fields = Hash[IdentityForm::FIELDS.zip([true] * IdentityForm::FIELDS.size)]
    fields['avatar'] = false

    # We need to loop since identity_for need a BSON _id
    Client.all.each do |c|
      c.identity_form.attributes = fields
      c.identity_form.save!
    end

    regexp_fields = {
      '^CamZap' => %w{email nickname gender address date_of_birth},
      '^(Y8|POG|GAMEPOST|DOLLMANIA)\.COM$' => %w{email nickname gender address date_of_birth},
      '^Sexy1.com$' => %w{email first_name last_name nickname gender date_of_birth}
    }

    regexp_fields.each do |regexp, fields_list|
      Client.where(display_name: {'$regex' => regexp}).all.each do |c|
        IdentityForm::FIELDS.each do |f|
          next if f.to_s.in?(fields_list)
          c.identity_form[f] = false
        end
        c.identity_form.save!
      end
    end
  end

  def self.down
  end
end
