resource "aws_vpc" "chatbot_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = { Name =  "chatbot_vpc" }
}

resource "aws_subnet" "chatbot_subnet" {
    count = 2
    vpc_id = aws_vpc.chatbot_vpc.id
    cidr_block = cidrsubnet(aws_vpc.chatbot_vpc.cidr_block, 8, count.index)

    availability_zone = element(["ap-south-1a", "ap-south-1b"], count.index)
    map_public_ip_on_launch = true

    tags = { Name = "chatbot-sub-${count.index}" }
}

resource "aws_internet_gateway" "chatbot_igw" {
    vpc_id = aws_vpc.chatbot_vpc.id

    tags = { Name = "chatbot-igw" }
}

resource "aws_route_table" "chatbot_rt" {
    vpc_id = aws_vpc.chatbot_vpc.id

    route {
        cidr_block =  "0.0.0.0/0"
        gateway_id = aws_internet_gateway.chatbot_igw.id
    }

    tags = { Name = "chatbot-rt" }
}

resource "aws_route_table_association" "chatbot_rta" {
    count = 2
    subnet_id = aws_subnet.chatbot_subnet[count.index].id
    route_table_id = aws_route_table.chatbot_rt.id
}