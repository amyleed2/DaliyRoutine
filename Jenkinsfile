pipeline {
    agent any

    environment {
        GIT_REPO = "https://github.com/amyleed2/DaliyRoutine.git"
        BRANCH = "main"
        RBENV_ROOT = "$HOME/.rbenv"
        PATH = "$HOME/.rbenv/shims:$HOME/.rbenv/bin:/opt/homebrew/bin:$PATH"
        RUBY_VERSION = "3.2.2"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: "${BRANCH}",
                    credentialsId: 'github_token',
                    url: "${GIT_REPO}"
            }
        }

        stage('Install Dependencies') {
            steps {
                sh """
                brew install fastlane || true
                gem install fastlane --user-install || true
                rbenv install -s ${RUBY_VERSION}
                rbenv global ${RUBY_VERSION}
                ruby -v
                """
            }
        }

        stage('Prepare API Key') {
            steps {
                withCredentials([file(credentialsId: 'APPLE_API_KEY', variable: 'API_KEY_FILE')]) {
                    sh """
                    mkdir -p fastlane
                    cp "\$API_KEY_FILE" fastlane/AuthKey_PQ2AAF864L.p8
                    """
                }
            }
        }

        stage('Fastlane TestFlight Upload') {
            steps {
                sh """
                cd fastlane
                fastlane release
                """
            }
        }
    }

    post {
        success {
            echo "🎉 TestFlight 업로드 성공!"
        }
        failure {
            echo "❌ TestFlight 업로드 실패. Console Output을 확인하세요."
        }
    }
}