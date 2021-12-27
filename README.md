## AutoScaling

1. Clone the VPC branch of the AutoScaling repo in micky.

```git clone -b vpc https://mgtsys:ab8413bb85accdc0deab71b10e75a8e995d0c576@github.com/mgtsys/AutoScaling.git```

2. Now execute the vpc.sh script to create the VPC.

3. You will be asked to enter the following details.

    * Enter your AWS ACCESS KEY: 
    * Enter your AWS SECRET KEY: 
    * Enter your AWS Region: 
    * Enter your Project Name: 

4. The script will create the Following resources.

    * VPC
    * Subnets [Public, Private]
    * Internet Gateway
    * NAT Gateway
    * Route Table [Public, Private]

5. Wait for the script to complete.

6. Now, launch the instance from MGT Backend in the newly created VPC and proceed with setting up Admin and WebMaster servers.

7. Once the servers are up and running, you can proceed with the cloning the ASG branch of the AutoScaling repo in micky.

```git clone -b asg https://mgtsys:ab8413bb85accdc0deab71b10e75a8e995d0c576@github.com/mgtsys/AutoScaling.git```

7. Now execute the asg.sh script to create the ASG.

8. You will be asked to enter the same details as you did in step 3.

9. The script will create the following resources.

    * AMI
    * Load Balancer
    * Target Groups
    * Security Group
    * Health Check
    * Launch Configuration
    * Auto Scaling Group
    * CloudWatch Alarm

10. Wait for the script to complete.
