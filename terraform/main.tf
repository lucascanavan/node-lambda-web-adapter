/*
resource "aws_lb" "alb" {
	name = "node-lambda-web-adapter-alb"
	internal = false
	load_balancer_type = "application"
	subnets = var.alb_subnets
	security_groups = [
		aws_security_group.alb_security_groups.id]
}

resource "aws_security_group" "alb_security_groups" {
	name = "node-lambda-web-adapter-security-groups"
	description = "Allow HTTP/s inbound traffic"
	vpc_id = var.vpc_id

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = [
			"0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = [
			"0.0.0.0/0"]
	}
}

resource "aws_alb_target_group_attachment" "lambda_target_group_attachment" {
	target_group_arn = aws_lb_target_group.lambda_target_group.arn
	target_id = aws_lambda_function.node-lambda-web-adapter.arn
	depends_on = [
		aws_lambda_permission.with_lb
	]
}

resource "aws_lb_listener" "http_listener" {
	count = 1
	default_action {
		type = "forward"
		target_group_arn = aws_lb_target_group.lambda_target_group.arn
	}
	port = 80
	load_balancer_arn = aws_lb.alb.arn
	protocol = "HTTP"
}

resource "aws_lb_target_group" "lambda_target_group" {
	lambda_multi_value_headers_enabled = true
	health_check {
		enabled = false
		interval = 35
		path = "/"
		unhealthy_threshold = 2
		healthy_threshold = 5
		timeout = 30
	}
	name = "node-lambda-web-adapter-tg"
	target_type = "lambda"
	vpc_id = var.vpc_id
}

resource "aws_lambda_permission" "with_lb" {
	action = "lambda:InvokeFunction"
	function_name = aws_lambda_function.node-lambda-web-adapter.function_name
	principal = "elasticloadbalancing.amazonaws.com"
}
*/

resource "aws_iam_role" "lambda_role" {
  name = "node-lambda-web-adapter_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "lambda.amazonaws.com"
	  },
	  "Effect": "Allow",
	  "Sid": ""
	}
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
	name = "node-lambda-web-adapter_policy"
	role = aws_iam_role.lambda_role.id

	policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
		{
	  "Action": [
		"logs:CreateLogGroup",
		"logs:CreateLogStream",
		"logs:PutLogEvents"
	  ],
	  "Resource": "*",
	  "Effect": "Allow"
	}
  ]
}
EOF
}

resource "aws_lambda_function_url" "url1" {
  function_name      = aws_lambda_function.node-lambda-web-adapter.function_name
  authorization_type = "NONE"
  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

resource "aws_lambda_layer_version" "layer" {
  filename = "${path.module}/../temp/produles.zip"
  source_code_hash = filebase64sha256("${path.module}/../temp/produles.zip")
  layer_name = "node-lambda-web-adapter-${terraform.workspace}"
  compatible_runtimes = ["nodejs16.x"]
}

resource "aws_lambda_function" "node-lambda-web-adapter" {
	layers = [
		aws_lambda_layer_version.layer.arn,
	"arn:aws:lambda:ap-southeast-2:753240598075:layer:LambdaAdapterLayerX86:7"
	]
	filename = "${path.module}/../temp/dist.zip"
	source_code_hash = filebase64sha256("${path.module}/../temp/dist.zip")
	function_name    = "node-lambda-web-adapter"
	role             = aws_iam_role.lambda_role.arn
	handler          = "run.sh"
	runtime          = "nodejs16.x"
	environment {
		variables = {
			NODE_ENV = "production",
			AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
		}
	}
}
