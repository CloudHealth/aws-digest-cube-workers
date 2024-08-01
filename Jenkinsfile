#!/usr/bin/env groovy
@Library('cht-jenkins-pipeline') _

properties([
  [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '15']]
]);


if (env.BRANCH_NAME == 'master') {
  properties([pipelineTriggers([cron('H H(8-10) * * 4')]),
    [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '15']]
  ]);
}

def hooks = [pushBCJfrog: true]

node('management-testing') {
  def DB_USER = 'cloudpercept_tes'
  def DB_PSWD = 'Cl0udPercept123'
  def ecr_registry = '146708650527.dkr.ecr.us-east-1.amazonaws.com'
  def BC_ARTIFACTORY = 'tis-cost-docker-dev-local.usw1.packages.broadcom.com'
  def BC_REGISTRY_PROD = 'tis-cost-docker-prod-local.usw1.packages.broadcom.com'
  def OPEN_MYSQL_PORT
  def HOST_IP

  final scmVars = checkout(scm)
  env.GIT_BRANCH = scmVars.GIT_BRANCH
  env.GIT_URL = scmVars.GIT_URL

  cleanWs()
  stgSetup()

  stage('checkout submodules'){

      checkout([
          $class: 'GitSCM',
          branches: scm.branches,
          doGenerateSubmoduleConfigurations: true,
          extensions: scm.extensions + [[$class: 'SubmoduleOption', parentCredentials: true]],
          userRemoteConfigs: scm.userRemoteConfigs
      ])
                
  }
  
  timestamps {
    withCredentials([sshUserPrivateKey(credentialsId: 'github', keyFileVariable: 'GIT_SSH_KEY'),
                      usernamePassword(credentialsId: 'BC_ARTIFACTORY',
                                                  usernameVariable: 'BC_ARTIFACTORY_USER',
                                                  passwordVariable: 'BC_ARTIFACTORY_PASS')]) {
      
      sh 'cp $GIT_SSH_KEY ssh_key'
      sh "echo $BC_ARTIFACTORY_PASS | docker login -u $BC_ARTIFACTORY_USER --password-stdin $BC_ARTIFACTORY"
      parallel aws_digest_cube_workers_gke: {
        stage('Build GKE aws-digest-cube-workers') {
          // check whether the sub-modules are properly checked-out
          sh 'echo "Contents of sub-module core subdirectory:"; ls -la core/'

          aws_digest_cube_workers_mri_gke_image = docker.build("${BC_ARTIFACTORY}/pr/cht/services/cp-workers/aws-digest-cube-workers_mri:${gitCommit()}", "--build-arg RELEASE_VERSION=${gitCommit().take(7)} -f docker/aws-digest-cube-workers.dockerfile .")
        }
      }
      sh 'rm ssh_key'
    }

    sh "rm GemfileMriAwsDigest"
    dir('core') {
      OPEN_MYSQL_PORT = findOpenPort(3000,5000)
      HOST_IP = findIp()
      echo "PORT: " + OPEN_MYSQL_PORT
      echo "HOST IP: " + HOST_IP
      sh "modify_ports.rb ${OPEN_MYSQL_PORT} ${HOST_IP}"
      echo "Rewrote config/database.yml"
    }
   
    try {
      sh "docker run -d --name=mysql-cpworkers-25-3-${OPEN_MYSQL_PORT} -p ${OPEN_MYSQL_PORT}:3306 297322132092.dkr.ecr.us-east-1.amazonaws.com/cht/test_db_base/mysql8:latest --default-authentication-plugin=mysql_native_password --sql-mode=NO_ENGINE_SUBSTITUTION,STRICT_ALL_TABLES --character-set-server=utf8 --collation-server=utf8_unicode_ci"
      workers_img = aws_digest_cube_workers_mri_gke_image
      workers_img.inside('''
          -e JENKINS=1 \
          -e RAILS_ENV=test \
          -e IP_ADDRESS=${HOST_IP} \
          -e DB_USER=${DB_USER} \
          -e DB_PASSWORD=${DB_PSWD} \
          -e MYSQL_PORT=${OPEN_MYSQL_PORT}
      ''') {
        stage('Populate DB_2.5.5-3.0') {
          sh "bash docker/test_mysql_connection.sh ${HOST_IP} ${OPEN_MYSQL_PORT}"
          sh 'mv GemfileMri Gemfile && mv GemfileMri.lock Gemfile.lock'
          sh 'bundle exec rake db:schema:load db:seed'
          sh 'bundle exec rake analyses:refresh'
        }
        try {
          stage('Test_2.5.5-3.0') {
            try {
              sh "bundle exec rspec --format documentation --format RspecJunitFormatter --out cpworkers_rspec_25-3_${BUILD_NUMBER}.xml"
            } finally {
                junit(testResults: "cpworkers_rspec_25-3_${BUILD_NUMBER}.xml", skipPublishingChecks: true)
                publishHTML (target: [
                  allowMissing: false,
                  alwaysLinkToLastBuild: false,
                  keepAll: true,
                  reportDir: 'coverage',
                  reportFiles: 'index.html',
                  reportName: "SimpleCov Report Ruby 2.5.5"
                ])
                archiveArtifacts('coverage/.resultset.json')
                archiveArtifacts("cpworkers_rspec_25-3_${BUILD_NUMBER}.xml")
            }
            sh "exit 0"
            currentBuild.result = 'SUCCESS'
          }
        } catch (Exception e) {
          sh "exit 0"
          currentBuild.result = 'FAILURE'
        }
        codeCoverageRspec()
      }
    } finally {
      sh "docker stop mysql-cpworkers-25-3-${OPEN_MYSQL_PORT} && docker rm -f mysql-cpworkers-25-3-${OPEN_MYSQL_PORT}"
    }

    if(env.BRANCH_NAME.contains('master')) {
      stage('Push Images') {
        // jruby92_image.push(gitCommit())

        // jruby_next_image.push(gitCommit())

        // mri_255_image.push(gitCommit())
        aws_digest_cube_workers_mri_gke_image.push(gitCommit())
      }
    } else{
      stage('Push staging Images') {
        // jruby92_staging_image.push(gitCommit())

        // jruby_next_staging_image.push(gitCommit())

        // mri_255_staging_image.push(gitCommit())

        aws_digest_cube_workers_mri_gke_image.push(gitCommit())

      }
    }
      stage('Push to BC Prod-local') {
        withCredentials([sshUserPrivateKey(credentialsId: 'github', keyFileVariable: 'GIT_SSH_KEY'),
                         usernamePassword(credentialsId: 'BC_ARTIFACTORY',
                                 usernameVariable: 'BC_ARTIFACTORY_USER',
                                 passwordVariable: 'BC_ARTIFACTORY_PASS')]){

          if ( env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main' ) {
            sh "echo $BC_ARTIFACTORY_PASS | docker login -u $BC_ARTIFACTORY_USER --password-stdin $BC_REGISTRY_PROD"
            sh "docker image tag ${BC_ARTIFACTORY}/pr/cht/services/cp-workers/aws-digest-cube-workers-mri:${gitCommit()} ${BC_REGISTRY_PROD}/master/cht/services/cp-workers/aws-digest-cube-workers-mri:${gitCommit()}"
            sh "docker push ${BC_REGISTRY_PROD}/master/cht/services/cp-workers/aws-digest-cube-workers-mri:${gitCommit()}"
          }

        }
      }
      stage('Helm package publish Class') {
        stgHelmPublishChartClassicBC(hooks)
      }
    }
    wavefrontMetrics("cp-workers")
}
