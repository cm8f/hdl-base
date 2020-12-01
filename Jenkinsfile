pipeline {
    agent any

    stages {
        stage("tools") {
            steps {
                sh 'python3 --version'
                sh 'pip3 install vunit-hdl'
                sh 'ghdl --version'
            }
        }
        stage("compile") {
            steps {
                sh 'cd ram && python3 ./run.py --compile --exit-0'
            }
        }
        stage("elaborate") {
            steps {
                sh 'cd ram && python3 ./run.py --elaborate -p6 --exit-0'
            }
        }
        stage("simulate") {
            steps {
                sh 'cd ram && python3 ./run.py -p6 -x output.xml --xunit-xml-format jenkins --exit-0'
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
