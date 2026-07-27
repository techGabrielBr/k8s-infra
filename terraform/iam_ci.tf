resource "aws_iam_user" "ci" {
  name = "${var.project_name}-ci"
}

resource "aws_iam_user_policy" "ci" {
  name = "${var.project_name}-ci-policy"
  user = aws_iam_user.ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [for repo in aws_ecr_repository.apis : repo.arn]
      },
      {
        Sid      = "EksDescribe"
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = module.eks.cluster_arn
      },
      {
        Sid      = "OpenSearchDescribe"
        Effect   = "Allow"
        Action   = "es:DescribeDomain"
        Resource = aws_opensearch_domain.games.arn
      }
    ]
  })
}
