#!/bin/bash

# Don't stop on error — prevents system boot failure
set +e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

yum update -y || echo "YUM update failed"
yum install -y java-17-amazon-corretto awscli unzip amazon-cloudwatch-agent || echo "Package install failed"

mkdir -p /opt/myapp
cd /opt/myapp

echo "Downloading JAR from S3..."
for i in {1..10}; do
  aws s3 cp s3://my-app-bucket-sudhin-project-2025/hellomvc-0.0.1-SNAPSHOT.jar app.jar && break
  echo "Retrying S3 download..."
  sleep 5
done

if [ ! -f "/opt/myapp/app.jar" ]; then
  echo "JAR file missing — cannot start application" 
else
  echo "Creating systemd service..."
  cat >/etc/systemd/system/myapp.service << 'EOF'
[Unit]
Description=My Spring Boot Application
After=network.target

[Service]
ExecStart=/usr/bin/java -jar /opt/myapp/app.jar
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable myapp.service
  systemctl start myapp.service || echo "App failed to start"
fi

echo "Configuring CloudWatch Agent..."

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s || echo "CWAgent start failed"
