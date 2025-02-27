class BaseMailer < ActionMailer::Base
  include ERB::Util
  include ActionView::Helpers::TextHelper
  include EmailHelper
  include LocalesHelper

  helper :email
  helper :formatted_date

  NOTIFICATIONS_EMAIL_ADDRESS = ENV.fetch('NOTIFICATIONS_EMAIL_ADDRESS', "notifications@#{ENV['SMTP_DOMAIN']}")
  default :from => "\"#{AppConfig.theme[:site_name]}\" <#{NOTIFICATIONS_EMAIL_ADDRESS}>"
  before_action :utm_hash

  protected
  def utm_hash
    @utm_hash = { utm_medium: 'email', utm_campaign: action_name }
  end

  def from_user_via_loomio(user)
    if user.present?
      "\"#{I18n.t('base_mailer.via_loomio', name: user.name, site_name: AppConfig.theme[:site_name])}\" <#{NOTIFICATIONS_EMAIL_ADDRESS}>"
    else
      "\"#{AppConfig.theme[:site_name]}\" <#{NOTIFICATIONS_EMAIL_ADDRESS}>"
    end
  end

  def send_single_mail(locale: , to:, subject_key:, subject_params: {}, subject_prefix: '', subject_is_title: false, **options)
    return if NoSpam::SPAM_REGEX.match?(to)
    return if NOTIFICATIONS_EMAIL_ADDRESS == to
    return if User.has_spam_complaints.where(email: to).exists?

    I18n.with_locale(first_supported_locale(locale)) do
      if subject_is_title
        subject = subject_prefix + subject_params[:title]
      else
        subject = subject_prefix + I18n.t(subject_key, **subject_params)
      end
      mail options.merge(to: to, subject: subject )
    end
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
    raise "SMTP error to: '#{to}' from: '#{options[:from]}' action: #{action_name} mailer: #{mailer_name} error: #{e}"
  end
end
