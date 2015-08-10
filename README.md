# elasticsearch-aws-deployer
elasticsearch deployer for aws with asg dynamics. 

Deploys an elasticsearch cluster on aws with autoscale-groups. 

You need a configuration server for setup and configure your elasticsearch cluster. So you must launch an elasticsearch-manager server. 

### EC2 Types ( off course change for your elasticsearch usage )  : 

ConfigurationServer : t2.micro

elasticsearch node types : 

Master              : t2.medium

Balancer            : t2.medium

Persister           : m4.large

MemoryBased         : m4.large

#### Configure & Prepare Security Groups (1) : 
Create new security-group named "SG_Group_Elasticsearch"
Allow inbound traffic for 9200 HTTP. 
Allow internet access with your aws env. (using NAT or etc)
And you can configure about your aws restrictions and rules. 

#### Launching ConfigurationServer (2) : 

You can choose ubuntu general ami for this. You must install apache webserver for accessing other nodes to download deploy.sh. Your master, balancer, persister and memory nodes can access this ec2 with http(80) port. So you must configure your security-groups with this option. * You must change deploy.sh for your aws region. 

### Prepare A Generic AMI (3) : 

Launch a temp. ec2 with ubuntu image. Install java, jdk & aws-ec2 cli. 
    
      AMI Configurations : 
          # Edit /etc/security/limits.conf  for managing open file descriptors : 
                  root soft nofile 65536
                  root hard nofile 65536
                  * soft nofile 65536
                  * hard nofile 65536
          
          # Edit and paste at the end of file /etc/sysctl.conf for recyle tcp sockets. (This params solves TCP_TIME_WAIT problem) : 
                  
                net.ipv4.tcp_tw_recycle = 1
                net.ipv4.tcp_tw_reuse = 1
                net.ipv4.ip_local_port_range = 10240    65535
                
                
After setting this configs, you can create an ami-image for your elasticsearch cluster. 

### Setting IAM_ROLE (4) : 

Create a new iam_role or use your existing with full ec2-describe permission.


### Configure Launch Configs (5) : 

You must create launch configs with settings below for each elasticsearch node types.

Master, balancer and memory  configs for all elasticsearch-node-types : 

1. Choose your ec2-instance type for your elasticsearch-node-type
2. Select your general-ami (3)
3. Select security-group which is you created for your elasticsearch cluster. (1)
4. Select iam role which is you created for your elasticsearch cluster (4)
5. Put launch_config_user_data.sh to launch config's user_data area

Persister configs : 

Create launch config with settings above. And Attach EBS with /sdf device.

#### Create AutoScaleGroups : 

Create AutoScaleGroups for each launch config, you created (5)

    General EC2 Tag Configuration : 
            You must set es_discover = True for your all elasticsearch nodes when you create autoscaling groups.
    
    MasterNode EC2 Tags : 
            You must set es_role = master for your all elasticsearch nodes when you create balancer autoscaling group.

    BalancerNode EC2 Tags : 
            You must set es_role = balancer for your all elasticsearch nodes when you create balancer autoscaling group.
            
    PersisterNode EC2 Tags : 
            You must set es_role = persister for your all elasticsearch nodes when you create persister autoscaling group.
    
    MemoryNode EC2 Tags : 
            You must set es_role = memory for your all elasticsearch nodes when you create memory autoscaling group.
            
            
            
  @TODOS : 
  
      * Auto Create generic ami. 
      * Use configuration server more efficently for auto create lauch-config, asg etc. 
            
            
            
  











