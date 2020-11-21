pipeline {
    agent any
    
    stages {
        stage("tools") {
            steps {
                sh 'python --version'
                sh 'pip install vunit-hdl'
                sh 'ghdl --version'
            }
        }
        stage("simulate") {
            steps {
                sh 'cd ram && python ./run.py -p6 -x output.xml --xunit-xml-format jenkins --no-color'
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
