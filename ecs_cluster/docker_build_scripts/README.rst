
#############
Summary
#############
This dir contains scripts to create docker image,
update docker image, or start the dockerized app.
These scripts are meant for manual execution on the cluster.
To run these script, use the template "elb-cluster-...", not "ecs-cluster-...".
The "ecs-cluster-..." script already includes these instructions in its UserData section.

- To create a new image and push it to Dockyard: "01_create_image.sh"
- To update an existing image after changing the dockerfile: "02_update_image.sh"
- To see if the docker container can be started properly: "03_start_app"

For a live app, all we need is to keep the most updated docker image on Dockyard.
When we start an ECS service, the task definition pulls the docker image from dockyard and
automatically runs it on the cluster for us.


############
USAGE
############
The entry points are:

=======================
$ 01_install_docker.sh
=======================
Installs docker from yum.
Starts docker as a daemon.


=========================
$ 02_configure_docker.sh
=========================
Adds configuration settings to docker config file.
Restarts docker for the new configs to take effect.


=======================
$ 03_create_image.sh
=======================
Build a new image from Dockerfile and push it to dockyard registry.
Accepts version number as an argument.


=======================
$ 04_update_image.sh
=======================
Commits changes to an existing image on dockyard registry.
Run after changing the instance, but not changing the dockerfile.
This is only recommended for testing and dev situations where
we dont want to change the DockerFile yet.

Once we are done with dev work and ready to commit our changes,
we should update the DockerFile and
run 03_create_image.sh instead of 04_update_image.sh


=======================
$ 05_start_app.sh
=======================
Pulls the container from dockyard and runs it to start the app.


###########
Debugging
###########

===================
Test app
===================
# Browse to <instance_ip>:5000
# Browse to <instance_ip>:5000/bounce/good%20morning%20sunshine


===================
Test docker images
===================
# SSH into the EC2 instance, then SSH into the docker container:
$ ssh -i ~/.credentials/BBS_KP.pem ec2-user@<ec2_instance_ip>
$ sudo docker exec -t -i <container_id> /bin/bash

$ vi /etc/sysconfig/docker

# See the list of docker images
$ cd /var/lib/docker


===================
Debug Dockerfile
===================
$ sudo su
$ cd /opt/gits/aurelius/ecs-cluster/dockerfile/
$ vi dockerfile
$ docker build --no-cache -t seneca-img -f dockerfile .


===================
Test EC2 instance
===================
### Read bootstrap logs
sudo vi /var/log/user-data.log


========================
Monitoring and logging
========================
If you need to know the value of a variable, store it in a text file.
Each docker instructions runs in a new shell,
so variables from one instruction are not available to another instruction.
The only way to use variables from one instruction in another is to use ENV instruction.


####################
Docker cheat sheet
####################

------------------
Images
------------------
# see the list of existing images
$ sudo docker images

# remove an image
$ sudo docker rmi d0b41c341127

# remove a container
$ sudo docker rm d0b41c341127

# build a container from an image
$ sudo docker build
$ sudo docker build -t seneca-image-3 -f dockerfile .

# create a new image from a container's changes
$ $ docker commit -m "ready for testing" <container_id> seneca/seneca-api:v1.1

# Remove an image
$ sudo docker rmi <image_name>


------------------
Containers
------------------
# see the list of containers
$ sudo docker ps

### To start a new docker container in the background and not SSH into it:
$ sudo docker run -d -p 8081:80 --name=seneca-cont seneca-image

# run a command in a container
# for instance, we can start the API inside the container. Parameter -w sets the working directory inside the container.
$ sudo docker run -d -w /home/sinatra -p 10001:4567 seneca/seneca:v1.1 ./run_app.sh

# restart a container
$ sudo docker restart <container id>

# to see docker containers
$ sudo su
$ cd /var/lib/docker

### To SSH into a running container
sudo docker exec -it <cont_id> /bin/bash


------------------
Docker service
------------------
### List images and containers:
List active containers:
$ docker ps
List all containers (stopped and active)
docker ps -a

# to see docker settings
$ sudo docker info

# to change docker settings
$ vi /etc/sysconfig/docker

# restart docker service
$ sudo systemctl start docker.service

# to remove a container
$ sudo docker rm <container_name>


------------------
Registry
------------------
# create a new container
$ sudo docker create

# pull an image from a registry
$ sudo docker pull <address to the image on the registry>

# push an image to a registry
$ sudo docker push <>


#######################
Writing the DockerFile
#######################
We need either a DockerFile or a base image to start a container from scratch.
Using a DockerFile is strongly recommended,
because even if we use a completely neutral base image (say, RHEL base image),
there is always the chance that something goes wrong and we lose our initial container.
