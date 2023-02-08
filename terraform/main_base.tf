module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tf-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
    Name = "tf-vpc"
  }
}

resource "aws_security_group" "lb-sg" {
  name = "app-lb-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "app-lb" {
  name = "app-lb"
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets
  security_groups = ["${aws_security_group.lb-sg.id}"]
}

resource "aws_lb_target_group" "app-tg" {
  name = "app-tg"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = module.vpc.vpc_id
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}


resource "aws_lb_listener" "app-lb-l" {
  port = 80
  protocol = "HTTP"
  load_balancer_arn = aws_alb.app-lb.arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app-tg.arn
  }
}