require 'easy_extensions/spec_helper'

describe EasyErrorsController do
  render_views
  before :each do
    request.env['action_dispatch.exception'] = ActionController::RenderError.new
    allow_any_instance_of(EasyErrorsController).to receive(:check_if_login_required).and_return(false)
    allow(Rails.application.config).to receive(:consider_all_requests_local) { false }
  end

  around(:each) do |ex|
    begin # set $!
      raise request.env['action_dispatch.exception']
    rescue
      ex.run
    end
  end

  describe '#show' do

    it do
      get :show
      expect(response).to render_template 'easy_errors/internal_server_error'
    end

    context 'with param' do
      it do
        get :show, params: { error_message: true }
        expect(response).to render_template 'easy_errors/error_with_backtrace'
      end
    end

    context 'gem easy_support missing' do
      it 'renders custom template' do
        request.env['action_dispatch.original_path'] = '/easy_support/login'

        get :show
        expect(response).to render_template 'easy_errors/easy_support_not_found'
      end
    end

  end

  it 'download_error' do
    get :show
    filename = "#{response.code}-ActionView_Template_Error-#{Date.today}.html"
    expect(Rails.root.join('tmp/easy_errors', filename).exist?).to be_truthy
    post :download_error, params: { filename: filename }
    expect(response).to be_successful
  end

  it 'show api with param' do
    get :show, params: { format: :json, error_message: true }
    parsed_response = JSON.parse(response.body)
    expect(response).to be_server_error
    expect(parsed_response).to include('exception')
    expect(parsed_response).to include('traces')
  end

  it 'show api with param' do
    get :show, params: { format: :json }
    parsed_response = JSON.parse(response.body)
    expect(response).to be_server_error
    expect(parsed_response).to include('exception')
    expect(parsed_response).not_to include('traces')
  end

  it 'show xml with param' do
    get :show, params: { format: :xml, error_message: true }
    parsed_response = Hash.from_xml(response.body)['hash']
    expect(response).to be_server_error
    expect(parsed_response).to include('exception')
    expect(parsed_response).to include('traces')
  end

  it 'show xml with param' do
    get :show, params: { format: :xml }
    parsed_response = Hash.from_xml(response.body)['hash']
    expect(response).to be_server_error
    expect(parsed_response).to include('exception')
    expect(parsed_response).not_to include('traces')
  end

  it 'send email' do
    ActionMailer::Base.deliveries = []
    filename                      = '00-ActionView_Template_Error-2018-02-27.html'
    fixture                       = Rails.root.join('tmp/easy_errors', filename)
    begin
      File.write(fixture, 'something')

      expect {
        post :send_email, params: { filename: filename, message: "It doesn't work!!!+FIX IT!" }
      }.to change(ActionMailer::Base.deliveries, :size).by(1)
    ensure
      File.delete(fixture) if File.exists?(fixture)
    end
  end

  it 'send email with bad encoding' do
    ActionMailer::Base.deliveries = []
    filename                      = '00-ActionView_Template_Error-2018-02-27.html'
    fixture                       = Rails.root.join('tmp/easy_errors', filename)
    begin
      File.write(fixture, 'something')

      expect {
        post :send_email, params: { filename: filename, cache_key: "\xFF&", message: "error!" }
      }.to change(ActionMailer::Base.deliveries, :size).by(1)
    ensure
      File.delete(fixture) if File.exists?(fixture)
    end
  end



end
