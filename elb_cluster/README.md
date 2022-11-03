
# Stack
"Stack" is simply the name that CloudFormation gives to the
collection of services and items that it creates for you.
The name "stack" has no computational, network, or server connotations.
It is just the name that CF gives to a collection or group of items.

The names "cluster" and "service" have computational and network meanings.

Cluster is the collection of physical remote machines (EC2 instances) that
host the application.
Service is an AWS term referring to a logical system that connects
a number of individual EC2 instances, each running one instance
of the application. Service is in charge of making sure the app
maintains a consistent level of service.


## ecs-cluster vs ecs-service
- cluster directory includes the scripts to get the physical cluster up and running. It needs to be run once.
- service directory includes the scripts to update the service. It is executed periodically and also
as a result of triggers that listen for model updates (i.e., new uploads to the model pickle file on S3).

- The “ecs-cluster” directory contains the infrastructure for the ASG and ecs-cluster.
- "ecs-service" directory contains the infrastructure to deploy a Service into an existing cluster.
- Cluster deployment will happen less frequently than the service deployment and many services can be deployed to a single cluster.
- “ecs-service” does not reference any scripts in “ecs-cluster”.

You can safely remove the “ecs-cluster” directory and redeploy the service.
- the two directories should not refer each other's code;
i.e., they should be totally independent.
Make sure that this is the case in the codebase.
Remove any cross-references and clean up.


- the settings for task definitions and clusters are stored in a yaml file:
aurelius/ecs-cluster/management-scripts/service-settings.yml

- clusters and tasks are spun up using AWS CLI, which also has a python package. So, instead of running the AWS CLI code from the Terminal, we run it from within python.
The python code reads task definitions and other arguments for cluster setup from the yaml file.
aurelius/ecs-cluster/management-scripts/create-cluster.py


## Non-dockerized deployment
The "elb" directory contains scripts to start the server without docker and containerization.



### Resources: cluster vs service
elb has the following resources:
    AWS::CloudFormation::Stack  >>  always part of this
    AWS::ECS::Cluster  >>  probably not needed
    AWS::AutoScaling::LaunchConfiguration  >>  Every autoscaling group needs a launch config so that it knows what operations to perform when spnning up a new instance.
    AWS::AutoScaling::AutoScalingGroup  >>  The ASG itself
    AWS::ElasticLoadBalancing::LoadBalancer  >>  Load balancer


ecs-cluster has the following resources:
    AWS::ECS::Cluster
    AWS::AutoScaling::AutoScalingGroup
    AWS::AutoScaling::LaunchConfiguration

ecs-service has the following resources:
    AWS::ElasticLoadBalancingV2::LoadBalancer
    AWS::ElasticLoadBalancingV2::Listener
    AWS::ElasticLoadBalancingV2::ListenerRule
    AWS::ElasticLoadBalancingV2::TargetGroup
    AWS::ECS::TaskDefinition
    AWS::ECS::Service


Full reference for CloudFormation resources,
including what parameters are available for each resource:
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html


### Naming convention
{base_name}-{resource_type}-{environment}-{suffix}

See below for an explanation of how AWS assigns names to resources.
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-name.html
You can also see which resources support adding a name to them.
For example, we cannot assign a name to ASG resources.

logical-id vs physical-id:
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html

