module KubeDeployTools
  # NOTE(jmodes): Bump patch
  VERSION_XYZ = '2.1.2'
  def self.version_xyz
    version_xyz = VERSION_XYZ
    prerelease_notation = '.dev'
    build_metadata_notation = ''
    build_metadata_notation += ENV.has_key?('GIT_BRANCH') ? '.' + ENV.fetch('GIT_BRANCH').sub('origin/', '') : ''
    build_metadata_notation += ENV.has_key?('BUILD_ID') ? '.' + ENV.fetch('BUILD_ID') : ''

    branch = ENV.fetch('GIT_BRANCH', '').sub('origin/', '')
    if branch == 'master' || branch.start_with?('release')
      # Jenkins master or release builds
      return version_xyz
    elsif ENV.has_key?('GIT_BRANCH') && ENV.has_key?('BUILD_ID')
      # Jenkins non-master builds
      version_xyz += prerelease_notation + build_metadata_notation
    else
      # non-Jenkins
      version_xyz += prerelease_notation
    end
  end
end
