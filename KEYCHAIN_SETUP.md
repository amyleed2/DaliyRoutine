# Keychain 인증서 Trust 설정 수동 설정 가이드

## 🎯 목적
Jenkins가 백그라운드에서 실행될 때도 Distribution 인증서를 사용할 수 있도록 Trust 설정 및 Access Control 설정

---

## ⚠️ 현재 에러
```
error: Invalid trust settings. Restore system default trust settings for certificate "Apple Distribution: JIEUN LEE (7CJ6R87Q3T)" in order to sign code with it.
```

이 에러는 인증서의 **Trust 설정**이 잘못되어 있을 때 발생합니다.

---

## 📝 수동 설정 방법 (가장 확실한 방법)

### 1단계: Keychain Access 앱 열기

```bash
open /Applications/Utilities/Keychain\ Access.app
```

### 2단계: Distribution 인증서 찾기

1. **왼쪽 사이드바**에서 `login` Keychain 선택
2. **카테고리**에서 `My Certificates` 선택
3. **"Apple Distribution: JIEUN LEE (7CJ6R87Q3T)"** 인증서 찾기

### 3단계: 인증서 Trust 설정 수정

1. **"Apple Distribution" 인증서 더블클릭**
2. **"Trust" 탭** 클릭
3. **"When using this certificate"** 드롭다운에서 **"Always Trust"** 선택
4. 창을 닫으면 비밀번호를 물어봅니다 → **맥 비밀번호 입력**
5. **"Save Changes"** 클릭

### 4단계: 인증서 Access Control 설정

1. **"Apple Distribution" 인증서 더블클릭** (또는 이미 열려있다면)
2. **"Access Control" 탭** 클릭
3. **"Allow all applications to access this item"** 체크
   - 또는 **"Confirm before allowing access"** 체크 해제
4. **"Save Changes"** 클릭

### 5단계: 개인키 Access Control 설정

1. **인증서를 펼쳐서 개인키 확인** (인증서 왼쪽 화살표 클릭)
2. **개인키 더블클릭**
3. **"Access Control" 탭** 클릭
4. **"Allow all applications to access this item"** 체크
5. **"Save Changes"** 클릭

---

## 🔧 터미널에서 자동 설정 (대안)

만약 수동 설정이 번거롭다면, 다음 명령어를 실행:

```bash
# Keychain 언락
security unlock-keychain ~/Library/Keychains/login.keychain-db

# Distribution 인증서 찾기
DIST_CERT=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -1 | awk -F'"' '{print $2}')

if [ -n "$DIST_CERT" ]; then
    echo "Distribution 인증서 발견: $DIST_CERT"
    
    # 인증서 접근 권한 설정
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$(security find-generic-password -w ~/Library/Keychains/login.keychain-db 2>/dev/null || echo '')" ~/Library/Keychains/login.keychain-db
    
    echo "✅ 인증서 접근 권한 설정 완료"
else
    echo "❌ Distribution 인증서를 찾을 수 없습니다"
fi
```

**주의**: 이 명령어는 맥 비밀번호가 필요할 수 있어요.

---

## 🧪 테스트

설정 후 다음 명령어로 테스트:

```bash
# Keychain 언락
security unlock-keychain ~/Library/Keychains/login.keychain-db

# 인증서 확인
security find-identity -v -p codesigning | grep "Apple Distribution"

# codesign 테스트 (실제 서명은 하지 않고 인증서만 확인)
codesign --display --verbose=4 /Applications/Xcode.app 2>&1 | head -5
```

---

## ✅ 완료 체크리스트

- [ ] Keychain Access에서 Distribution 인증서 찾기
- [ ] 인증서의 "Access Control" 설정
- [ ] 개인키의 "Access Control" 설정
- [ ] Jenkins 빌드 테스트
- [ ] 무한 Processing 없이 정상 업로드 확인

---

## 🚨 문제 해결

### "인증서를 찾을 수 없습니다"

**해결:**
1. Xcode → Settings → Accounts → Manage Certificates
2. "Apple Distribution" 인증서가 있는지 확인
3. 없다면 "+" 버튼으로 생성

### 여전히 무한 Processing

**해결:**
1. Keychain Access에서 인증서와 개인키 모두 "Allow all applications" 설정 확인
2. Jenkins를 재시작
3. Keychain 비밀번호가 Jenkins Credentials에 올바르게 저장되어 있는지 확인

---

## 📚 참고

- Keychain Access에서 수동 설정하는 것이 가장 확실합니다
- 자동화 스크립트는 일부 환경에서 실패할 수 있습니다
- 한 번 설정하면 계속 유지됩니다

