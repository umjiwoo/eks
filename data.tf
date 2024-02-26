
data "aws_vpc" "my_vpc" { 
  tags = {
    Name = "my-vpc" 
  }
}
data "aws_subnet" "my_pub_2a" {
  tags = {
    Name = "my-pub-2a" # 태그
  }
}
data "aws_subnet" "my_pub_2c" {
  tags = {
    Name = "my-pub-2c"
  }
}
data "aws_subnet" "my_pvt_2a" {
  tags = {
    Name = "my-pvt-2a"
  }
}
data "aws_subnet" "my_pvt_2c" {
  tags = {
    Name = "my-pvt-2c"
  }
}

data "aws_security_group" "my_sg_web" {
  name   = "my-sg-web"
}