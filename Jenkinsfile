pipeline {
    agent any;

    tools {
        maven "MAVEN3"
        jdk "OracleJDK17"
    }

    environment {
        NEXUS_USER = 'admin'
        NEXUS_PASS = '1234'
        RELEASE_REPO = 'rajatapp-release'
        CENTRAL_REPO = 'rajatapp-dependencies'
        NEXUS_GRP_REPO = 'rajatapp-group'
        NEXUSIP = '3.80.81.175'
        NEXUSPORT = '8081'
        NEXUS_LOGIN = 'nexuslogin'
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
    }
}