class AdsManagementTracker
  SHARING_PERCENTAGE = 85
  attr_reader :wpn_user_id, :client, :connection

  def initialize(wpn_user_id, client)
    @wpn_user_id, @client = wpn_user_id, client
    @connection = Faraday.new(Idnet.config.ads.api_url, ssl: { verify: false })
  end

  # https://main.trafficflux.com/webservices/API_KEY/contentowner/WPN_USER_ID/addtracker.json
  def create(sharing_percent = SHARING_PERCENTAGE)
    url = File.join(Idnet.config.ads.api_url,"/webservices/#{Idnet.config.ads.api_key}/contentowner/#{wpn_user_id}/addtracker.json")
    timestamp = Time.now.utc.to_i
    response = connection.post do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      # req.body = tracker_body(url, timestamp, {sharing_percent: sharing_percent}).to_json
      req.params = tracker_body(url, timestamp, {sharing_percent: sharing_percent})
    end
    puts [response.body, response.status, response.headers].inspect
    response.status == 200
  end

  # https://main.trafficflux.com/webservices/API_KEY/contentowner/WPN_USER_ID/updatetracker.json
  def update(sharing_percent = SHARING_PERCENTAGE)
    url = File.join(Idnet.config.ads.api_url,"/webservices/#{Idnet.config.ads.api_key}/contentowner/#{wpn_user_id}/updatetracker.json")
    timestamp = Time.now.to_i
    response = connection.post do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      # req.body = tracker_body(url, timestamp, {sharing_percent: sharing_percent}).to_json
      req.params = tracker_body(url, timestamp, {sharing_percent: sharing_percent})
    end
    response.status == 200
  end

  # https://main.trafficflux.com/webservices/API_KEY/contentowner/WPN_USER_ID/disabletracker.json
  def disable
    url = File.join(Idnet.config.ads.api_url,"/webservices/#{Idnet.config.ads.api_key}/contentowner/#{wpn_user_id}/disabletracker.json")
    timestamp = Time.now.to_i
    response = connection.post do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      # req.body = tracker_body(timestamp, url).to_json
      req.params = tracker_body(timestamp, url)
    end
    response.status == 200
  end

  protected

  def tracker_body(url, timestamp, options = {})
    {
      security_token: token(url, timestamp),
      timestamp: timestamp,
      tracker: {
        tracker_name: tracker_name
      }.merge(options)
    }
  end

  def token(uri, timestamp)
    password = Idnet.config.ads.api_password
    Digest::SHA1.hexdigest([timestamp, uri, password].join)
  end

  def tracker_name
    "idnet-#{client.id}"
  end
end
