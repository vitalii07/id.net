class FeedsController < ApplicationController
  before_filter :authenticate_account!
  before_filter :scope_resources, only: [:index, :show]
  helper_method :current_user_can_manage?

  def current_user_can_manage? resource
    #TODO: move to CanCan
    (resource.try(:parent) || resource).author.account == current_account
  end

  def show
    @feed = Idnet::Core::Activity.find params[:id]
  end

  def index
    # handle invalid urls: they all go here because of default route
    if params[:scope_id].present? && @identity.nil?
      render(status: 404, file: "public/404_refresh.html", layout: false)
      return
    end

    if @identity
      @feeds = @identity.activities.active.with_children.page(params[:page]).per(params[:per_page])
    else
      identity_ids = current_account.identities.pluck(:id)
      @feeds = Idnet::Core::Activity.where(:recipient_id.in => identity_ids).with_children.active.page params[:page]
    end

    @feeds = @feeds.not_spam

    # Mark feeds as read before rendering views
    @feeds.where(state: 'pending').update_all(state: 'read')
  end

  def create
    @feed = Idnet::Core::Feed.new params[:feed]
    @feed.mark_as_not_spam

    unless @feed.save
      flash[:error] = render_to_string(:create_error, layout: false).html_safe
    end

    redirect_to :back
  end

  def comment
    parent = Idnet::Core::Activity.find(params[:id])
    parent.comment!(from: params[:feed][:author_id], message: params[:feed][:message]) if parent.commentable?
    redirect_to :back
  end

  def trash
    feed = Idnet::Core::Activity.find(params[:id])
    feed.trash!
    redirect_to :back
  end

  def delete_comment
    feed = Idnet::Core::Activity.find(params[:id])
    if feed.commentable?
      comment = feed.comments.find(params[:comment_id])
      feed.delete_comment comment if current_user_can_manage? comment
    end
    redirect_to :back
  end
end
