

AWS CLI equivalent:
$ export stack_suffix=seneca-5
$ export env=dev
$ cd ${GITS_DIR}/aurelius/elb_cluster/templates
$ aws cloudformation create-stack --stack-name elb-stack-${env}-${stack_suffix} --template-body file://./elb-cluster-cft-amznlnx.json --parameters ParameterKey=BaseName,ParameterValue=elb-stack ParameterKey=StackSuffix,ParameterValue=${stack_suffix}


### ECS Cluster facilities that I've created
In CFT in codebase:
- define a service: ml-ecs-service-cka694-12
- define a ECS cluster: ml-ecs-cluster-cka694-12

In CloudFormation Console:
- create a EC2 stack: ml-ecs-stack-cka694-12

In task-definition.json file:
- define a family: ml-ecs-family-cka694-12
- specify a name for each container: ml-container-cka694-12
- task role: c1-RetailBank-Dev-CustomRole-NSBC
- Account: GR_GG_COF_AWS_Retailbank_Dev_Developer

In ECS Console:
- create a Task Definition: ECS Console> "Task Definitions" tab > Create> Use JSON > copy & paste from codebase task-definition.json
- create a Service: ECS Console > Clusters tab > search for your cluster name > Go to your cluster > Services tab > Create
Task Definition: ml-ecs-family-12:1
Cluster
Service name: ml-ecs-service-cka694-12
- start the ECS Service
- ALB name: ml-ecs-alb-cka694-25
- Target Group: ml-ecs-target-group-cka694-25-2

In EC2:
- created an Application Load Balancer: ml-ecs-load-balancer-cka694-25-2



# USAGE - manual

## 0. [Codebase] Update names, versions, etc
- CFT: update cluster names and version numbers
- Task Definition: update cluster names and version numbers

## 1. [CloudFormation] Create a cluster
- Start a new Stack of EC2 instances using CFT.
ml-ecs-stack-cka694-xx

## 2. [EC2] Create an ALB
- Wait until the stack is created (you will add its instances to ALB's target group')
- Create an application load balancer. ml-ecs-alb-cka694-xx
    Internal
    Add Subnets based on CFT
    Add Security Group based on CFT
    Add Target Group
        Name: ml-ecs-tg-cka694-xx
        Protocol: HTTP
        Port: 80
        Target type: instance
        Register Targets based on the stack you just created.

## 3. [ECS] Create a Task Definition
- Define a new Task Definition
Configure via JSON. Use the template json file.
Task Role: c1-RetailBank-Dev-CustomRole-LevelECSMember
Network Mode: Bridge


## 4. [ECS] Create a Service
- Find the ECS Cluster that was just created by the CFT you ran above.

- Create a new Service in the ECS Cluster.
First page
    Task definition name: ml-ecs-family-cka694-xx
    Service name: ml-ecs-service-cka694-xx
    Number of Tasks: 3
Second page
    Application Load Balancer
        IAM Role: c1-RetailBank-Dev-CustomRole-AutobahnECSMember
        Name: choose the ALB you created above. ml-ecs-alb-cka694-xx
        Select a container > Add to ELB
        Listener Port: If you have added a new listener port on page 1, choose it here. Otherwise, choose the default HTTP:80 port.
        Target Group: choose the target group that you defined for te ALB. ml-ecs-tg-cka694-xx
Third Page
    Choose "Configure Service Autoscaling ..."
    Min number of tasks: 1
    Desired number of tasks: 2
    Max number of tasks: 5
    IAM Role: c1-RetailBank-Dev-CustomRole-jenkins
    Choose existing alarm or create new one.
    Specify alarm action
Fourth page:
    Review and create Service


## 5. [EC2, browser] Test the App
- Find the ALB's DNS
EC2 > Left Pane > Load Balancers
Find your load balancer and copy its DNS.

- Browse to the ALB endpoint.



# USAGE - automated
The JenkinsFile is the entry point for a deployment. It references the shell scripts that need to run to
- re-hydrate the cluster if necessary
- re-start the service

Also, management scripts.
