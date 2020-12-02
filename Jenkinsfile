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
        stage("compile") {
            steps {
                sh 'python3 ./run.py --compile --no-color --cover 1'
            }
        }
        stage("elaborate") {
            steps {
                sh 'python3 ./run.py --elaborate -p6 --no-color --cover 1'
            }
        }
        stage("simulate") {
            steps {
                sh 'python3 ./run.py -p6 -x output.xml --xunit-xml-format jenkins --exit-0 --no-color --cover 1'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: '**/*.xml', fingerprint: true
            archiveArtifacts artifacts: '**/*.txt', fingerprint: true
            junit '**/output.xml'
            step([$class: 'CoberturaPublisher', autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: '**/coverage.xml', failUnhealthy: false, failUnstable: false, maxNumberOfBuilds: 0, onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false])

        }
    }
}
