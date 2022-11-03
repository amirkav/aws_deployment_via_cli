

##########################
Application DockerFile
##########################
dockerfile
The main dockerfile starts the application on a Docker container.
Use the scripts under docker_build_scripts as wrappers around this dockerfile.


##########################
Testing & Debugging
##########################
dockerfile-test-webserver automates the following process, so we dont need to do it manually:
(a) start a new container
(b) ssh into the container
(c) create a test apache simple HTML file
(d) try browsing to the page from outside
(e) if it works, there is something wrong with your app.
    It is most likely python package installations with virtual env.


====================
virtual environment
====================
Are all packages installed in the correct virt env?

Note: "/opt/venv/bin/activate" does not activate the environment.
Only "source /opt/venv/bin/activate" would do that.


====================
file permissions
====================
Does apache has access to execute all scripts it needs to?


====================
server and app start
====================
Does docker or the initializer script start both apache server and web app?

We cannot restart Apache from inside the container,
because we cannot execute systemctl or apachectl.
Therefore, if you make any changes to HTML files,
you need to start a new container.

# Starting Apache inside a container
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/getting_started_with_containers/install_and_deploy_an_apache_web_server_container
http://kimh.github.io/blog/en/docker/gotchas-in-writing-dockerfile-en/


############
References
############
# See the following links for best practices on writing dockerfiles,
https://stackoverflow.com/questions/20635472/using-the-run-instruction-in-a-dockerfile-with-source-does-not-work
https://docs.docker.com/engine/reference/builder/#run
