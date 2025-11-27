pipeline {
    agent any

    options {
         skipDefaultCheckout()
    }

    environment {
        GIT_REPO = "https://github.com/amyleed2/DaliyRoutine.git"
        BRANCH   = "main"

        // rbenv 관련
        RBENV_ROOT = "$HOME/.rbenv"
        PATH       = "$HOME/.rbenv/shims:$HOME/.rbenv/bin:/opt/homebrew/bin:$PATH"
        RUBY_VERSION = "3.2.2"

        // UTF-8 환경 변수
        LANG   = "en_US.UTF-8"
        LC_ALL = "en_US.UTF-8"

        // Telegram
        TELEGRAM_BOT_TOKEN = credentials('TELEGRAM_BOT_TOKEN')
        TELEGRAM_CHAT_ID   = '8567999419'
    }

    stages {
        stage('Checkout') {
		when {
	                not {
                	 	changelog '.*\\[Jenkins\\].*'
                	}
            	}
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

        stage('Commit Build Number') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github_token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    git config user.email "amy.lee.d2@gmail.com"
                    git config user.name "amyleed2"
                    git add DailyRoutine.xcodeproj/project.pbxproj

                    if ! git diff --cached --quiet; then
                        BUILD_NUM=$(agvtool what-version -terse | head -1)
                        git commit -m "[Jenkins] Bump build number to ${BUILD_NUM}"

                        git config credential.helper store
                        echo "https://$GIT_USERNAME:$GIT_PASSWORD@github.com" > ~/.git-credentials
                        git push origin HEAD:main
                        rm -f ~/.git-credentials

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
        	sh """
		curl -s -X POST https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
		-d chat_id=${TELEGRAM_CHAT_ID} \
		-d "text=✅ 빌드 성공 - ${JOB_NAME} #${BUILD_NUMBER}"
		"""
    	}

    	failure {
        	echo "❌ TestFlight 업로드 실패. Console Output을 확인하세요."
        	sh """
		curl -s -X POST https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
		-d chat_id=${TELEGRAM_CHAT_ID} \
		-d "text=❌ 빌드 실패 - ${JOB_NAME} #${BUILD_NUMBER}"
		"""
	    }
	}
}
