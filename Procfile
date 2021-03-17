web: bundle exec rails server -p 5500
worker: bundle exec sidekiq
webpack: bundle exec bin/webpack-dev-server
anycable: bundle exec anycable --server-command "anycable-go --port=8080"
notifications: while true; do echo "Sending Notifications..."; bundle exec rake notify:publish_watches; sleep 60; done
