# hello-tornado

An experiment in using Docker to package and deploy a simple 
web server.  My goal is to learn a little bit about docker,
and some modern tools for deploying a docker image in the cloud.

## Running the app

There is an automatic build of the `master` branch on docker.com.
To run it:

- `docker run -d -p 8000:8888 bwbeach/hello-tornado:latest`
- `curl http://localhost:8000`

## Building the image by hand

Building the image:

- `docker build --tag hello:0.1 .`

To run locally:

- `docker run -d -p 8000:8888 hello:0.1`

## To Do

- Figure out how to deploy the image to a container hosted on a cloud service.
- Figure out how to hook up (Let's Encrypt)[https://letsencrypt.org/]. 

## Questions To Answer

- How does one set up a dev environment?  Run in docker, or not?
- Is it better to build the image separately from building the software?

## History

These are the steps I took to get here.

1. Create an empty repo on github, with README, with Python .gitignore, and an MIT license.
1. Copy the sample "hello world" tornado app from the tornado docs.
1. Copy sample Dockerfile from [tornado samples](https://github.com/tornadoweb/tornado/tree/master/demos/blog), and tweak it.
1. Add a repo on docker.com, link it to this GitHub repo, and enable automatic builds.
1. Set up a build in CircleCI
   a. add a project, linked to GitHub
   a. use standard python template
   a. create an app token on docker.com
   a. add DOCKER_LOGIN (set to account name) and DOCKER_PASSWORD (set to app token) environment variables
   a. add a job to build the docker image
   a. add a step to run `test-image.sh` on the new image
   a. add a step to push the image to the (docker.com repository)[https://hub.docker.com/repository/docker/bwbeach/hello-tornado].
