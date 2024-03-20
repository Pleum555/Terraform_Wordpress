terraform {
  required_providers {
    aws = {
    source = "hashicorp/aws"
    version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# Select Region
provider "aws" {
  region = var.region

}

# Create VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "public_subnet_wordpress" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.public_subnet1_cidr_block
  availability_zone = var.availability_zone
  # map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_wordpress"
  }
}
resource "aws_subnet" "public_subnet_nat" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.public_subnet2_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "public_subnet_nat"
  }
}
resource "aws_subnet" "private_subnet_connectdb" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.private_subnet1_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "private_subnet_connectdb"
  }
}
resource "aws_subnet" "private_subnet_connectnat" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.private_subnet2_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "private_subnet_connectnat"
  }
}

# Create Internet Gateway and attach to VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "igw"
  }
}

# Create ElasticIP of NAT AND Create NAT
resource "aws_eip" "eip-nat" {
  # vpc = true
  
  tags = {
    Name = "eip-nat"
  }
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip-nat.id
  subnet_id     = aws_subnet.public_subnet_nat.id

  tags = {
    Name = "nat"
  }
}

# Create Route Table
resource "aws_route_table" "public_wordpress_route_table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Word Press Route Table"
  }
}
resource "aws_route_table" "private_nat_route_table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Public NAT Route Table"
  }
}
resource "aws_route_table" "nat_to_igw_route_table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "nat_to_igw_route_table"
  }
}

# Associate route tables with subnets
resource "aws_route_table_association" "public_subnet_wordpress_association" {
  subnet_id      = aws_subnet.public_subnet_wordpress.id
  route_table_id = aws_route_table.public_wordpress_route_table.id
}
resource "aws_route_table_association" "private_subnet_connectnat_association" {
  subnet_id      = aws_subnet.private_subnet_connectnat.id
  route_table_id = aws_route_table.private_nat_route_table.id
}
resource "aws_route_table_association" "public_nat_association" {
  subnet_id      = aws_subnet.public_subnet_nat.id
  route_table_id = aws_route_table.nat_to_igw_route_table.id
}

# Create Security Group
resource "aws_security_group" "security_group_http" {
  name               = "security_group_http"
  description        = "Inbound traffic"
  vpc_id             = aws_vpc.my-vpc.id
  
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "security_group_Outbound_MYSQL" {
  name               = "security_group_Outbound_MYSQL"
  description        = "Outbound traffic"
  vpc_id             = aws_vpc.my-vpc.id

  egress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [var.private_subnet1_cidr_block]
  }

  egress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.private_subnet1_cidr_block]
  }

  # egress {
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "-1"
  #   cidr_blocks      = [var.private_subnet1_cidr_block]
  # }
}
resource "aws_security_group" "security_group_Inbound_MYSQL" {
  name               = "security_group_Inbound_MYSQL"
  description        = "Inbound traffic"
  vpc_id             = aws_vpc.my-vpc.id
  
  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [var.private_subnet1_cidr_block]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.private_subnet1_cidr_block]
  }

  # ingress {
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "-1"
  #   cidr_blocks      = [var.private_subnet1_cidr_block]
  # }
}
resource "aws_security_group" "security_group_connect_NAT" {
  name        = "security_group_connect_NAT"
  description = "Inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id
  
  # ingress {
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "-1"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

  # ingress {
  #   from_port        = 22
  #   to_port          = 22
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Create Network Interface
resource "aws_network_interface" "web-server-wordpress" {
  subnet_id       = aws_subnet.public_subnet_wordpress.id
  security_groups = [aws_security_group.security_group_http.id]
  # attachment {
  #   instance = "${aws_instance.test.id}"
  #   device_index = 1
  # }
}
resource "aws_network_interface" "connect-outbound" {
  subnet_id       = aws_subnet.private_subnet_connectdb.id
  security_groups = [aws_security_group.security_group_Outbound_MYSQL.id]
}
data "aws_network_interface" "connect-outbound" {
  id = aws_network_interface.connect-outbound.id
}
resource "aws_network_interface" "connect-inbound" {
  subnet_id       = aws_subnet.private_subnet_connectdb.id
  security_groups = [aws_security_group.security_group_Inbound_MYSQL.id]
}
data "aws_network_interface" "connect-inbound" {
  id = aws_network_interface.connect-inbound.id
}
resource "aws_network_interface" "connect-NAT" {
  subnet_id       = aws_subnet.private_subnet_connectnat.id
  security_groups = [aws_security_group.security_group_connect_NAT.id]
}

# Create Elastic IP of Web Client
resource "aws_eip" "eip-web" {
  network_interface           = aws_network_interface.web-server-wordpress.id
  depends_on                  = [aws_internet_gateway.igw]
}

# Create S3 Bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "${var.bucket_name}"
  force_destroy = true
}

# Control Ownership
resource "aws_s3_bucket_ownership_controls" "s3_controls" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "s3_public" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Policy of IAM
data "aws_iam_policy_document" "s3_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

# Create IAM User
resource "aws_iam_user" "s3_user" {
  name = "s3_user"
  path = "/"

  tags = {
    Name = "s3_user"
  }
}

# Create Access Key of IAM User
resource "aws_iam_access_key" "s3_access_key" {
  user = aws_iam_user.s3_user.name
}

# Attach Policy of IAM to IAM User
resource "aws_iam_user_policy" "s3_policy" {
  name   = "user_policy"
  user   = aws_iam_user.s3_user.name
  policy = data.aws_iam_policy_document.s3_policy_doc.json
}

