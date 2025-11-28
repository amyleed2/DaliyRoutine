pipeline {
    agent any

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

        // Keychain 설정
        KEYCHAIN_PATH = "${HOME}/Library/Keychains/login.keychain-db"
        
        // Telegram
        TELEGRAM_BOT_TOKEN = credentials('TELEGRAM_BOT_TOKEN')
        TELEGRAM_CHAT_ID   = '8567999419'
    }

    stages {

        stage('Checkout') {
            steps {
                script {
                    // Generic Webhook Trigger의 Optional Filter가 이미 [Jenkins] 커밋을 필터링함
                    echo "🔍 Webhook Variables:"
                    echo "  - ref: ${env.ref ?: 'not set'}"
                    echo "  - commit_message: ${env.commit_message ?: 'not set'}"
                    
                    checkout scm
                    
                    def commitMessage = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    
                    echo "📝 최근 커밋: ${commitMessage}"
                    echo "✅ 빌드 진행"
                }
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

        stage('Unlock Keychain') {
            steps {
                withCredentials([string(credentialsId: 'KEYCHAIN_PASSWORD', variable: 'KEYCHAIN_PWD')]) {
                    sh '''
                    # Keychain 언락
                    security unlock-keychain -p "$KEYCHAIN_PWD" "$KEYCHAIN_PATH"
                    
                    # Keychain 타임아웃 설정 (3600초 = 1시간)
                    security set-keychain-settings -t 3600 -u "$KEYCHAIN_PATH"
                    
                    # 기본 Keychain으로 설정
                    security default-keychain -s "$KEYCHAIN_PATH"
                    
                    # Keychain 검색 리스트에 추가
                    security list-keychains -d user -s "$KEYCHAIN_PATH"
                    
                    # 사용 가능한 인증서 확인
                    echo "📋 사용 가능한 코드 서명 인증서:"
                    CERT_OUTPUT=$(security find-identity -v -p codesigning 2>&1)
                    echo "$CERT_OUTPUT"
                    
                    # Distribution 인증서 확인
                    if echo "$CERT_OUTPUT" | grep -q "Apple Distribution"; then
                        echo "✅ Distribution 인증서 발견"
                    else
                        echo "❌ Distribution 인증서를 찾을 수 없습니다!"
                        exit 1
                    fi
                    
                    # 인증서 접근 권한 설정 (Jenkins가 백그라운드에서 인증서 사용 가능하도록)
                    # 이 명령어는 각 인증서의 개인키에 접근 권한을 부여합니다
                    echo "🔐 인증서 접근 권한 설정 중..."
                    if security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PWD" "$KEYCHAIN_PATH" 2>&1; then
                        echo "✅ 인증서 접근 권한 설정 성공"
                    else
                        echo "⚠️  인증서 접근 권한 설정 실패 (일부 인증서는 추가 비밀번호가 필요할 수 있음)"
                        echo "⚠️  하지만 Keychain이 언락되어 있으므로 대부분의 경우 작동합니다"
                        echo "⚠️  만약 무한 Processing이 발생하면 수동으로 인증서 접근 권한을 설정해야 합니다"
                    fi
                    
                    echo "✅ Keychain 언락 완료"
                    '''
                }
            }
        }

        stage('Fastlane TestFlight Upload') {
            steps {
        	sh """
        	echo "🚀 Fastlane 빌드 시작..."
        	fastlane release
        	echo "✅ Fastlane 빌드 완료"
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
