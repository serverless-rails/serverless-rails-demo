class CloudwatchMetricHandler
  def self.report_job_run(name, status: :success)
    payload = {
      namespace: "Jobs",
      metric_data: [
        {
          metric_name: "JobRun#{status == :success ? "Success" : "Failed"}",
          dimensions: [
            {
              name: Rails.env.to_s,
              value: name.split(/[:\s]/).map(&:titleize).join("").delete(" ")
            }
          ],
          timestamp: Time.now,
          value: 1.0,
          unit: "Count"
        }
      ]
    }

    if Rails.env.production?
      begin
        cloudwatch.put_metric_data(payload)
      rescue
        Rails.logger.error("Unable to report Cloudwatch metric: #{$!.message}")
      end
    else
      Rails.logger.error("\n\nCLOUDWATCH PAYLOAD DEBUG: #{payload.inspect}\n\n")
    end
  end

  class << self
    protected

    def cloudwatch
      Aws::CloudWatch::Client.new(
        region: "ca-central-1",
        credentials: Aws::Credentials.new(
          ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"]
        )
      )
    end
  end
end
