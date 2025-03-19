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
    }

    stages {
        stage("Build") {
            steps {
                sh "mvn -s settings.xml -DskipTests install"
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

        stage("UploadArtifact"){
            steps{
                nexusArtifactUploader(
                  nexusVersion: 'nexus3',
                  protocol: 'http',
                  nexusUrl: "${NEXUS_URL}",
                  groupId: 'ARTIFACTS', // The folder in which our artifacts will be uploaded after build
                  version: "Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP}", // the folder where artifact after each build will be uploaded.
                  repository: "${RELEASE_REPO}",
                  credentialsId: "NEXUS_CREDENTIALS",
                  artifacts: [
                    [artifactId: 'java-app', // sub-group
                     classifier: '',
                     file: 'target/vprofile-v2.war',
                     type: 'war']
                  ]
                )
            }
        }

        stage("Save build version") {
            steps {
                script {
                    sh 'echo "Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP}" > /var/lib/jenkins/latestBuildVprofile.txt'

                    sh 'echo BUILD VERSION SAVED!'
                    sh 'echo -> Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP}'
                }
            }
        }

        stage("Ansible Deploy to Staging server") {
            steps {
                ansiblePlaybook(
                    playbook              : './ansible/site.yml',
                    inventory             : './ansible/stage.inventory',
                    credentialsId         : 'applogin',
                    colorized             : true,
                    disableHostKeyChecking: true,
                    installation          : 'ansible',
                    extraVars             : [
                        USER: env.NEXUS_USER,
                        PASS: env.NEXUS_PASS,
                        NEXUS_URL: env.NEXUS_PRIVATE_URL,
                        RELEASE_REPO: env.RELEASE_REPO,
                        groupid: "ARTIFACTS",
                        subgroupid: "java-app",
                        build_version: "Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP}",
                    ]
                )
            }
        }
    }

    post {
        success {
            echo 'Slack Notification....'
            slackSend channel: '#jenkinscicd', 
                color: COLOR_MAP[currentBuild.currentResult], 
                message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build-Version: Build-${env.BUILD_ID}_${env.BUILD_TIMESTAMP} \n\n Artifact Uploaded to Staging Server! ✅\n\n More info at: ${env.BUILD_URL}"
        }
    }
}