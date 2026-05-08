provider "aws" {
  region = "ap-northeast-1"
}

# セキュリティグループを作成（SSH許可）
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH"

  # インバウンド (外から中)のルール
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # 全てのIPアドレスから接続OK
  }

  # アウトバンドルール　中から外へ
  # EC2から外部への通信は全て自由
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# EC2インスタンス
resource "aws_instance" "web" {
  ami                    = "ami-0a0b7b240264a48d7"  # Amazon Linux 2023
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "terraform-test"
  }
}

# 出力（パブリックIP）
output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "EC2のパブリックIPアドレス"
}
