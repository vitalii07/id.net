require 'spec_helper'
shared_examples_for "followable" do

  it "should include Followable" do
    Idnet::Core::Followable.should be_in subject.class.ancestors
  end

  describe "fields" do
    it {should have_many(:link_requests)}
    it {should have_many(:requested_links)}
  end

  let(:requester){ create :account }
  let(:receiver){ create :account }
  let(:requesting){ requester.identities.first }
  let(:receiving){ receiver.identities.first }
  let(:link) do
    IdentityLink.create do |obj|
      obj.requester = requesting
      obj.receiver = receiving
    end
  end

  it { should respond_to :follow! }
  it { should respond_to :unfollow! }
  it { should respond_to :block! }
  it { should respond_to :unblock! }
  it { should respond_to :accept! }
  it { should respond_to :mutual_accept! }
  it { should respond_to :mutual_accept_link_request! }
  it { should respond_to :accept_link_request! }
  it { should respond_to :block_link_request! }
  it { should respond_to :unblock_link_request! }

  describe "creating link" do

    it "should allow creating link request" do
      link = requesting.follow! receiving
      receiving.followers.should == [requesting.id]
      requesting.followees.should == [receiving.id]
      receiving.pending_requests.should == [requesting.id]
      link.requester.should eq requesting
      link.receiver.should eq receiving
      link.should be_pending
    end

    it "should add mutual if both pending" do
      link = requesting.follow! receiving
      link.should be_pending
      other_link = receiving.follow! requesting
      other_link.should be_mutual
      link.reload
      link.should be_mutual
    end

    it "should not be allowed on same account" do
      receiving = requester.identities.where(_id: {'ne' => requesting.id}).first
      lambda { requesting.follow! receiving }.should raise_error
    end

    it "should accept" do
      receiving.accept_link_request! link
      requesting.id.should be_in receiving.followers
      receiving.id.should be_in requesting.followees
    end

    it "should mutual accept" do
      receiving.mutual_accept_link_request! link

      receiving.id.should be_in requesting.friends
      requesting.id.should be_in receiving.friends

      requesting.id.should_not be_in receiving.followees
      requesting.id.should_not be_in receiving.followers

      receiving.id.should_not be_in requesting.followees
      receiving.id.should_not be_in requesting.followers
    end

    it "should mutual accept if already accepted in other side" do
      receiving.accept_link_request! link
      other_link = receiving.follow! requesting
      other_link.should be_mutual
      link.reload
      link.should be_mutual
      other_link.mirror.should eq link
      link.mirror.should eq other_link
    end

    it "should block" do
      receiving.block_link_request! link
      receiving.id.should_not be_in requesting.friends
      link.reload
      link.should be_blocked
      requesting.id.should_not be_in receiving.friends
    end

    it "should unblock" do
      receiving.block_link_request! link
      receiving.unblock_link_request! link
      link.should be_accepted
    end

    it "should remove from friend_request" do
      account = create :account
      other_account = create :account
      account.identities.last.destroy
      other_account.identities.last.destroy
      id1 = account.identities.first
      id2 = other_account.identities.first
      account.identities_to_follow_with(id2).should be_include id1
      id1.follow! id2
      account.reload
      account.identities_to_follow_with(id2).to_a.should_not be_include id1
    end

    it 'should force block' do
      receiving.force_block! requesting
      receiving.blocked.should include(requesting.id)
    end
  end
end

describe Identity do
  it_should_behave_like "followable"
end
