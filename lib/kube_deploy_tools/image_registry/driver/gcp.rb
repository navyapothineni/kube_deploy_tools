require_relative 'base'
require 'tmpdir'

module KubeDeployTools
  class ImageRegistry::Driver::Gcp < ImageRegistry::Driver::Base
    GCR_DOCKER_CONFIG = <<-EOH
{
  "credHelpers": {
    "us.gcr.io": "gcloud",
    "staging-k8s.gcr.io": "gcloud",
    "asia.gcr.io": "gcloud",
    "gcr.io": "gcloud",
    "marketplace.gcr.io": "gcloud",
    "eu.gcr.io": "gcloud"
  }
}
EOH

    def initialize(registry:)
      super

      @gcloud_config_dir = Dir.mktmpdir
      @activated = false

      # Always prepare a fake Docker config for pushing using the
      # credential helper.
      ENV['DOCKER_CONFIG'] = @gcloud_config_dir
      File.open(File.join(@gcloud_config_dir, 'config.json'), 'w') do |f|
        f.write(GCR_DOCKER_CONFIG)
      end
    end

    def authorize
      # Always prefer and activate a service account under a protected namespace if present.
      if @activated
        return
      elsif ENV.member?('GOOGLE_APPLICATION_CREDENTIALS')
        raise "Failed to activate service account" unless activate_service_account()[2].success?
        @activated = true
      else
        user = current_user
        if ! user.empty?
          Logger.info "Skipping Google activation, using current user #{user}"
          @activated = true
        else
          raise 'No usable Google authorization for pushing images; specify GOOGLE_APPLICATION_CREDENTIALS?'
        end
      end
    end

    # Delete temporary config dir for gcloud authentication
    def unauthorize
      Logger.info "Cleaning up authorization for #{@registry.prefix}"
      FileUtils.rm_rf(@gcloud_config_dir) unless @gcloud_config_dir.nil?
    end

    def delete_image(image_id, dryrun)
      # Need the id path to be [HOSTNAME]/[PROJECT-ID]/[IMAGE]
      if dryrun
        Logger.info("DRYRUN: delete gcp image #{image_id}")
      else
        # --quiet removes the user-input component
        _, err, status = Shellrunner.run_call('gcloud', 'container', 'images', 'delete', '--quiet', image_id, '--force-delete-tags')
        if !status.success?
          # gcloud gives a deceptive error msg when the image does not exist
          if err.include?('is not a valid name')
            Logger.warn("Image #{image_id} does not exist, skipping")
          else
            raise "gcloud image deletion failed!"
          end
        end
      end
    end

    private
    # activate gcloud with svc json keys on Jenkins
    def activate_service_account
      keypath = ENV.fetch('GOOGLE_APPLICATION_CREDENTIALS')
      Logger.info("Authorizing using temp directory #{@gcloud_config_dir} and credentials #{keypath}")

      ENV['XDG_CONFIG_HOME'] = @gcloud_config_dir
      ENV['CLOUDSDK_CONFIG']= File.join(@gcloud_config_dir, 'gcloud')

      Shellrunner.run_call('gcloud', 'auth', 'activate-service-account', '--key-file', keypath)
    end

    def current_user
      Shellrunner.run_call('gcloud', 'config', 'list', 'account', '--format', "value(core.account)")[0]
    end
  end
end
