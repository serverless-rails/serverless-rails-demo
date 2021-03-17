namespace :notify do
  task publish_watches: :environment do |t|
    PublishWatch.find_each do |pw|
      since = pw.last_notified_at || pw.created_at
      to_notify = pw.publisher.documents.where("updated_at > ?", since)
      if to_notify.any?
        print "Notifying #{pw.watcher.email} about #{to_notify.count} documents... "
        PublishWatchMailer.notify(pw.id, to_notify.map(&:id)).deliver_later
        pw.update(last_notified_at: Time.now)
        puts "DONE"
      end
    end
    CloudwatchMetricHandler.report_job_run(t.name)
  end
end
