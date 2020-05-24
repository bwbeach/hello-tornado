# hello-tornado

[![bwbeach](https://circleci.com/gh/bwbeach/hello-tornado.svg?style=svg&branch=master)](https://app.circleci.com/pipelines/github/bwbeach/hello-tornado?branch=master)

An experiment in using Docker to package and deploy a simple 
web server.  My goal is to learn a little bit about docker,
and some modern tools for deploying a docker image in the cloud.

## Running the app

There is an automatic build of the `master` branch on docker.com.
To run it:

- `docker run -d -p 8000:8888 bwbeach/hello-tornado:latest`
- `curl http://localhost:8000`

## Running the app in Google Cloud Run

(This section is in progress.)

The current plan is to run on Google Cloud Run, which has a clear
[runtime contract](https://cloud.google.com/run/docs/reference/container-contract)
with the app running in the container.

The steps to run:
  - create account and project
  - download `gcloud` command line tool: `curl https://sdk.cloud.google.com | bash`
  - `gcloud auth configure-docker`
  - [push the image](https://cloud.google.com/container-registry/docs/pushing-and-pulling)
    - `docker tag b21240ed7b12 us.gcr.io/hello-tornado/hello-tornado`
    - `docker push us.gcr.io/hello-tornado/hello-tornado`
  - `gcloud run deploy --image=us.gcr.io/hello-tornado/hello-tornado:latest --platform managed` 
  - The app is now available at an [ugly domain name](https://hello-tornado-yd7w2njldq-uw.a.run.app)
  
Setting up a custom domain:
  - Google has [instructions](https://cloud.google.com/endpoints/docs/openapi/dev-portal-setup-custom-domain)
  
TO DO:
  - figure out how to push the image from circle-ci [to the google registry](https://circleci.com/docs/2.0/google-auth/)
  - figure out how to auto-reload after a push
  - figure out how to use my own domain name
  - when gcloud asks about accepting un-authenticated traffic, what does that mean?

## Building the image by hand

Building the image:

- `docker build --tag hello:0.1 .`

To run locally:

- `docker run -d -p 8000:8888 hello:0.1`

## To Do

- Figure out how to deploy the image to a container hosted on a cloud service.
- Figure out how to hook up [Let's Encrypt](https://letsencrypt.org/). 

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
   1. add a project, linked to GitHub
   1. use standard python template
   1. create an app token on docker.com
   1. add DOCKER_LOGIN (set to account name) and DOCKER_PASSWORD (set to app token) environment variables
   1. add a job to build the docker image
   1. add a step to run `test-image.sh` on the new image
   1. add a step to push the image to the [docker.com repository](https://hub.docker.com/repository/docker/bwbeach/hello-tornado).
1. Deploy to Google Cloud Run, using [their instructions](https://codelabs.developers.google.com/codelabs/cloud-run-deploy)
   1. [how to push an image](https://cloud.google.com/container-registry/docs/pushing-and-pulling)
   1. `gcloud auth configure-docker` to add `credHelpers` to `~/.docker/config.json`
   1. `docker pull docker.io/bwbeach/hello-tornado:latest`
   1. `docker tag docker.io/bwbeach/hello-tornado:latest us.gcr.io/hello-tornado/hello-tornado:latest`
   1. `docker push us.gcr.io/hello-tornado/hello-tornado:latest`
   1. Image name: `us.gcr.io/hello-tornado/hello-tornado:latest`
1. Set up build to push image to Google Cloud
   1. Create a custom roll called "Update Service" that can `run.services.update`
   1. create a "service account" on the [GC console](https://console.cloud.google.com/iam-admin/serviceaccounts).
      1. Needs roles:
         - Storage Admin (see [registry doc](https://cloud.google.com/container-registry/docs/access-control)) 
         - Cloud Run Admin
         - Cloud Run Service Agent
   1. you can test the key like this: `cat key.json | gcloud auth activate-service-account --key-file=-`
   1. `gcloud run services describe hello-tornado --platform managed --region us-west1`
   1. To see the IP address, etc.: `gcloud run services list --platform managed`
   1. `gcloud run deploy hello-tornado --image us.gcr.io/hello-tornado/hello-tornado:latest --platform managed --region us-west1`