case Rails.env.to_sym
when :development
  ActionMailer::Base.delivery_method = :letter_opener_web
when :production
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    user_name: 'apikey',
    password: ENV["SENDGRID_API_KEY"],
    domain: 'em3837.demo.serverless-rails.com',
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }
when :test
  ActionMailer::Base.delivery_method = :test
end
