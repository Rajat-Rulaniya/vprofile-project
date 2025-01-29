pipeline {
    agent any;

    tools {
        maven "MAVEN3"
        jdk "OracleJDK8"
    }

    environment {
        SNAP_REPO = 'vprofile-snapshot'   
        NEXUS-USER = 'admin'
        NEXUS-PASS = 'e7bpr-Ed25:!vb4'
        RELEASE-REPO = 'vprofile-release'
        CENTRAL-REPO = 'vpro-maven-central'
        NEXUS-GRP-REPO = 'vpro-maven-group'
        NEXUSIP = '172.31.39.95'
        NEXUSPORT = '8081'
        NEXUS_LOGIN = 'nexuslogin'
    }

    stages {
        stage("Build") {
            steps {
                sh "mvn -s setting.xml -DskipTests install"
            }
        }
        stage("") {}
        stage("") {}
        stage("") {}
        stage("") {}
    }
}