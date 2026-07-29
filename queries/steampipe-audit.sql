-- 1. Buckets S3 com acesso público liberado ou sem bloqueio de acesso público
SELECT 
  name,
  region,
  block_public_acls,
  block_public_policy,
  ignore_public_acls,
  restrict_public_buckets
FROM 
  aws_s3_bucket;

-- 2. Grupos de Segurança com porta SSH (22) ou RDP (3389) aberta para a internet (0.0.0.0/0)
SELECT
  group_id,
  group_name,
  ip_protocol,
  from_port,
  to_port,
  cidr_ipv4
FROM
  aws_vpc_security_group_rule
WHERE
  type = 'ingress'
  AND cidr_ipv4 = '0.0.0.0/0'
  AND (
    from_port <= 22 AND to_port >= 22
    OR from_port <= 3389 AND to_port >= 3389
  );

-- 3. Instâncias EC2 em execução com IP Público associado
SELECT
  instance_id,
  instance_type,
  instance_state,
  public_ip_address,
  private_ip_address,
  vpc_id
FROM
  aws_ec2_instance
WHERE
  instance_state = 'running'
  AND public_ip_address IS NOT NULL;

-- 4. Chaves IAM de Acesso com mais de 90 dias de criação
SELECT
  user_name,
  access_key_id,
  status,
  create_date,
  date_part('day', now() - create_date) AS age_days
FROM
  aws_iam_access_key
WHERE
  date_part('day', now() - create_date) > 90;
