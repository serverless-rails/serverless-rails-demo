class PublishWatchMailer < ApplicationMailer
  def notify(publish_watch_id, document_ids)
    @pw = PublishWatch.find(publish_watch_id)
    @watcher, @publisher = @pw.watcher, @pw.publisher
    @documents = Document.where(id: document_ids)

    mail(
      to: "#{@watcher.name} <#{@watcher.email}>",
      reply_to: "noreply@demo.serverless-rails.com",
      subject: "#{@publisher.name} has new/updated documents!"
    )
  end
end
