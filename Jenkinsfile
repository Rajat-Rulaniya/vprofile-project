pipeline {
    agent any;

    tools {
        maven "MAVEN3"
        jdk "OracleJDK8"
    }

    environment {
        SNAP_REPO = 'vprofile-snapshot'   
        NEXUS_USER = 'admin'
        NEXUS_PASS = 'e7bpr-Ed25:!vb4'
        RELEASE_REPO = 'vprofile-release'
        CENTRAL_REPO = 'vpro-maven-central'
        NEXUS_GRP_REPO = 'vpro-maven-group'
        NEXUSIP = '172.31.39.95'
        NEXUSPORT = '8081'
        NEXUS_LOGIN = 'nexuslogin'
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
                sh "mvn -s setting.xml test"
            }
        }

        stage("Checkstyle Analysis") {
            steps {
                sh 'mvn -s setting.xml checkstyle:checkstyle'
            }
        }
    }
}