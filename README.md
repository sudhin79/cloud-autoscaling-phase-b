# 🚀 Phase B — AWS Auto Scaling, CloudWatch Monitoring & SNS Alerts (Terraform)

This repository contains **Phase-B** of the Lift-and-Shift Cloud Automation Assignment.  
The goal of Phase-B is to extend the application deployed in Phase-A by adding:

- Auto Scaling Group  
- CPU-based and Memory-based scaling  
- CloudWatch custom metrics  
- CloudWatch alarms  
- SNS notifications  
- Load-testing script to simulate spikes  

All infrastructure is automated using **Terraform**.

---

# 📌 **Architecture Overview (Phase B)**

The following components are implemented:

### **1. Launch Template**
- Custom AMI + instance type  
- User-data script to:
  - Install Java 17  
  - Download app JAR from S3  
  - Start Spring Boot app  
  - Install & start CloudWatch Agent (for memory metrics)

### **2. Auto Scaling Group**
- Min = **1**, Max = **10**
- Uses Launch Template
- Application Load Balancer distributes traffic
- Automatically replaces unhealthy instances

### **3. Scaling Policies**
#### **CPU Target Tracking**
- Scales out when **CPU > 30%**
- Scales in when CPU falls below threshold

#### **Memory Target Tracking** (Custom CloudWatch Metric)
- Uses CloudWatch Agent to push:
  ```
  mem_used_percent
  ```
- Scales out when **Memory > 5%**

### **4. CloudWatch Monitoring**
- EC2 StatusCheckFailed alarm  
- Memory usage metric from CWAgent  
- CPU utilization  
- Scaling metrics  
- Alarm actions integrated with SNS

### **5. SNS Notifications**
SNS topic is configured to send email alerts for:
- EC2 instance failure  
- Scaling (instance launch/termination)  
- CloudWatch alarm state changes  

### **6. Load Test Script**
A lightweight script (`loadtest-light.sh`) sends repeated HTTP requests to ALB to simulate traffic and trigger scaling.

---

# 📁 **Project Structure**

```
phase-b/
│
├── main.tf                     # Providers, networking, ALB, target group
├── launch_template.tf          # EC2 launch template + user-data
├── asg.tf                      # Auto Scaling Group config
├── autoscaling-policies.tf     # CPU & Memory scaling policies
├── iam.tf                      # IAM roles & policies (S3 + CloudWatch + SNS)
├── cloudwatch-alarms.tf        # CloudWatch alarms integrated with SNS
├── variables.tf                # Variable definitions
├── terraform.tfvars            # Variable values (AMI, subnet IDs, SG, etc.)
│
├── user-data-phaseb.sh         # EC2 startup automation script
├── loadtest-light.sh           # On-demand load generator script
│
└── docs/
     └── screenshots/
         └── phase-b-slide.pdf  # Assignment diagram (Phase B)
```

---

# ⚙️ **How to Deploy (Terraform)**

### **1️⃣ Initialize**
```
terraform init
```

### **2️⃣ Validate**
```
terraform validate
```

### **3️⃣ Apply**
```
terraform apply -auto-approve
```

Infrastructure created:
- Launch Template  
- Auto Scaling Group  
- Target Tracking Scaling Policies  
- CloudWatch Alarms  
- SNS Notifications  
- Application Load Balancer  

---

# 🧪 **How to Generate Load (Trigger Scaling)**

Run this from **Git Bash** (Windows) or any Linux terminal:

```
./loadtest-light.sh
```

This script:
- Sends 300 requests to your ALB  
- Increases CPU and memory  
- Triggers Auto Scaling to launch new instances  

Watch scaling here:
```
AWS Console → EC2 → Auto Scaling Groups → Instances
```

---

# 🔔 **SNS Notifications**

SNS sends email alerts for:
- EC2 instance became unhealthy  
- Scaling event triggered (instance launched/terminated)  
- CloudWatch alarm state changed  

Make sure your email subscription is **Confirmed**.

---

# 📊 **CloudWatch Metrics**

Metrics visible under:
```
CloudWatch → Metrics → CWAgent → mem_used_percent
CloudWatch → Metrics → EC2 → CPUUtilization
CloudWatch → Alarms
```

---

# 🎯 **Phase-B Deliverables Completed**

✔ Auto Scaling Group  
✔ Launch Template with user-data  
✔ CPU scaling policy (>30%)  
✔ Memory scaling policy (>5%)  
✔ CloudWatch custom metric  
✔ CloudWatch alarms  
✔ SNS alerts  
✔ Load test script  
✔ Terraform automation  
✔ Assignment diagram included  
✔ Repository structured cleanly  
✔ Ready for PR submission  

---

# 📧 **Author**
**Sudhin Swain**  
sudhinnirmalswain@gmail.com

