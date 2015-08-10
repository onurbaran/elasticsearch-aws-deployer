#!/bin/bash
# You need to configure a config server (eg. t2.micro type) with any web server and put this script your webservers root path.

#You must configure (1), (2), (3) and (3) parameters. Other params are optional for your deployment scenario.

INSTANCE_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`

sudo apt-get update
cd /opt
sudo wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.6.0.deb

sudo dpkg -i elasticsearch-1.6.0.deb

cd /usr/share/elasticsearch/bin/
sudo ./plugin -install royrusso/elasticsearch-HQ
sudo ./plugin install elasticsearch/elasticsearch-cloud-aws/2.6.0

sudo cp /etc/elasticsearch/elasticsearch.yml /home/ubuntu/elasticsearch.yml
sudo rm -rf /etc/elasticsearch/elasticsearch.yml

sudo echo "network.publish_host: $INSTANCE_IP" >> /home/ubuntu/elasticsearch.yml
sudo echo "cluster.name: your_cluster_name" >> /home/ubuntu/elasticsearch.yml      #(1)

sudo echo 'discovery.type: "ec2"' >> /home/ubuntu/elasticsearch.yml
sudo echo 'discovery.ec2.groups: "SG_Group_Elasticsearch"' >> /home/ubuntu/elasticsearch.yml   #(2)
sudo echo 'discovery.ec2.host_type: "private_ip"' >> /home/ubuntu/elasticsearch.yml
sudo echo 'discovery.ec2.ping_timeout: "30s"' >> /home/ubuntu/elasticsearch.yml
sudo echo 'discovery.ec2.availability_zones: ["eu-west-1a", "eu-west-1b", "eu-west-1c"]' >> /home/ubuntu/elasticsearch.yml
sudo echo 'cloud.aws.region: "eu-west"' >> /home/ubuntu/elasticsearch.yml                       # (4)
sudo echo 'discovery.zen.ping.multicast.enabled: false' >> /home/ubuntu/elasticsearch.yml
sudo echo 'discovery.ec2.tag.es_discover: true' >> /home/ubuntu/elasticsearch.yml
sudo echo 'discovery.zen.minimum_master_nodes: 1' >> /home/ubuntu/elasticsearch.yml
sudo echo 'index.translog.flush_threshold_ops: 50000' >> /home/ubuntu/elasticsearch.yml
sudo echo 'index.refresh_interval: 30s' >> /home/ubuntu/elasticsearch.yml
sudo echo 'indices.fielddata.cache.size: 10%' >> /home/ubuntu/elasticsearch.yml
sudo echo 'threadpool.search.type: cached' >> /home/ubuntu/elasticsearch.yml
sudo echo 'threadpool.bulk.type: fixed' >> /home/ubuntu/elasticsearch.yml
sudo echo 'threadpool.bulk.queue_size: 2000' >> /home/ubuntu/elasticsearch.yml

cd /home/ubuntu
ROLE=`aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=es_role" --region eu-west-1 --output=text | cut -f5`
NODE_NAME=$ROLE"_"$INSTANCE_IP
echo 'node.name:' $NODE_NAME >> /home/ubuntu/elasticsearch.yml

sudo cp elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

if [ "$ROLE" =  "master" ]
then
  sudo echo 'node.master: true' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo 'node.data: false' >> /etc/elasticsearch/elasticsearch.yml
  sudo sed -i 's,.*#ES_HEAP_SIZE.*,ES_HEAP_SIZE=2g,g' /etc/init.d/elasticsearch

elif [ "$ROLE" = "balancer"  ]
then
  sudo echo 'node.master: false' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo 'node.data: false' >> /etc/elasticsearch/elasticsearch.yml
  sudo sed -i 's,.*#ES_HEAP_SIZE.*,ES_HEAP_SIZE=2g,g' /etc/init.d/elasticsearch


elif [ "$ROLE" = "persister" ]
then
  sudo echo 'node.master: false' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo 'node.data: true' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo '"index.store.type": "mmapfs"' >> /etc/elasticsearch/elasticsearch.yml
  sudo sed -i 's,.*#ES_HEAP_SIZE.*,ES_HEAP_SIZE=4g,g' /etc/init.d/elasticsearch      # (3)
  sudo mkfs -t ext4 /dev/xvdf
  sudo mount /dev/xvdf /var/lib/elasticsearch/

elif [ "$ROLE" = "memory" ]
then
  sudo echo 'node.master: false' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo 'node.data: true' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo '"index.store.type": "memory"' >> /etc/elasticsearch/elasticsearch.yml
  sudo sed -i 's,.*#ES_HEAP_SIZE.*,ES_HEAP_SIZE=4g,g' /etc/init.d/elasticsearch      # (3)

else
  sudo echo 'node.master: false' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo 'node.data: true' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo 'node.data: true' >> /etc/elasticsearch/elasticsearch.yml
  sudo echo '"index.store.type": "mmapfs"' >> /etc/elasticsearch/elasticsearch.yml
  sudo sed -i 's,.*#ES_HEAP_SIZE.*,ES_HEAP_SIZE=2g,g' /etc/init.d/elasticsearch     # (3)

fi

sudo service elasticsearch start
