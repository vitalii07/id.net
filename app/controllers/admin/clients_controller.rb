class Admin::ClientsController < Admin::BaseController
  before_filter :find_client, only: [:edit, :update, :destroy, :reject, :accept, :achievements]
  before_filter :normalize_identity_form_address, only: [:update]
  authorize_resource class: "Client"
  check_authorization
  # rescue_from Rack::OAuth2::Server::InvalidRequestError, with: :handle_rack_oauth2_server_errors

  def index
    options = params.slice(:client_id, :display_name, :state, :account_email, :studio_name, :is_released, :with_highscores, :with_cheats, :page, :per)
    @clients = Client.admin_search(options)
  rescue ::Elasticsearch::Transport::Transport::Error
     @clients = []
  end

  def pending
    options = params.slice(:display_name, :is_released, :page, :per)
    options[:state] = :pending
    @clients = Client.admin_search(options)
  end

  def accept
    respond_to do |wants|
      if @client.accept
        Client.__elasticsearch__.refresh_index!
        wants.json { render json: { message: 'Accepted' } }
        wants.html { redirect_to :back, notice: "#{@client.display_name} was accepted."}
      else
        message = @client.errors.full_messages.join '. '
        wants.json { render json: { message: message } }
        wants.html { redirect_to :back, alert: message }
      end
    end
  end

  def reject
    respond_to do |wants|
      if @client.reject
        Client.__elasticsearch__.refresh_index!
        wants.json { render json: { message: 'Rejected' } }
        wants.html { redirect_to :back, notice: "#{@client.display_name} was rejected."}
      else
        message = @client.errors.full_messages.join '. '
        wants.json { render json: { message: message } }
        wants.html { redirect_to :back, alert: message }
      end
    end
  end

  def edit
  end

  def update
    @client.update_attributes(params[:client])#, as: :admin)
    if @client.save
      redirect_to admin_clients_path, notice: 'Client was successfully updated.'
    else
      render action: "edit"
    end
  end

  def new
    @client = Client.new(status: :accepted)#, as: :admin)
  end

  def create
    @client = Client.new(params[:client])#, as: :admin)
    if @client.save
      redirect_to admin_clients_path, notice: 'Client was successfully created.'
    else
      render action: :new and return
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path
  end

  def achievements
    if params.include?(:achievement)
      achievement_params = %w[appid achievement description achievementkey difficulty secret icon]
      @achievement = Achievement.new(params.select { |key,_| achievement_params.include? key })
      if @achievement.save
        flash[:notice] = "Achievement saved"
        redirect_to action: :achievements and return
      else
        flash[:error] = "All achievement fields are required"
      end
    end
    @achievements = Achievement.where(appid: @client.id)
    render :achievements
  end

  def achievement_delete
    if params[:key]
      @achievement = Achievement.where(achievementkey: params[:key])
      @achievement.destroy
      flash[:notice] = "Achievement removed"
      redirect_to action: :achievements and return
    end
  end

  private

  def handle_rack_oauth2_server_errors(e)
    redirect_to({action: "new"}, notice: 'Redirect URL must be absolute URL and should not be empty!')
  end

  def find_client
    @client = Client.find(params[:id])
  end
end
