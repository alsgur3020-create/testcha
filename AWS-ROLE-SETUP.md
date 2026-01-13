# AWS IAM Role 설정 가이드 (OIDC 사용)

## 개요
GitHub Actions에서 AWS 액세스 키 대신 IAM Role을 사용하여 보안성을 높이는 방법입니다.

## 1. AWS OIDC Identity Provider 생성

### AWS Console에서 설정
```
1. AWS Console → IAM → Identity providers
2. Add provider 클릭
3. Provider type: OpenID Connect
4. Provider URL: https://token.actions.githubusercontent.com
5. Audience: sts.amazonaws.com
6. Add provider 클릭
```

### AWS CLI로 설정 (선택사항)
```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## 2. IAM Role 생성

### Trust Policy 생성
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::101553892293:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

### Permission Policy 생성
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:ListRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

## 3. AWS Console에서 단계별 설정

### Step 1: OIDC Provider 생성
```
1. AWS Console → IAM → Identity providers → Add provider
2. Provider type: OpenID Connect
3. Provider URL: https://token.actions.githubusercontent.com
4. Audience: sts.amazonaws.com
5. Thumbprint: 6938fd4d98bab03faadb97b34396831e3780aea1 (자동 입력됨)
6. Add provider
```

### Step 2: IAM Role 생성
```
1. AWS Console → IAM → Roles → Create role
2. Trusted entity type: Web identity
3. Identity provider: token.actions.githubusercontent.com
4. Audience: sts.amazonaws.com
5. GitHub organization: YOUR_GITHUB_USERNAME
6. GitHub repository: YOUR_REPO_NAME
7. GitHub branch: main (선택사항)
8. Next 클릭
```

### Step 3: Permission Policy 연결
```
1. Create policy 클릭
2. JSON 탭에서 위의 Permission Policy 붙여넣기
3. Policy name: GitHubActions-ECR-EKS-Policy
4. Create policy
5. 생성된 정책을 Role에 연결
```

### Step 4: Role 이름 설정
```
Role name: GitHubActions-ECR-EKS-Role
Description: GitHub Actions에서 ECR 및 EKS 접근용 Role
```

## 4. GitHub Secrets 업데이트

### 기존 Secrets 삭제
```
GitHub Repository → Settings → Secrets and variables → Actions

삭제할 Secrets:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
```

### 새로운 Secrets 추가
```
Name: AWS_ROLE_ARN
Secret: arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role

Name: EKS_CLUSTER_NAME
Secret: your-cluster-name
```

## 5. Trust Policy 예시 (리포지토리별)

### 특정 리포지토리만 허용
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::101553892293:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:myusername/my-3tier-app:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

### 특정 브랜치만 허용
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::101553892293:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:myusername/my-3tier-app:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

## 6. 테스트 및 검증

### 로컬에서 Role 테스트
```bash
# Role ARN 확인
aws sts get-caller-identity

# Role assume 테스트
aws sts assume-role-with-web-identity \
    --role-arn arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role \
    --role-session-name test-session \
    --web-identity-token "test-token"
```

### GitHub Actions에서 확인
```yaml
- name: Test Role Assumption
  run: |
    echo "Current identity:"
    aws sts get-caller-identity
    echo "Role ARN: $(aws sts get-caller-identity --query Arn --output text)"
```

## 7. 보안 장점

### IAM Role 사용의 장점
- ✅ 장기 자격 증명 불필요 (액세스 키 없음)
- ✅ 임시 자격 증명 사용 (자동 만료)
- ✅ 세밀한 권한 제어 가능
- ✅ 자격 증명 로테이션 불필요
- ✅ GitHub Secrets에 민감한 정보 저장 불필요

### 기존 액세스 키 방식의 단점
- ❌ 장기 자격 증명 (만료되지 않음)
- ❌ 정기적인 로테이션 필요
- ❌ GitHub Secrets에 민감한 정보 저장
- ❌ 키 유출 위험

## 8. 트러블슈팅

### 일반적인 오류

#### "No OpenIDConnect provider found"
```
원인: OIDC Provider가 생성되지 않음
해결: AWS Console에서 OIDC Provider 생성
```

#### "Not authorized to perform sts:AssumeRoleWithWebIdentity"
```
원인: Trust Policy 설정 오류
해결: Trust Policy에서 리포지토리 정보 확인
```

#### "Invalid identity token"
```
원인: GitHub Actions permissions 설정 누락
해결: 워크플로우에 id-token: write 권한 추가
```

## 9. 모니터링

### CloudTrail로 Role 사용 추적
```json
{
  "eventName": "AssumeRoleWithWebIdentity",
  "sourceIPAddress": "GitHub Actions IP",
  "userIdentity": {
    "type": "WebIdentityUser",
    "principalId": "OIDC:token.actions.githubusercontent.com:sub"
  }
}
```

### 정기 검토 사항
- [ ] Role 사용 빈도 확인
- [ ] 불필요한 권한 제거
- [ ] Trust Policy 조건 검토
- [ ] CloudTrail 로그 분석