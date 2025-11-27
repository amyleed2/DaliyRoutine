pipeline {
    agent any

    environment {
        GIT_REPO = "https://github.com/amyleed2/DaliyRoutine.git"
        BRANCH = "main"

        # rbenv 관련
        RBENV_ROOT = "$HOME/.rbenv"
        PATH = "$HOME/.rbenv/shims:$HOME/.rbenv/bin:/opt/homebrew/bin:$PATH"
        RUBY_VERSION = "3.2.2"

        # UTF-8 환경 변수
        LANG = "en_US.UTF-8"
        LC_ALL = "en_US.UTF-8"
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
                # rbenv로 Ruby 버전 설정
                rbenv install -s ${RUBY_VERSION}
                rbenv global ${RUBY_VERSION}
                ruby -v

                # Fastlane 설치
                brew install fastlane || true
                gem install fastlane --user-install || true

                # 환경 변수 적용 확인
                echo "PATH: $PATH"
                echo "LANG: $LANG"
                echo "LC_ALL: $LC_ALL"
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
                # UTF-8 적용
                export LANG=en_US.UTF-8
                export LC_ALL=en_US.UTF-8

                # rbenv 적용
                export PATH=$HOME/.rbenv/shims:$HOME/.rbenv/bin:/opt/homebrew/bin:$PATH
                rbenv global ${RUBY_VERSION}
                ruby -v

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