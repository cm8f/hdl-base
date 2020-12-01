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
                sh 'cd ram && python3 ./run.py --compile --no-color'
            }
        }
        stage("elaborate") {
            steps {
                sh 'cd ram && python3 ./run.py --elaborate -p6 --no-color'
            }
        }
        stage("simulate") {
            steps {
                sh 'cd ram && python3 ./run.py -p6 -x output.xml --xunit-xml-format jenkins --exit-0 --no-color'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: '**/*.xml', fingerprint: true
            junit '**/*.xml'
        }
    }
}