# Public Key Pair for SSH
resource "aws_key_pair" "my_key_pair" {
  key_name   = "cloud-wordpress"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODaHqtrCOBpfD+meWggDG5gFEqnNDtpxnqQ7xWIfXfL"
}

# Create Instance
resource "aws_instance" "web-wordpress" {
  ami               = var.ami
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = aws_key_pair.my_key_pair.key_name

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-wordpress.id 
  }

  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.connect-outbound.id 
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              sudo apt update -y

              # Install PHP and Apache
              sudo apt install -y apache2 php8.1-mysql libapache2-mod-php
              sudo apt install -y php8.1-xml php8.1-curl php8.1-gd php8.1-imagick

              # Download and extract WordPress
              wget https://wordpress.org/latest.tar.gz
              tar -xzf latest.tar.gz

              # Configure WordPress
              cp wordpress/wp-config-sample.php wordpress/wp-config.php
              sed -i "s/'DB_NAME', '.*'/'DB_NAME', '${var.database_name}'/" wordpress/wp-config.php
              sed -i "s/'DB_USER', '.*'/'DB_USER', '${var.database_user}'/" wordpress/wp-config.php
              sed -i "s/'DB_PASSWORD', '.*'/'DB_PASSWORD', '${var.database_pass}'/" wordpress/wp-config.php
              sed -i "s/'DB_HOST', '.*'/'DB_HOST', '${data.aws_network_interface.connect-inbound.private_ip}'/" wordpress/wp-config.php

              # Download wp command
              wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
              chmod +x wp-cli.phar
              sudo mv wp-cli.phar /usr/local/bin/wp
              wp --info
              
              # Set wp-admin
              until wp core install --url="${aws_eip.eip-web.public_ip}" --path='wordpress' --allow-root --admin_user="${var.admin_user}" --admin_password="${var.admin_pass}" --admin_email="${var.admin_user}@gmail.com" --title="Cloud" --skip-email
              do
                sleep 10
              done

              sudo wp plugin install amazon-s3-and-cloudfront --path='wordpress' --allow-root --activate
              
              # copy and paste the following sed command to insert the temporary file you just created into the WordPress configuration file
              cat <<EOT >> credfile.txt
                define( 'AS3CF_SETTINGS', serialize( array(
                // Storage Provider ('aws', 'do', 'gcp')
                'provider' => 'aws',
                // Access Key ID for Storage Provider (aws and do only, replace '*')
                'access-key-id' => '${aws_iam_access_key.s3_access_key.id}',
                // Secret Access Key for Storage Providers (aws and do only, replace '*')
                'secret-access-key' => '${aws_iam_access_key.s3_access_key.secret}',
                // Bucket to upload files to
                'bucket' => '${var.bucket_name}',
                // Bucket region (e.g. 'us-west-1' - leave blank for default region)
                'region' => '${var.region}',
                // Automatically copy files to bucket on upload
                'copy-to-s3' => true,
                // Rewrite file URLs to bucket
                'serve-from-s3' => true,
                // Serve files over HTTPS
                'force-https' => false,
                // Remove the local file version once offloaded to bucket
                'remove-local-file' => false,
                // DEPRECATED (use enable-delivery-domain): Bucket URL format to use ('path', 'cloudfront')
                //'domain' => 'path',
                // DEPRECATED (use delivery-domain): Custom domain if 'domain' set to 'cloudfront'
                //'cloudfront' => 'cdn.exmple.com',
              ) ) );
              EOT

              sed -i "/define( 'WP_DEBUG', false );/r credfile.txt" wordpress/wp-config.php

              # Copy WordPress files to Apache's root directory
              sudo cp -r wordpress/* /var/www/html/
              sudo chown -R www-data:www-data /var/www/html/wp-content
              sudo chmod -R 755 /var/www/html/wp-content

              # Enable and start Apache service
              sudo systemctl start apache2
              sudo systemctl enable apache2
              sudo systemctl restart apache2
              exit
              EOF

  tags = {
    Name = "web-wordpress"
  }
}
resource "aws_instance" "mariaDB" {
  ami               = var.ami
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = aws_key_pair.my_key_pair.key_name

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.connect-NAT.id 
  }

  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.connect-inbound.id 
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              sudo apt update -y

              # Install MariaDB 10.6
              sudo apt install software-properties-common -y
              curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
              sudo bash mariadb_repo_setup --mariadb-server-version=10.6
              sudo apt install mariadb-server -y

              # Start and enable MariaDB
              sudo systemctl enable mariadb
              sudo systemctl start mariadb

              # Set MariaDB admin_user&admin_pass
              sudo mysqladmin -u root password 'password'

              # Access MariaDB
              echo "CREATE USER '${var.database_user}'@'${data.aws_network_interface.connect-outbound.private_ip}' IDENTIFIED BY '${var.database_pass}';" > create_user.sql
              echo "CREATE DATABASE ${var.database_name};" >> create_user.sql
              echo "GRANT ALL PRIVILEGES ON ${var.database_name}.* TO '${var.database_user}'@'${data.aws_network_interface.connect-outbound.private_ip}';" >> create_user.sql
              echo "FLUSH PRIVILEGES;" >> create_user.sql
              sudo mysql -u root -p'password' < create_user.sql
              sudo rm create_user.sql
              
              # bind address from 127.0.0.1 to 0.0.0.0
              sudo sed -i 's/bind-address            = 127.0.0.1/bind-address            = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
              sudo systemctl restart mariadb
              sudo systemctl enable mariadb
              
              EOF

  tags = {
    Name = "mariaDB"
  }
}

output "wordpress_admin_url" {
  value = "http://${aws_eip.eip-web.public_ip}/wp-admin"
}