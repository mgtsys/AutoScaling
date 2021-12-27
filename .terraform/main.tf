variable "aws_region" {
    type = string
    description = "Enter you region: "
}
variable "access_key" {
    type = string
    description = "Enter you Access Key: "
}
variable "secret_key" {
    type = string
    description = "Enter you Secret Key: "
}
variable "project_name" {
    type = string
    description = "Enter your project-name: "
}
data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.project_name}"
  }
}
data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags = {
    Name = "${var.project_name}-Private*"
  }
}
data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags = {
    Name = "${var.project_name}-Public*"
  }
}
data "aws_instance" "web_master" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-web-master"]
  }
}
data "aws_instance" "web_admin" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-admin"]
  }
}
provider "aws" {
    region = var.aws_region
    access_key = var.access_key
    secret_key = var.secret_key
}

output "project_name" {
    value = "${var.project_name}"
}

resource "aws_ami_from_instance" "web_master_ami" {
  name               = "${var.project_name}-ami"
  source_instance_id = data.aws_instance.web_master.id
}

resource "aws_launch_configuration" "as_launchconfig" {
  name   = "${var.project_name}-0.0.1"
  image_id      = aws_ami_from_instance.web_master_ami.id
  instance_type = "t4g.small"
  security_groups = data.aws_instance.web_master.vpc_security_group_ids
 lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb_sg" {
  name        = "arvind-test-elb"
  description = "Allow traffic to instances through Elastic Load Balancer"
  vpc_id = data.aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3333
    to_port     = 3333
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "web_elb" {
  name = "${var.project_name}-elb"
  internal = false
  enable_http2 = true
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.elb_sg.id,
  ]
  idle_timeout = 1800
  subnets = data.aws_subnet_ids.public.ids
}

resource "aws_lb_target_group" "admin_elb_tg" {
  name     = "${var.project_name}-admin"
  port     = 443
  protocol = "HTTPS"
  deregistration_delay = 30
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "admin_tg_attachment" {
  target_group_arn = aws_lb_target_group.admin_elb_tg.arn
  target_id        = data.aws_instance.web_admin.id
  port             = 443
}

resource "aws_lb_target_group" "http_elb_tg" {
  name     = "${var.project_name}-http"
  port     = 80
  protocol = "HTTP"
  deregistration_delay = 30
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group" "https_elb_tg" {
  name     = "${var.project_name}-https"
  port     = 443
  protocol = "HTTPS"
  deregistration_delay = 30
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group" "code_deploy_elb_tg" {
  name     = "${var.project_name}-code-deploy"
  port     = 3333
  protocol = "HTTP"
  deregistration_delay = 30
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "code-deploy_tg_attachment" {
  target_group_arn = aws_lb_target_group.code_deploy_elb_tg.arn
  target_id        = data.aws_instance.web_admin.id
  port             = 3333
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_elb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name = "${var.project_name}-auto-scaling-group"
  min_size             = 1
  desired_capacity     = 1
  max_size             = 4
  health_check_type    = "ELB"
  health_check_grace_period = 600
  termination_policies = ["OldestInstance"]
  target_group_arns = [ aws_lb_target_group.http_elb_tg.arn, aws_lb_target_group.https_elb_tg.arn ]
  launch_configuration = aws_launch_configuration.as_launchconfig.name
  metrics_granularity = "1Minute"
  vpc_zone_identifier  = data.aws_subnet_ids.private.ids
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = "prod"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "WebScaleUp"
  scaling_adjustment = 1
  policy_type = "SimpleScaling"
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "${var.project_name}-WebScaleUp"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "60"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_up.arn ]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "WebScaleDown"
  policy_type = "SimpleScaling"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "${var.project_name}-WebScaleDown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "900"
  statistic = "Average"
  threshold = "20"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_down.arn ]
}