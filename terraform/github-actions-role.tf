# GitHub Actions용 IAM Role 및 OIDC Provider 설정

# OIDC Identity Provider 생성
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
  
  tags = {
    Name = "GitHub Actions OIDC Provider"
  }
}

# GitHub Actions용 IAM Role
resource "aws_iam_role" "github_actions" {
  name = "GitHubActions-ECR-EKS-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repository}:*"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "GitHub Actions Role"
  }
}

# ECR 및 EKS 권한 정책
resource "aws_iam_policy" "github_actions_policy" {
  name        = "GitHubActions-ECR-EKS-Policy"
  description = "GitHub Actions에서 ECR 및 EKS 접근을 위한 정책"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
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
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# 정책을 Role에 연결
resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

# 변수 정의
variable "github_username" {
  description = "GitHub 사용자명"
  type        = string
}

variable "github_repository" {
  description = "GitHub 리포지토리명"
  type        = string
}

# 출력값
output "github_actions_role_arn" {
  description = "GitHub Actions에서 사용할 Role ARN"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}