# Jenkins Keychain 설정 가이드

## 🔐 문제 상황
- Xcode Organizer / Jenkins 수동 빌드: ✅ 성공
- 터미널 fastlane / Jenkins 자동 빌드: ❌ 무한 Processing

**원인**: 자동 실행 시 Keychain이 잠겨있어서 코드 서명 인증서에 접근 불가

---

## 📝 해결 방법

### 1단계: Jenkins에 Keychain 비밀번호 등록

1. **Jenkins 대시보드** 접속: `http://localhost:8080`

2. **Manage Jenkins** → **Credentials** 클릭

3. **(global)** 도메인 클릭

4. **Add Credentials** 클릭

5. 다음 정보 입력:
   - **Kind**: `Secret text`
   - **Scope**: `Global`
   - **Secret**: `[맥 로그인 비밀번호 입력]`
   - **ID**: `KEYCHAIN_PASSWORD`
   - **Description**: `Mac Keychain Password`

6. **Create** 클릭

---

### 2단계: Keychain 자동 언락 테스트

터미널에서 테스트:

```bash
# Keychain 상태 확인
security show-keychain-info ~/Library/Keychains/login.keychain-db

# Keychain 언락 (비밀번호 입력 필요)
security unlock-keychain ~/Library/Keychains/login.keychain-db

# 타임아웃 설정 (3600초 = 1시간)
security set-keychain-settings -t 3600 -u ~/Library/Keychains/login.keychain-db

# 인증서 확인
security find-identity -v -p codesigning
```

---

### 3단계: 터미널에서 fastlane 테스트

```bash
cd /Users/ezyeun/Desktop/Workspace/02_Personal/DailyRoutine

# Keychain 언락 후 fastlane 실행
security unlock-keychain ~/Library/Keychains/login.keychain-db
fastlane release
```

이제 무한 Processing 없이 정상 업로드되어야 합니다! ✅

---

## 🔄 자동화 완성

### Jenkins 자동 빌드 흐름:
1. GitHub Push → Webhook → Jenkins 트리거
2. **Keychain 언락** (새로 추가!)
3. Fastlane 빌드 & TestFlight 업로드
4. 빌드 번호 커밋 & Push
5. Telegram 알림

---

## 🚨 문제 해결

### "security: SecKeychainUnlock: The user name or passphrase you entered is not correct."
→ Jenkins Credentials의 `KEYCHAIN_PASSWORD`가 맥 로그인 비밀번호와 일치하는지 확인

### 여전히 무한 Processing
→ 다음 명령어로 인증서 확인:
```bash
security find-identity -v -p codesigning
```

유효한 "Apple Distribution" 인증서가 있어야 합니다.

### Keychain이 자꾸 잠김
→ Jenkinsfile의 타임아웃을 늘리세요:
```bash
security set-keychain-settings -t 7200 -u "$KEYCHAIN_PATH"  # 2시간
```

---

## ✅ 완료 체크리스트

- [ ] Jenkins에 `KEYCHAIN_PASSWORD` Credential 등록
- [ ] 터미널에서 `security unlock-keychain` 테스트
- [ ] 터미널에서 `fastlane release` 테스트 (무한 Processing 없이 성공)
- [ ] Jenkinsfile 커밋 & Push
- [ ] Jenkins 자동 빌드 테스트
- [ ] TestFlight에서 빌드 확인

---

## 📚 참고

- Jenkins는 백그라운드에서 실행되므로 Keychain 접근 권한이 제한됩니다
- `security unlock-keychain` 명령으로 명시적으로 언락해야 합니다
- 보안을 위해 타임아웃을 설정하여 일정 시간 후 자동으로 잠기도록 합니다

