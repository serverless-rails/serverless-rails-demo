workers [1, `grep -c processor /proc/cpuinfo`.to_i].max
threads 20, 20
environment ENV.fetch("RAILS_ENV")
port 8080
preload_app!
rackup DefaultRackup
stdout_redirect("/dev/stdout", "/dev/stderr", true)
