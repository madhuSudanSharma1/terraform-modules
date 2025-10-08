# Defining IAM role
resource "aws_iam_role" "iam_role" {
  name = var.role_name

  assume_role_policy = var.assume_role_policy

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# Managed policies
resource "aws_iam_role_policy_attachment" "role_policies" {
  count = length(var.policy_arns)

  role       = aws_iam_role.iam_role.name
  policy_arn = var.policy_arns[count.index]
}

# Optional inline policy
resource "aws_iam_role_policy" "inline_policy" {
  count = var.inline_policy != "" ? 1 : 0

  name   = "${var.role_name}-inline-policy"
  role   = aws_iam_role.iam_role.id
  policy = var.inline_policy
}

# Instance Profile (for EC2 instances)
resource "aws_iam_instance_profile" "instance_profile" {
  count = var.create_instance_profile ? 1 : 0

  role = aws_iam_role.iam_role.name
}