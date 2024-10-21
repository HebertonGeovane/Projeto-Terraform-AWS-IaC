variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "notification_email" {
  description = "Email address for SNS notifications"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true  # Para ocultar a senha em logs
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

# Configuração do provider AWS
provider "aws" {                        
  region     = "us-east-1"              
  access_key = var.aws_access_key  
  secret_key = var.aws_secret_key      
}

data "aws_availability_zones" "azs" {
  state = "available"
}

# Criar uma VPC com o nome "vpc_prod"
resource "aws_vpc" "vpc_prod" {  
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_prod"
  }
}

# Sub-rede pública A
resource "aws_subnet" "sub_ext_prod_a" {
  vpc_id            = aws_vpc.vpc_prod.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "sub_net_ext_prod_a"
  }
}

# Sub-rede pública B
resource "aws_subnet" "sub_ext_prod_b" {
  vpc_id            = aws_vpc.vpc_prod.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "sub_net_ext_prod_b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw_prd" {
  vpc_id = aws_vpc.vpc_prod.id               

  tags = {
    Name = "IGW_PRD"                         
  }
}

# Criação da tabela de rotas para sub-rede externa A
resource "aws_route_table" "external_route_table_a" { 
  vpc_id = aws_vpc.vpc_prod.id                     

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_prd.id  
  }

  tags = {
    Name = "tabela de roteamento externa_a"          
  }
}

# Criação da tabela de rotas para sub-rede externa B
resource "aws_route_table" "external_route_table_b" { 
  vpc_id = aws_vpc.vpc_prod.id   

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_prd.id  
  }

  tags = {
    Name = "tabela de roteamento externa_b"           
  }
}

# Associação da tabela de roteamento externo para sub-rede A
resource "aws_route_table_association" "roteamento_externo_a" {
  subnet_id      = aws_subnet.sub_ext_prod_a.id
  route_table_id = aws_route_table.external_route_table_a.id
}

# Associação da tabela de roteamento externo para sub-rede B
resource "aws_route_table_association" "roteamento_externo_b" {
  subnet_id      = aws_subnet.sub_ext_prod_b.id
  route_table_id = aws_route_table.external_route_table_b.id
}

# Criar um grupo de segurança para a VPC
resource "aws_security_group" "sg_prod" {
  vpc_id = aws_vpc.vpc_prod.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Ajuste conforme necessário
  }

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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_prod"
  }
}

# Criar um Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_prod.id]
  subnets            = [aws_subnet.sub_ext_prod_a.id, aws_subnet.sub_ext_prod_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "AppLoadBalancer"
  }
}

# Criar um Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_prod.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name = "AppTargetGroup"
  }
}

# Criar uma Listener para o Load Balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Adicionar as instâncias EC2 ao Target Group
resource "aws_lb_target_group_attachment" "instance_a_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.instance_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance_b_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.instance_b.id
  port             = 80
}

# Criar um SNS Topic para notificações do Load Balancer
resource "aws_sns_topic" "lb_notifications" {
  name = "lb_notifications"

  tags = {
    Name = "LoadBalancerNotifications"
  }
}

# Criar uma assinatura do SNS para enviar notificações por e-mail
resource "aws_sns_topic_subscription" "lb_email_subscription" {
  topic_arn = aws_sns_topic.lb_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email  # Email que receberá as notificações
}



resource "aws_instance" "instance_a" {
 ami                    = "ami-0866a3c8686eaeeba"  # ID da AMI
 instance_type         = "t2.micro"                 # Tipo da instância
 subnet_id             = aws_subnet.sub_ext_prod_a.id
 key_name              = "chave1"                   # Nome do par de chaves


 security_groups       = [aws_security_group.sg_prod.id]
  associate_public_ip_address = true                  # Adicionando IP público
 tags = {
   Name = "Instance-A"
 }
}


resource "aws_instance" "instance_b" {
 ami                    = "ami-0866a3c8686eaeeba"  # ID da AMI
 instance_type         = "t2.micro"                 # Tipo da instância
 subnet_id             = aws_subnet.sub_ext_prod_b.id
 key_name              = "chave1"                   # Nome do par de chaves


 security_groups       = [aws_security_group.sg_prod.id]
  associate_public_ip_address = true                  # Adicionando IP público
 tags = {
   Name = "Instance-B"
 }
}


 #Criar o Launch Template
