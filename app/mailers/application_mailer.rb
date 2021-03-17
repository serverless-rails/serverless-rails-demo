class ApplicationMailer < ActionMailer::Base
  default from: 'hello@serverless-rails-demo.lol'
  layout 'mailer'
end
