application_name = "serverless-rails-demo"
application_host = "serverless-rails-demo.lol"

telegram_channel_id = "-571174084"

maintenance_mode = {
  production = false
}

cidr_prefix = {
  production = "10.50"
}

ssh_ips = {
  production = ["0.0.0.0/0"]
}

service_size = {
  production = {
    web = {
      cpu    = 1024
      memory = 2048
    }
    worker = {
      cpu    = 512
      memory = 1024
    }
    cable = {
      cpu    = 256
      memory = 512
    }
    job = {
      cpu    = 512
      memory = 1024
    }
  }
}

service_count = {
  production = {
    web = {
      desired = 1
      min     = 1
      max     = 5
    }
    worker = {
      desired = 1
      min     = 1
      max     = 5
    }
    cable = {
      desired = 1
      min     = 1
      max     = 5
    }
  }
}