resource "aws_launch_template" "app_launch_template" {
  name          = "app-launch-template"
  image_id     = "ami-0866a3c8686eaeeba"  # ID da AMI
  instance_type = "t2.micro"               # Tipo da instância
  key_name      = "chave1"                 # Nome do par de chaves

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.sg_prod.id]  # Grupo de segurança
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}



# Configuração do Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1

  vpc_zone_identifier = [aws_subnet.sub_ext_prod_a.id, aws_subnet.sub_ext_prod_b.id]

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }
  health_check_type          = "EC2"
  health_check_grace_period = 300
}

# SNS Topic para notificações
resource "aws_sns_topic" "asg_notifications" {
  name = "asg_notifications"

  tags = {
    Name = "ASG Notifications"
  }
}

resource "aws_sns_topic_subscription" "asg_email_subscription" {
  topic_arn = aws_sns_topic.asg_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email  # O e-mail que receberá as notificações
}

# Alarmes CloudWatch
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "70"
  
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "30"
  
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

# Políticas de Auto Scaling
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  scaling_adjustment      = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  scaling_adjustment      = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# Sub-rede privada A (RDS Master)
resource "aws_subnet" "sub_int_prod_a" {
  vpc_id            = aws_vpc.vpc_prod.id
  cidr_block        = "10.0.11.0/24"    # Bloco CIDR para a sub-rede A
  availability_zone = "us-east-1a"      # Zona de Disponibilidade A
  
  tags = {
    Name = "sub_net_int_prod_a"         # Tag para identificação
  }
}

# Sub-rede privada B (RDS Multi-AZ)
resource "aws_subnet" "sub_int_prod_b" {
  vpc_id            = aws_vpc.vpc_prod.id
  cidr_block        = "10.0.12.0/24"    # Bloco CIDR para a sub-rede B (diferente da A)
  availability_zone = "us-east-1b"      # Zona de Disponibilidade B
  
  tags = {
    Name = "sub_net_int_prod_b"         # Tag para identificação
  }
}

# (Opcional) Criação de uma tabela de rotas para as sub-redes privadas
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_prod.id
  
  tags = {
    Name = "private_route_table"
  }
}

# Associação das sub-rede privadas à tabela de rotas
resource "aws_route_table_association" "private_route_association_a" {
  subnet_id      = aws_subnet.sub_int_prod_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_association_b" {
  subnet_id      = aws_subnet.sub_int_prod_b.id
  route_table_id = aws_route_table.private_route_table.id
}

# Criar um grupo de sub-rede para o RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.sub_int_prod_a.id, aws_subnet.sub_int_prod_b.id]  # As sub-redes privadas que você criou
  tags = {
    Name = "RDS Subnet Group"
  }
}


# Criar o grupo de segurança para o RDS
resource "aws_security_group" "rds_access" {
  vpc_id = aws_vpc.vpc_prod.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_prod.id]  # Permitir acesso apenas das instâncias EC2
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_access"
  }
}

# RDS Master na AZ A
resource "aws_db_instance" "database_master" {
  identifier             = "database-master"
  engine                 = "mysql"
  engine_version         = "8.0"  # Altere conforme necessário
  instance_class         = "db.t4g.micro"
  allocated_storage       = 20
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  skip_final_snapshot    = true
  vpc_security_group_ids  = [aws_security_group.rds_access.id]  # Grupo de segurança do RDS
  publicly_accessible     = false  # Não acessível publicamente
  availability_zone       = "us-east-1a"  # AZ A
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  tags = {
    Name = "MyDatabaseMaster"
  }
}

# RDS Multi-AZ na AZ B
resource "aws_db_instance" "database_multi_az" {
  identifier             = "database-multi-az"
  engine                 = "mysql"
  engine_version         = "8.0"  # Altere conforme necessário
  instance_class         = "db.t4g.micro"
  allocated_storage       = 20
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  skip_final_snapshot    = true
  vpc_security_group_ids  = [aws_security_group.rds_access.id]  # Grupo de segurança do RDS
  publicly_accessible     = false  # Não acessível publicamente
  multi_az               = true  # Ativar Multi-AZ
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  tags = {
    Name = "MyDatabaseMultiAZ"
  }
}

#criar buckets3
resource "aws_s3_bucket" "californiabucket" {
  bucket = "californiabucket"

  tags = {
    Name        = "californiabucket"
    Environment = "Dev"
  }
}

