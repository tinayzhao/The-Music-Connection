class WelcomeController < ApplicationController
  def index
    a = AdminSettings.last
    if a.nil?
      session[:form_open] = true
      return
    end
    session[:form_open] = a.form_open
  end
end
