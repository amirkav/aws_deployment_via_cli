

These scripts are meant for manual execution.
To run these script, use the template "elb-cluster-...", not "ecs-cluster-...".
The "ecs-cluster-..." script already includes these instructions in its UserData section.

$ cd ${GITS_DIR}/aurelius/ecs-cluster/docker_build_scripts/amznlnx
$ sudo su
$ ./01_install_docker.sh
$ # ./02_configure_docker.sh  # we need to run these instructions by hand to avoid double "sudo su" shells
$ ./03_create_push_image.sh 1.3


###########
Debugging
###########
$ systemctl status docker.ecs-service


====================
Verify installation
====================
$ sudo su
$ cd /var/lib/docker

# # to see a list of containers:
$ cd /var/lib/docker/containers


###########
Resources
###########
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html
