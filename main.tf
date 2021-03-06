resource "aws_vpc" "testvpc" {
    cidr_block = var.test_cidr

    tags = {
      "Name" = "test"
    }
  
}

resource "aws_subnet" "subnets" {
   
   count = length(var.test_subnet_azs)

   cidr_block = cidrsubnet(var.test_cidr, 8, count.index)
   availability_zone = var.test_subnet_azs[count.index]
   tags = {
      "Name" = var.test_subnet_tags[count.index]
    }
    vpc_id = aws_vpc.testvpc.id

    depends_on = [
      aws_vpc.testvpc
    ]
  
}


resource "aws_internet_gateway" "testigw" {
  vpc_id = aws_vpc.testvpc.id

  tags = {
    "Name" = "test-igw"
  }

  depends_on = [
    aws_vpc.testvpc
  ]
  
}


resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.testvpc.id
  route = [ ]
  
  tags = {
    "Name" = "test-publicrt"
  }

  depends_on = [
    aws_vpc.testvpc,
    aws_subnet.subnets  
  ]
}

resource "aws_route" "publicroute" {
  route_table_id = aws_route_table.publicrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.testigw.id
}

resource "aws_route_table_association" "publicrtassociations" {
  count = length(var.web_subnet_indexes)
  subnet_id = aws_subnet.subnets[var.web_subnet_indexes[count.index]].id
  route_table_id = aws_route_table.publicrt.id
}

resource "aws_security_group" "websg" {
  name = "openhttp"
  description = "Open http and ssh"
  vpc_id = aws_vpc.testvpc.id

  tags = {
    "Name" = "Openhttp"
  }
  depends_on = [
    aws_vpc.testvpc,
    aws_subnet.subnets,
    aws_route_table.publicrt,
    aws_route_table.testprivatert
  ]

}

resource "aws_security_group_rule" "websghttp" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.websg.id
  
  
}

resource "aws_security_group_rule" "websgssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.websg.id

  
  
}

resource "aws_instance" "webserver1" {
  ami = "ami-0c1a7f89451184c8b" 
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.subnets[0].id
  key_name = "continuousintegration"

  depends_on = [
    aws_vpc.testvpc,
    aws_subnet.subnets,
    aws_security_group.websg,
    aws_route_table.publicrt

  ]
  
}

resource "aws_route_table" "testprivatert" {
  vpc_id = aws_vpc.testvpc.id
  route = [ ]
  
  tags = {
    "Name" = "test-privatert"
  }
  
}

resource "aws_route_table_association" "privatertassociations" {
  count = length(var.other_subnet_indexes)
  subnet_id = aws_subnet.subnets[var.other_subnet_indexes[count.index]].id
  route_table_id = aws_route_table.testprivatert.id

  depends_on = [
    aws_subnet.subnets,
    aws_route_table.testprivatert
  ]
}