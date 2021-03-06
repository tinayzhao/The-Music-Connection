# frozen_string_literal: true

require 'rails_helper'

# Monkeypatch: see https://github.com/rails/rails/issues/34790
if RUBY_VERSION >= '2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # HACK: to avoid MonitorMixin double-initialize error:
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  else
    puts 'Monkeypatch for ActionController::TestResponse no longer needed'
  end
end

if AdminSettings.last.nil?
  a = AdminSettings.new
  a.attributes = {
    form_open: false,
    salt: 'salt',
    password_hash: BCrypt::Password.create('password'),
    last_updated: Time.at(1),
    email: 'placeholder@tmc.com',
    session_id: 'placeholder'
  }
  a.save
end

passed_session = {
  auth_token: AdminSettings.last.session_id
}

describe AdminController do
  describe ':verify_login' do
    context 'When not logged in as admin' do
      it 'should redirect when accessing welcome' do
        get :welcome
        expect(response).to redirect_to('/admin')
      end
      it 'should redirect when accessing update settings' do
        get :update_settings_post
        expect(response).to redirect_to('/admin')
      end
      it 'should redirect when accessing open form' do
        get :open_form
        expect(response).to redirect_to('/admin')
      end
      it 'should redirect when accessing close form' do
        get :close_form
        expect(response).to redirect_to('/admin')
      end
      it 'should redirect when accessing generate matches' do
        get :generate_matches
        expect(response).to redirect_to('/admin')
      end
      it 'should redirect when accessing reset_database' do
        get :reset_database
        expect(response).to redirect_to('/admin')
      end
    end
    context 'When logged in as admin' do
      it 'should redirect to welcome when accessing login' do
        get :home, nil, passed_session
        expect(response).to redirect_to('/admin/welcome')
      end
      it 'should allow access to welcome' do
        get :welcome, nil, passed_session
        expect(response).to have_http_status(200)
      end
      it 'should show warning if password is default' do
        a = AdminSettings.new
        a.attributes = {
          form_open: false,
          salt: 'salt',
          password_hash: BCrypt::Password.create('password'),
          last_updated: Time.at(1),
          email: 'placeholder@tmc.com',
          session_id: 'placeholder'
        }
        a.save
        get :welcome, nil, passed_session
        expect(flash[:password]).to be_present
      end
      it 'should not show warning if password is not default' do
        a = AdminSettings.new
        a.attributes = {
          form_open: false,
          salt: 'salt',
          password_hash: BCrypt::Password.create('high entropy password'),
          last_updated: Time.at(1),
          email: 'placeholder@tmc.com',
          session_id: 'placeholder'
        }
        a.save
        get :welcome, nil, passed_session
        expect(flash[:password]).to eq('')
      end
      it 'should allow access to update settings' do
        get :update_settings, nil, passed_session
        expect(response).to have_http_status(200)
      end
      it 'should allow open form' do
        get :open_form, nil, passed_session
        expect(response).to redirect_to('/admin/edit_forms')
        expect(AdminSettings.last.form_open).to eq(true)
      end
      it 'should allow close form' do
        get :close_form, nil, passed_session
        expect(response).to redirect_to('/admin/edit_forms')
        expect(AdminSettings.last.form_open).to eq(false)
      end
      it 'should allow generate matches with empty database' do
        get :generate_matches, nil, passed_session
        expect(response).to have_http_status(200)
      end
      it 'should allow generate matches' do
        create(:tutor)
        create(:tutor)
        create(:tutor)
        create(:teacher)
        create(:parent)
        get :generate_matches, nil, passed_session
        expect(response).to have_http_status(200)
      end
      it 'should allow reset database' do
        get :reset_database, nil, passed_session
        expect(response).to have_http_status(200)
      end
      it 'should allow confirm reset database' do
        create(:tutor)
        create(:teacher)
        create(:parent)
        create(:parent)
        post :confirm_reset_database, { reset_confirmation: 'Yes' }, passed_session
        expect(response).to redirect_to('/admin/welcome')
        expect(Teacher.first).to be_nil
        expect(Tutor.first).to be_nil
        expect(Parent.first).to be_nil
        expect(Match.first).to be_nil
      end
      it 'should allow denied reset database' do
        create(:tutor)
        create(:teacher)
        create(:parent)
        post :confirm_reset_database, { reset_confirmation: 'No' }, passed_session
        expect(response).to redirect_to('/admin/welcome')
        expect(Teacher.first).not_to be_nil
        expect(Tutor.first).not_to be_nil
        expect(Parent.first).not_to be_nil
      end
    end
  end
  describe '#login' do
    it 'should give auth token and redirect on success' do
      answer = passed_session[:auth_token]
      post :login, { password: 'password' }, {}
      expect(response).to redirect_to('/admin/welcome')
      expect(session[:auth_token]).to eq(answer)
    end
    it 'should not give auth token and redirect on failure' do
      post :login, { password: 'ddafdad' }, {}
      expect(session[:auth_token]).to eq('')
    end
  end
  describe '#logout' do
    it 'should clear auth token and redirect' do
      get :logout, {}, passed_session
      expect(response).to redirect_to('/admin')
      expect(session[:auth_token]).to eq('')
    end
  end
  describe '#update_settings_post' do
    it 'should update all settings' do
      new_params = {
        old_password: 'password',
        new_password: 'new_password',
        new_email: 'newemail@email.com'
      }
      post :update_settings_post, new_params, passed_session
      expect(response).to redirect_to('/admin/welcome')
      expect(flash[:notice]).to eq('Updated settings')
      expect(session[:auth_token]).to eq(AdminSettings.last.session_id)
      expect(AdminSettings.last.email).to eq(new_params[:new_email])
      # password cannot be directly compared
      get :logout, {}, passed_session
      post :login, { password: new_params[:new_password] }, {}
      expect(response).to redirect_to('/admin/welcome')
    end
    it 'should not update settings with bad password' do
      new_params = {
        old_password: 'AAAAAAAAAAAAAAA',
        new_password: 'even_newer_password',
        new_email: 'wrong@email.com'
      }
      post :update_settings_post, new_params, passed_session
      expect(response).to redirect_to('/admin/update_settings')
      expect(flash[:notice]).to eq('Incorrect password')
      expect(AdminSettings.last.email).not_to eq(new_params[:new_email])
      expect(AdminSettings.last.password_hash).not_to eq(new_params[:new_password])
    end
  end
end
