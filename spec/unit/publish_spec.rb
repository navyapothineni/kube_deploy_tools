require 'set'

require 'kube_deploy_tools/publish'

MANIFEST_FILE='spec/resources/deploy.yaml'
PROJECT='my-project'

describe KubeDeployTools::Publish do
  let(:logger) { KubeDeployTools::FormattedLogger.build }

  it 'publishes artifacts according to deploy.yaml' do
    KubeDeployTools::Logger.logger = logger
    KubeDeployTools::PROJECT = PROJECT

    # Mock artifact upload
    uploads = Set.new
    allow_any_instance_of(Artifactory::Resource::Artifact).to receive(:upload) do |artifact, repo, path|
      # Expect to upload to kubernetes-snapshots-local/<project>
      expect(repo).to eq(KubeDeployTools::ARTIFACTORY_REPO)
      expect(path).to start_with(PROJECT)

      # add only the basenames of the files to the set as the BUILD_ID
      # will vary on each build
      uploads.add(File.basename(path))
    end

    expected_uploads = [
      'manifests_colo-service-prod_default.tar.gz',
      'manifests_colo-service-staging_default.tar.gz',
      'manifests_local_default.tar.gz',
      'manifests_us-east-1-prod_default.tar.gz',
      'manifests_us-east-1-staging_default.tar.gz',
      'manifests_ingestion-prod_default.tar.gz',
      'manifests_pippio-production_default.tar.gz',
      'manifests_platforms-prod_default.tar.gz',
      'manifests_filtered-artifact_default.tar.gz',
    ]

    Dir.mktmpdir do |dir|
      expected_uploads.each do |f|
        FileUtils.touch File.join(dir, f)
      end

      KubeDeployTools::Publish.new(
        manifest: MANIFEST_FILE,
        output_dir: dir,
      ).publish
    end

    all_uploads = expected_uploads
    expect(uploads).to contain_exactly(*all_uploads)
  end
end

