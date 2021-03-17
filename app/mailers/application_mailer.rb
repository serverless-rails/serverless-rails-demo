class ApplicationMailer < ActionMailer::Base
  default from: 'hello@demo.serverless-rails.com'
  layout 'mailer'
end
