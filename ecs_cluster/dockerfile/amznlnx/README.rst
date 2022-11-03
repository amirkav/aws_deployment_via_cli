
docker pull amazonlinux:2017.12.0.20171212.2

About Amazon Linux 2:
https://hub.docker.com/_/amazonlinux/
https://github.com/aws/amazon-linux-docker-images/tree/2017.12
https://cloudonaut.io/migrating-to-amazon-linux-2/


#############################################
Running services inside a docker container
#############################################
Docker runs each RUN command in a new shell, so processes
that start in one RUN command do not make it to the next command.
That means if we start a process like httpd or awslogsd in a RUN
command, by the time the dockerfile finishes execution, the
process is stopped.

https://stackoverflow.com/questions/28212380/why-docker-container-exits-immediately
https://docs.docker.com/config/containers/multi-service_container/

See my Evernotes for more on running services inside a container.

