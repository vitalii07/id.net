require 'spec_helper'

describe Client do
  it { should be_stored_in :"oauth2.clients" }

  describe "Fields" do
    it { should have_fields(:display_name, :link, :image_url, :redirect_uri, :merchant_callback_uri,:consumer_login_uri, :notes, :secret, :terms_of_service_uri, :privacy_policy_uri, :app_type).of_type String }
    it { should have_fields(:tokens_revoked, :tokens_granted, :minimum_age).of_type Integer }
    it { should have_fields(:created_at, :revoked).of_type Time }
    it { should have_fields(:scope).of_type Array }
    it { should have_fields(:real_data_access).of_type Mongoid::Boolean }
    it { should have_fields(:is_checkout_client).of_type Mongoid::Boolean }
    it { should have_fields(:mobile_friendly).of_type Mongoid::Boolean }
  end

  describe "Relations" do
    it { should have_many(:authorizations).of_type Authorization }
    it { should embed_one(:identity_form) }
    it { should embed_many(:affiliates) }
  end

  describe "Validations" do
    it { should validate_presence_of(:display_name) }
    it { should validate_presence_of(:link) }
    it { should validate_presence_of(:redirect_uri) }

    it { should validate_inclusion_of(:app_type).to_allow(Client::APP_TYPES) }
    it { should validate_inclusion_of(:security_level).to_allow(Client::SECURITY_LEVELS) }

    it { should_not allow_mass_assignment_of :tokens_granted }
    it { should_not allow_mass_assignment_of :tokens_revoked }

    it { should custom_validate(:redirect_uri).with_validator(UriValidator) }
    it { should custom_validate(:link).with_validator(UriValidator) }
    it { should custom_validate(:privacy_policy_uri).with_validator(UriValidator) }
    it { should custom_validate(:terms_of_service_uri).with_validator(UriValidator) }
    it { should custom_validate(:consumer_login_uri).with_validator(UriValidator) }
    it { should custom_validate(:merchant_callback_uri).with_validator(UriValidator) }
    it { should custom_validate(:push_event_url).with_validator(UriValidator) }
    it { should custom_validate(:image_url).with_validator(UriValidator) }
  end

  it 'should use alternate name' do
    client = create :client, display_name: 'Test'
    client.display_name('Alternate name').should eq 'Alternate name'
    client.display_name.should eq 'Test'
  end

  it "should build identity_form" do
    subject.identity_form.should be_an_instance_of(IdentityForm)
  end

  describe "persisted" do
    subject{ create :client }

    let(:identity) do
      identity = Identity.new
      identity.account_id = BSON::ObjectId.new
      identity.identity_title = 'Test'
      identity
    end

    describe "Creation" do
      it "should persist identity_form with no required fields" do
        ident_form = subject.identity_form
        ident_form.should be_persisted
      end

      it "should be pending on creation" do
        Client.new.should be_pending
      end

      it "should be checkout client" do
        subject.should_not be_checkout
        subject.set is_checkout_client: true
        subject.should be_checkout
      end
    end

    describe "required fields" do
      it "can be updated" do
        IdentityForm::OPTIONAL_FIELDS.each do |f|
          f.should_not be_in(subject.identity_form_required_fields)
          subject.form_field?(f).should be false
          subject.identity_form[f] = true
          f.should be_in(subject.identity_form_required_fields)
          subject.form_field?(f).should be true
        end
      end

      it "works with generated_nickname as expected" do
        subject.form_field?(:nickname).should be true
        subject.form_field?(:generated_nickname).should be false

        subject.identity_form.generated_nickname = true
        subject.identity_form.save

        subject.form_field?(:nickname).should be false
        subject.form_field?(:generated_nickname).should be false
      end
    end

    describe "authorization creation" do
      let(:identity) { create :identity, identity_title: "Dummy", nickname: "Yoda" }

      let(:recipients) { create_list :identity, 5, nickname: "Jango_Fett" }

      before do
        allow(subject).to receive(:identity_form_required_fields).and_return([:nickname])
      end

      describe "ensuring authorizations" do
        it "should create authorizations for unregistered users" do
          authorizations_count = Authorization.count
          results = subject.ensure_authorizations_for recipients

          results.map(&:identity).should =~ recipients
          Authorization.count.should == authorizations_count + recipients.count
        end

        it "should create authorizations only once" do
          subject.ensure_authorizations_for recipients
          authorizations_count = Authorization.count
          subject.ensure_authorizations_for recipients
          authorizations_count.should == Authorization.count
        end

        it "should not create authorization if other identity has it" do
          other_identity = create :identity, account: identity.account
          auth = subject.create_authorization_for other_identity
          auth.should be_present
          results = subject.ensure_authorizations_for [identity]
          results.first.should == auth
        end
      end

      describe "#authorize_identity with valid identity" do
        it "should authorize a valid identity" do
          auth = subject.create_authorization_for(identity)
          auth.should be_persisted
          auth.identity_id.should eq identity.id
          auth.account_id.should eq identity.account_id
          auth.client_id.should eq subject.id
        end

        it "should retrieve a nullified authorization even deleted" do
          auth = Authorization.new
          auth.account_id = identity.account_id
          auth.identity_id = nil
          auth.client_id = subject.id
          auth.save!
          auth.delete

          created_auth = subject.create_authorization_for(identity)
          created_auth.id.should eq auth.id

          created_auth.deleted_at.should be_nil
          created_auth.identity_id.should eq identity.id
          created_auth.account_id.should eq identity.account_id
          created_auth.client_id.should eq subject.id
        end

        it "should not override identity_id" do
          auth = Authorization.new
          auth.account_id = identity.account_id
          auth.identity_id = identity.id
          auth.client_id = subject.id
          auth.save!

          new_id = Identity.create { |i| i.account_id = identity.account_id; i.nickname = 'Anakin' }
          subject.create_authorization_for(new_id).should be_nil
        end

        it "should override identity_id" do
          auth = Authorization.new
          auth.account_id = identity.account_id
          auth.identity_id = identity.id
          auth.client_id = subject.id
          auth.save!
          identity.authorizations.count.should eq 1

          new_id = Identity.create { |i| i.account_id = identity.account_id; i.nickname = 'Anakin'; i.identity_title = 'test' }
          new_auth = subject.create_authorization_for!(new_id)
          new_auth.identity_id.should eq new_id.id

          identity.authorizations.count.should eq 0

        end
      end
    end
  end

  context "Destroy client" do
    let(:account){create :account}
    subject{ create :client }

    it "should destroy authorizations" do
      another_client = create :client
      another_client.create_authorization_for account.identities.first
      subject.create_authorization_for account.identities.first
      Authorization.unscoped.count.should == 2
      subject.destroy
      Authorization.unscoped.count.should == 1
    end
  end

end

