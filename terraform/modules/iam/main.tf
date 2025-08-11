resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy
}

resource "aws_iam_role_policy" "this" {
  count = length(var.policies) > 0 ? 1 : 0

  name   = var.policies[0].name
  role   = aws_iam_role.this.id
  policy = var.policies[0].document
}
