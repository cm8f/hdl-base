pipeline {
    agent {
        docker { image 'ghdl/vunit:gcc' }
    }

    stages {
        stage("tools") {
            steps {
                sh 'python3 --version'
                sh 'ghdl --version'
            }
        }
        stage("simulate") {
            steps {
                sh 'python3 ./run.py -p6 -x output.xml --xunit-xml-format jenkins --exit-0 --no-color --cover --clean'
            }
        }
    }
    post {
        always {
            
            archiveArtifacts artifacts: 'vunit_out/*', fingerprint: true
            archiveArtifacts artifacts: '**/*.xml', fingerprint: true
            archiveArtifacts artifacts: '**/*.xml', fingerprint: true
            archiveArtifacts artifacts: '**/*.txt', fingerprint: true
            junit '**/output.xml'
            step([$class: 'CoberturaPublisher', autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: '**/coverage.xml', failUnhealthy: false, failUnstable: false, maxNumberOfBuilds: 0, onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false])

        }
    }
}

