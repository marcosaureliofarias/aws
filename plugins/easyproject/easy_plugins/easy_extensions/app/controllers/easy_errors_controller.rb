require 'digest/md5'

class EasyErrorsController < ApplicationController

  accept_anonymous_access :send_email, :download_error, :show

  skip_before_action :verify_authenticity_token, only: [:send_email, :download_error]

  accept_api_auth :show

  SUPPORT_EMAIL = 'support@easysoftware.com'
  ERRORS_FOLDER = Rails.root.join('tmp/easy_errors')

  def show
    exception          = request.env['action_dispatch.exception']
    original_path      = request.env['action_dispatch.original_path'].to_s
    @cache_key         = Digest::MD5.hexdigest("#{original_path}-#{exception}".gsub(/for #<.+>/, ''))
    backtrace_cleaner  = request.get_header("action_dispatch.backtrace_cleaner")
    @wrapper_exception = ActionDispatch::ExceptionWrapper.new(backtrace_cleaner, exception)
    @debug_view        = ActionDispatch::DebugExceptions::DebugView.new
    @exception         = ActionView::Template::Error.new(@debug_view)
    @traces            = @wrapper_exception.traces
    @status_code       = @wrapper_exception.status_code
    @request           = request
    @response          = response

    if original_path.include?('/easy_support/login')
      status_response = 'easy_support_not_found'
    else
      status_response = ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.name]
    end

    if (source_to_show = @traces['Application Trace'].first)
      @show_source_idx = source_to_show[:id]
    end

    @source_extracts = @wrapper_exception.source_extracts
    @redmine_info    = redmine_info

    if [:html, :pdf, :xlsx].include?(request.format.to_sym)
      if show_debug
        render template: 'easy_errors/error_with_backtrace', status: @status_code, layout: 'rescue'
      else
        Dir.mkdir(ERRORS_FOLDER) unless ERRORS_FOLDER.directory?
        @filename = Attachment.sanitize_filename("#{@status_code}-#{@exception.class.to_s}-#{Date.today}.html")
        File.open(ERRORS_FOLDER.join(@filename), "w") do |file|
          file.write(render_to_string template: 'easy_errors/error_with_backtrace', status: @status_code, layout: 'rescue', formats: [:html])
        end

        if lookup_context.template_exists?(status_response, 'easy_errors')
          render template: 'easy_errors/' + status_response.to_s, status: @status_code, layout: 'errors'
        else
          render template: 'easy_errors/internal_server_error', layout: 'errors'
        end
      end
    else
      render_for_api_request(request.format, @wrapper_exception)
    end
  end

  def send_email
    email, message = params[:email].presence, params[:message]
    email_cache_key = Digest::MD5.hexdigest("#{params[:cache_key]}-#{message}")
    basename       = Pathname(params[:filename]).basename
    filename       = ERRORS_FOLDER.join(basename)

    post_send_message = l('internal_server_error.notice_error_report_has_already_been_sent')
    Rails.cache.fetch(email_cache_key, expires_in: 1.day) do
      # works if cache with the same key expires or is absent
      # so send a message per day
      post_send_message = l('internal_server_error.notice_error_report_send')
      if File.exist?(filename)
        email ||= SUPPORT_EMAIL
        EasyMailer.internal_error(email, message, filename).deliver
      end
      true
    end
    flash[:notice] = post_send_message
    redirect_back_or_default home_url
  end

  def download_error
    return if params[:filename].blank?
    basename = Pathname(params[:filename]).basename
    filename = ERRORS_FOLDER.join(basename)
    send_file(filename, filename: 'internal_error.html', type: 'text/html; charset=utf-8') if filename.exist?
  end

  private

  def redmine_info
    redmine_info                        = {}
    redmine_info['Redmine environment'] = [
        ['Redmine version', Redmine::VERSION],
        ['Full version', EasyExtensions.full_version],
        ['Platform version', EasyExtensions.platform_version],
        ['Last commit SHA', shellout('git rev-parse HEAD')],
        ['Ruby version', "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"],
        ['Rails version', Rails::VERSION::STRING],
        ['Environment', Rails.env],
        ['Database adapter', ActiveRecord::Base.connection.adapter_name],
        ['Rails root', Rails.root.to_s],
        ['Gem root', Gem.dir],
        ['Hostname', shellout('hostname')]
    ].map { |info| "  %-30s %s" % info }

    redmine_info['SCM'] = []

    Redmine::Scm::Base.all.each do |scm|
      scm_class = "Repository::#{scm}".constantize
      if scm_class.scm_available
        redmine_info['SCM'] << "  %-30s %s\n" % [scm, scm_class.scm_version_string]
      end
    end

    redmine_info['Redmine Plugins'] = []
    plugins                         = Redmine::Plugin.all
    if plugins.any?
      redmine_info['Redmine Plugins'] += Redmine::Plugin.all.map { |plugin| "  %-30s %s" % [plugin.id, plugin.version] }
    else
      redmine_info['Redmine Plugins'] << "  no plugins installed"
    end

    redmine_info['Request details'] = [
        ['Params', request.parameters.to_hash],
        ['URL', request.original_url],
        ['Remote IP', request.remote_ip]
    ].map { |info| "  %-30s %s" % info }

    redmine_info
  end

  def shellout(command)
    EasyUtils::ShellUtils.shellout(command) { |io| io.read }.to_s.strip
  rescue EasyUtils::ShellUtils::CommandFailed
    "?"
  end

  def show_debug
    Rails.application.config.consider_all_requests_local || params[:error_message].present?
  end

  def render_for_api_request(content_type, wrapper)
    body          = {
        status:    wrapper.status_code,
        error:     Rack::Utils::HTTP_STATUS_CODES.fetch(
            wrapper.status_code,
            Rack::Utils::HTTP_STATUS_CODES[500]
        ),
        exception: wrapper.exception.inspect
    }
    body[:traces] = wrapper.traces if show_debug
    to_format     = "to_#{content_type.to_sym}"

    if body.respond_to?(to_format)
      formatted_body = body.public_send(to_format)
      format         = content_type
    else
      formatted_body = body.to_json
      format         = Mime[:json]
    end

    render(body: formatted_body, status: wrapper.status_code, content_type: format)
  end

end
