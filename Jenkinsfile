pipeline {
    agent any

    environment {
        GIT_REPO = "https://github.com/amyleed2/DaliyRoutine.git"
        BRANCH = "main"

        // rbenv 관련
        RBENV_ROOT = "$HOME/.rbenv"
        PATH = "$HOME/.rbenv/shims:$HOME/.rbenv/bin:/opt/homebrew/bin:$PATH"
        RUBY_VERSION = "3.2.2"

        // UTF-8 환경 변수
        LANG = "en_US.UTF-8"
        LC_ALL = "en_US.UTF-8"

        // Jenkins Credentials에 저장된 Token 불러오기
        TELEGRAM_BOT_TOKEN = credentials('TELEGRAM_BOT_TOKEN')
        TELEGRAM_CHAT_ID = '8567999419'    // chat_id는 그냥 써도 됨
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
                fastlane release
                """
            }
        }
    }

    post {
        success {
            echo "🎉 TestFlight 업로드 성공!"

            sh """
            curl -X POST https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
            -d chat_id=${TELEGRAM_CHAT_ID} \
            -d text="🎉 *Build Success!*%0AJob: ${JOB_NAME}%0ABuild: #${BUILD_NUMBER}" \
            -d parse_mode=Markdown
            """
        }
        failure {
            echo "❌ TestFlight 업로드 실패. Console Output을 확인하세요."

            sh """
            curl -X POST https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
            -d chat_id=${TELEGRAM_CHAT_ID} \
            -d text="❗ *Build FAILED* ❗%0AJob: ${JOB_NAME}%0ABuild: #${BUILD_NUMBER}" \
            -d parse_mode=Markdown
            """
        }
    }
}