resource "aws_iam_policy" "cw_agent_policy" {
  name        = "cw-agent-policy"
  description = "Policy for CloudWatch Agent"
  policy      = file("cloudwatch_agent_policy.json")
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cw_agent_policy.arn
}
