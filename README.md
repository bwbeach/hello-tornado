# hello-tornado

Experimenting with docker / circle-ci / etc.

## Running the app

Building the image:

- `docker build --tag hello:0.1 .`

To run locally:

- `docker run -d -p 8000:8888 hello:0.1`

## To Do

- get a build running of the image
- have the build add the image to a registry

## Questions To Answer

How does one set up a dev environment?  Run in docker, or not?

## History

These are the steps I took to get here.

1. Create an empty repo on github, with README, with Python .gitignore, and an MIT license.
1. Copy the sample "hello world" tornado app from the tornado docs.
1. Copy sample Dockerfile from [tornado samples](https://github.com/tornadoweb/tornado/tree/master/demos/blog), and tweak it.
