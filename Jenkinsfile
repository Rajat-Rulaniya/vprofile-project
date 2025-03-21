def COLOR_MAP = [
    'SUCCESS': 'good', 
    'FAILURE': 'danger',
]

pipeline {
    agent any;

    tools {
        maven "maven"
        jdk "OracleJDK17"
    }

    environment {
        NEXUS_CREDENTIALS = credentials('NEXUS_CREDENTIALS')
        NEXUS_USER = "${NEXUS_CREDENTIALS_USR}"
        NEXUS_PASS = "${NEXUS_CREDENTIALS_PSW}"
        RELEASE_REPO = 'vprofile-release'
        CENTRAL_REPO = 'vprofile-central'
        NEXUS_GRP_REPO = 'vprofile-group'
        SONARSERVER = 'sonarserver'
        SONARSCANNER = 'sonarscanner'
        AWS_CRED = 'awscreds-jenkins'
        AWS_REGION = 'us-east-1'
        S3_BUCKET = 'rajat-blog-app-artifacts'
        EB_APPLICATION = 'vproapp'
        EB_ENV = 'Vproapp-staging-env'
    }

    stages {
        stage("Build") {
            steps {
                sh "mvn -s settings.xml -DskipTests install"

                sh "mv ./target/vprofile-v2.war ./target/vprofile-Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP}.war"
            }

            post {
                success {
                    echo "Now Archiving."
                    archiveArtifacts artifacts: '**/*.war'
                }
            }
        }

        stage("Test") {
            steps {
                sh "mvn -s settings.xml test"
            }
        }

        stage("Checkstyle Analysis") {
            steps {
                sh 'mvn -s settings.xml checkstyle:checkstyle'
            }
        }    

        stage("Sonar Analysis") {
            environment {
                scannerHome = tool "${SONARSCANNER}"
            }
            steps {
               withSonarQubeEnv("${SONARSERVER}") {
                   sh '''
                        ${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=vprofile \
                        -Dsonar.projectName=vproapp-cicd \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src/ \
                        -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                        -Dsonar.junit.reportsPath=target/surefire-reports/ \
                        -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                        -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
                   '''
              }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: "HOURS") {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Save build version") {
            steps {
                script {
                    env.buildVersion = "Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP}"

                    sh 'echo "${buildVersion}" > /var/lib/jenkins/vprofileBuildVersion.txt'

                    sh 'echo "BUILD VERSION SAVED!"'
                }
            }
        }

        stage("UploadArtifact to S3"){
            steps{
                withAWS(region: 'us-east-1', credentials: 'awscreds-jenkins') {
                    s3Upload(
                        file:"./target/vprofile-${env.buildVersion}.war",
                        bucket: S3_BUCKET,
                        path: "java-app/vprofile-${env.buildVersion}.war"
                    )
                }
            }
        }

        stage("Update Staging Beanstalk Environment") {
            steps {
                script {
                    withAWS(region: AWS_REGION, credentials: AWS_CRED) {
                        sh """
                            aws elasticbeanstalk create-application-version \
                            --application-name ${EB_APPLICATION} \
                            --version-label ${buildVersion} \
                            --source-bundle S3Bucket="${S3_BUCKET}",S3Key="java-app/vprofile-${env.buildVersion}.war"
                        """

                        sh """
                            aws elasticbeanstalk update-environment \
                            --application-name ${EB_APPLICATION} \
                            --environment-name ${EB_ENV} \
                            --version-label ${buildVersion}
                        """
                    }
                }                
            }
        }
    }

    post {
        success {
            echo 'Slack Notification....'
            slackSend channel: '#jenkinscicd', 
                color: COLOR_MAP[currentBuild.currentResult], 
                message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build-Version: Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP} \n\n New Artifact Uploaded to Staging Beanstalk Environment! ✅\n\n More info at: ${env.BUILD_URL}"
        }
    }
}