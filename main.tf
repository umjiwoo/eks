#  1. EKS Cluster IAM Role

resource "aws_iam_role" "eks_cluster_iam_role" {  # policy 설정 전 role 선생성
  name = "eks-cluster-iam-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# 2. IAM Role policy 

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {   # role에 policy 설정
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_iam_role.name
}

# 3. EKS Cluster

resource "aws_eks_cluster" "my_eks_cluster" {
  name     = "jiwoo-eks-cluster"
  role_arn =  aws_iam_role.eks_cluster_iam_role.arn 
  version = "1.29"
  vpc_config {
    security_group_ids = [data.aws_security_group.my_sg_web.id]     #data.aws_security_group.my_sg_web -> data.tf 에서 정의한 내용   
    subnet_ids         = concat(data.aws_subnet.my_pvt_2a[*].id, data.aws_subnet.my_pvt_2c[*].id) # 두 개 이상 배열 결합, [*]는 해당 데이터 소스로부터 반환된 모든 요소를 나열하도록 Terraform에 지시합니다.
    endpoint_private_access = true # 동일 vpc 내 private ip간 통신허용
    endpoint_public_access = true 
   }
  }


# 노드 그룹에 부여할 Role 생성 & 해당 Role에 정책 할당
# 4. Node Group IAM Role

resource "aws_iam_role" "eks_node_iam_role" {
  name = "jiwoo-eks-node-iam-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


# iam role policy

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_iam_role.name
}

# 5. EKS Node Group

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.my_eks_cluster.name
  node_group_name = "worker-node-group"
  node_role_arn   = aws_iam_role.eks_node_iam_role.arn
  subnet_ids      = concat(data.aws_subnet.my_pvt_2a[*].id, data.aws_subnet.my_pvt_2c[*].id)  
  #concat->두 개 이상의 배열 결합/[*]->데이터 소스로부터 반환된 모든 요소 나열
  instance_types = ["t2.micro"]
  capacity_type  = "ON_DEMAND"   
  #최근 노드그룹 생성 시 Spot 방식 사용 多
  #(경매에 넘어가 실행중이던 컨테이너가 제거된다고 해도 auto scailing을 통해 또 다른 spot instance에 컨테이너를 띄우면 
  remote_access {
    ec2_ssh_key = "jiwoo-key"
  }
  labels = {
    "role" = "eks_node_iam_role"
  }
  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
    }
  tags = {
    Name = "jiwoo-worker"
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

