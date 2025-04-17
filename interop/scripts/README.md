# Scripts for Spinning up AWS instances

This folder contains a set of scripts for spinning up the AWS instances needed to run the interop tests with the respective SDKs, it's very important that you tear these down as this can get expensive.


```bash
aws ec2 describe-instances --instance-ids $INSTANCE_IDS --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
```

```bash
ssh -i atoma-key.pem -o StrictHostKeyChecking=no ubuntu@$AWS_INSTANCE_IP
```

```bash
 sudo docker exec -it atoma-proxy-db-1 psql -U atoma -d atoma
 ```