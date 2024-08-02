node('management-default') {
    stage('Pipeline Configuration') {
      final scmVars = checkout(scm)
      env.GIT_BRANCH = scmVars.GIT_BRANCH
      env.GIT_URL = scmVars.GIT_URL
      env.GIT_REVISION = scmVars.GIT_COMMIT
    
      // See https://stackoverflow.com/a/55500013/1935861
      env.GIT_REPO_NAME = env.GIT_URL.replaceFirst(/^.*\/([^\/]+?).git$/, '$1')
    }
}
