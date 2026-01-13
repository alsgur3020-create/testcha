# GitHub Secrets 설정 체크리스트

## 필수 확인 사항

### 1. GitHub Repository 확인
- [ ] 올바른 리포지토리에서 작업 중인가?
- [ ] 리포지토리 소유자 권한이 있는가?
- [ ] Private 리포지토리인가? (Public 리포지토리는 Secrets 제한이 있음)

### 2. Secrets 이름 정확성 (대소문자 구분)
```
정확한 이름:
✅ AWS_ACCESS_KEY_ID
✅ AWS_SECRET_ACCESS_KEY  
✅ AWS_REGION
✅ EKS_CLUSTER_NAME

잘못된 예시:
❌ aws_access_key_id (소문자)
❌ AWS-ACCESS-KEY-ID (하이픈)
❌ AWS_ACCESS_KEY (불완전)
```

### 3. Secrets 값 확인
- [ ] AWS_ACCESS_KEY_ID: AKIA로 시작하는 20자리
- [ ] AWS_SECRET_ACCESS_KEY: 40자리 영숫자 조합
- [ ] AWS_REGION: ap-northeast-2 (정확한 리전명)
- [ ] EKS_CLUSTER_NAME: 실제 클러스터 이름

### 4. 브랜치 및 트리거 확인
- [ ] main 브랜치에 push했는가?
- [ ] Pull Request가 아닌 직접 push인가?
- [ ] 워크플로우 파일이 .github/workflows/ 경로에 있는가?

### 5. 권한 확인
- [ ] 리포지토리 Settings 접근 권한이 있는가?
- [ ] Actions 권한이 활성화되어 있는가?
- [ ] Secrets 생성/수정 권한이 있는가?

## 단계별 해결 방법

### Step 1: GitHub에서 Secrets 재확인
```
1. GitHub 리포지토리 → Settings
2. 왼쪽 사이드바 → Secrets and variables → Actions
3. Repository secrets 섹션 확인
4. 4개의 Secret이 모두 존재하는지 확인
```

### Step 2: Secrets 재생성
```
1. 기존 Secret 삭제 (Delete 버튼)
2. New repository secret 클릭
3. 정확한 이름과 값으로 재생성
```

### Step 3: 로컬에서 AWS 자격 증명 테스트
```bash
# 1. AWS CLI 설정
aws configure set aws_access_key_id YOUR_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_SECRET_KEY
aws configure set region ap-northeast-2

# 2. 자격 증명 확인
aws sts get-caller-identity

# 3. ECR 접근 테스트
aws ecr get-login-password --region ap-northeast-2

# 4. EKS 접근 테스트
aws eks describe-cluster --name YOUR_CLUSTER_NAME --region ap-northeast-2
```

### Step 4: 워크플로우 재실행
```
1. GitHub → Actions 탭
2. 실패한 워크플로우 선택
3. Re-run jobs 클릭
4. Debug GitHub Secrets 스텝 결과 확인
```

## 일반적인 문제와 해결책

### 문제 1: "Secret not found"
**원인:** Secret 이름 오타 또는 대소문자 불일치
**해결:** 정확한 이름으로 Secret 재생성

### 문제 2: "Invalid credentials"
**원인:** 잘못된 AWS 액세스 키 또는 만료된 키
**해결:** AWS Console에서 새 액세스 키 생성

### 문제 3: "Permission denied"
**원인:** IAM 사용자 권한 부족
**해결:** 필요한 IAM 정책 연결

### 문제 4: "Repository not found"
**원인:** 잘못된 리포지토리 또는 권한 부족
**해결:** 올바른 리포지토리에서 작업하는지 확인

## 디버깅 명령어

### GitHub Actions에서 확인
```yaml
- name: Debug Environment
  run: |
    echo "Repository: ${{ github.repository }}"
    echo "Branch: ${{ github.ref }}"
    echo "Event: ${{ github.event_name }}"
    echo "Actor: ${{ github.actor }}"
```

### 로컬에서 확인
```bash
# Git 정보 확인
git remote -v
git branch
git log --oneline -5

# AWS 설정 확인
aws configure list
aws sts get-caller-identity
```