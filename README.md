## AutoScaling


Note: To remove the infrastructure that you have created, just re-run the script and it will prompt you for destroying the infra that you created. Infra that already exists(not created by the script) cannot be destroyed by the script.


1. Clone the VPC branch of the AutoScaling repo in micky.

```git clone -b vpc https://mgtsys:ab8413bb85accdc0deab71b10e75a8e995d0c576@github.com/mgtsys/AutoScaling.git /home/mgt/AutoScaling/vpc```

2. Now execute the vpc.sh script to create the VPC.

```bash vpc.sh```

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

IMPORTANT: Make sure your instances are named in the following format ``Admin = "$projectname-admin"`` ``WebMaster = "$projectname-web-master"``

It is important for the script to detect the names in mentioned format to fetch the properties.

7. Once the servers are up and running, you can proceed with the cloning the ASG branch of the AutoScaling repo in micky.

```git clone -b asg https://mgtsys:ab8413bb85accdc0deab71b10e75a8e995d0c576@github.com/mgtsys/AutoScaling.git /home/mgt/AutoScaling/asg```

7. Now execute the asg.sh script to create the ASG.

```bash asg.sh```

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
