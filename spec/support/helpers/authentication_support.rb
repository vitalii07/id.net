module AuthenticationSupport
  def log_in account
    visit new_account_session_path
    fill_in 'account_email', with: account.email
    fill_in 'account_password', with: account.password
    click_button 'Login'
  end
end

