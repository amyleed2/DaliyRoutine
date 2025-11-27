pipeline {
    agent any

    // Jenkins 자신이 만든 커밋은 빌드하지 않음
    options {
        skipDefaultCheckout()
    }

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
    }

    stages {

        stage('Checkout') {
            steps {
                script {
                    def changeLogSets = currentBuild.changeSets
                    for (int i = 0; i < changeLogSets.size(); i++) {
                        def entries = changeLogSets[i].items
                        for (int j = 0; j < entries.length; j++) {
                            def entry = entries[j]
                            if (entry.msg.contains('[Jenkins]')) {
                                echo "⏭️  Skipping build - commit by Jenkins: ${entry.msg}"
                                currentBuild.result = 'NOT_BUILT'
                                error('Skipping Jenkins auto-commit')
                            }
                        }
                    }
                }
                
                git branch: "${BRANCH}",
                    credentialsId: 'github_token',
                    url: "${GIT_REPO}"
            }
        }

        stage('Install Dependencies') {
            steps {
                sh """
                gem install bundler --user-install || true
                bundle install
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
                bundle exec fastlane release
                """
            }
        }

        stage('Commit Build Number') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github_token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    git config user.email "amy.lee.d2@gmail.com"
                    git config user.name "amyleed2"
                    git add DailyRoutine.xcodeproj/project.pbxproj
                    
                    # 변경사항이 있을 때만 커밋
                    if ! git diff --cached --quiet; then
                        BUILD_NUM=$(agvtool what-version -terse)
                        git commit -m "[Jenkins] Bump build number to ${BUILD_NUM}"
                        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/amyleed2/DaliyRoutine.git HEAD:main
                        echo "✅ Build number committed and pushed"
                    else
                        echo "ℹ️  No changes to commit"
                    fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "🎉 TestFlight 업로드 성공!"
            slackSend(channel: '#jenkins_build_ios', color: 'good', message: "✅ 빌드 성공 - ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        failure {
            echo "❌ TestFlight 업로드 실패. Console Output을 확인하세요."
            slackSend(channel: '#jenkins_build_ios', color: 'danger', message: "❌ 빌드 실패 - ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
    }
}