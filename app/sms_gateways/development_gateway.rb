class DevelopmentGateway < Idnet::Core::MobileGateway
  def send_message(number, message)
    ::Rails.logger.warn <<-WARN
      \e[0;31mDevelopment SMS stub adapter: \e[0;37m\e[0;1m
        Number: #{number}
        Message: #{message}
        WARN
  end
end
