# hello-tornado

[![bwbeach](https://circleci.com/gh/bwbeach/hello-tornado.svg?style=svg&branch=master)](https://app.circleci.com/pipelines/github/bwbeach/hello-tornado?branch=master)

This project was a learning exercise for me.  My goal was to learn
how to deploy a web server, packaged in a container, with support for
secure connections through https.

The path I chose was to:

- store the source code in GitHub,
- build, test, and package in Circle CI,
- keep a docker image at docker.com, and
- deploy in Google Cloud Run.

There are many choices for continuous integration in the cloud;
I picked Circle CI because many people have mentioned it, and I
hadn't used it before.  Docker seemed like the logical choice to
host docker images.

Google Cloud Run is the only place I've found so far that can host
an application in a container image, and take care of the rest
of the deployment issues, including generating a certificate for
TLS.  (Heroku does all that stuff, but doesn't run docker containers.)

I figured out how to do each step manually, then wrote the YAML for Circly CI
to automate it.

## The Web Server

The web server in this example needs to be able to run
in a docker container, and to run in Google Cloud Run.
For docker, it's good to have the server shut down quickly
when it gets a SIGTERM.  For Google, it
needs to listen on the port in the PORT envoronment variable.

I used the Tornado framework in Python, which I've used before.
The core of the server returns "Hello, world" as the main page,
and has a `/status` call as a placeholder for integration
tests to run during the build.  This is based on the "hello world"
sample app in the Tornado docs.

```python
class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("Hello, world\n")

class StatusHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("healthy")

def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/status", StatusHandler)
    ])
```

For testing, you'll need a python virtualenv with tornado
installed.  Then you can run the server by starting it
like this:

```
$ ./hello.py
listening on port 8888
```

And then look at the web page in your browser at [`http://localhost:8888`](http://localhost:8888).

Shut down the server by typing control-C.  Tornado handles this by default, but does
not respond to SIGTERM by default.  Doing that took some code:

```python
def main():
    app = make_app()
    server = app.listen(PORT)
    ioloop = tornado.ioloop.IOLoop.current()

    def stop():
        # Stop listening for more connections, and de-register
        # from the ioloop.
        server.stop()
        # Stop the ioloop.  Running tasks may still finish.
        ioloop.stop()

    def handler(_signum, _stack_frame):
        # Tell the ioloop to run the stop action.  IO loops are
        # not very thread safe, and we can't run the stop()
        # method in the signal handler.
        ioloop.add_callback_from_signal(stop)

    signal.signal(signal.SIGTERM, handler)

    print('listening on port', PORT)
    ioloop.start()
    print('server stopped')
```

The unit tests for the app run in the normal Python `unittest` framework.
To run from the command line:

```
python -m unittest hello.py
```

For the `config.yml` file for CircleCI, I started with their standard Python template.
These are the steps to install Python dependences and run the unit tests:

```yaml
    steps:
      - checkout
      - python/load-cache
      - python/install-deps
      - python/save-cache
      - run:
          command: python -m unittest hello.py
          name: Unit Test

```

## Building a Container Image

Now that we have a web server, the next step is to package it inside
a docker image.  The [`Dockerfile`](https://github.com/bwbeach/hello-tornado/blob/master/Dockerfile) does this.

To build it by hand:

```
DOCKER_USERNAME=bwbeach
docker build . --tag ${DOCKER_USERNAME}/hello-tornado:hand-built
```

To run the image on port 8000:

```
docker run -d -p 8000:8888 ${DOCKER_USERNAME}/hello-tornado:hand-built
```

To push the image up to Docker, go to (docker.com){docker.com} and create
a repository called `hello-tornado`.  Then:

```
docker push ${DOCKER_USERNAME}/hello-tornado:hand-built
```

Now we can run the image from any computer that has docker, and
it will fetch it from `docker.com` and run it.  The command is the
same run command as above.

These are the Circle CI steps to package up the Docker image, test
it, and push it to `docker.com`:

```yaml
    steps:
      - setup_remote_docker
      - docker/check
      - docker/build:
          image: bwbeach/hello-tornado
          tag: latest
      - run:
          command: ./test-image.sh bwbeach/hello-tornado:latest
          name: Image Test
      - docker/push:
          image: bwbeach/hello-tornado
          tag: latest
```

## Running the app in Google Cloud Run

Google Cloud Run has a clear
[runtime contract](https://cloud.google.com/run/docs/reference/container-contract)
with the app running in the container.  The important part is that it
says the app should listen on the port from the PORT environment variable.

To get things set up:

1. Create an account and a project at Google Cloud Run.
1. Download the `gcloud` command line tool and set it up:
   - `curl https://sdk.cloud.google.com | bash`
   - `gcloud login`
   - `gcloud auth configure-docker`
1. Push the image to Google Cloud Run
   - `docker tag docker.com/bwbeach/hello-tornado:latest us.gcr.io/hello-tornado/hello-tornado`
   - `docker push us.gcr.io/hello-tornado/hello-tornado`
   - `gcloud run deploy --image=us.gcr.io/hello-tornado/hello-tornado:latest --platform managed` 
   - The app is now available at an [ugly domain name](https://hello-tornado-yd7w2njldq-uw.a.run.app)
   
To automate this, the build system needs access to Google Cloud Run:

1. [Make a service account](https://console.cloud.google.com/iam-admin/serviceaccounts), and create a key for it,
   being sure to download the JSON key and keep it in a safe place.
1. [Assign roles](https://console.cloud.google.com/iam-admin/iam) to the service account:
   - Cloud Run Admin
   - Cloud Run Service Agent
   - Storage Admin

These are the steps to automate deployment:

```yaml
    steps:
      - run:
          command: |
            echo ${GOOGLE_CLOUD_KEY} | gcloud auth activate-service-account --key-file=-
            gcloud auth configure-docker
            gcloud config set project hello-tornado
            docker tag bwbeach/hello-tornado:latest us.gcr.io/hello-tornado/hello-tornado:latest
            docker push us.gcr.io/hello-tornado/hello-tornado:latest
            gcloud run deploy hello-tornado --image us.gcr.io/hello-tornado/hello-tornado:latest --platform managed --region us-west1
```

## Building in Circle CI

Some things need to be set up to get things running:

1. add a project, linked to GitHub
1. create an app token on docker.com
1. add DOCKER_LOGIN (set to account name) and DOCKER_PASSWORD (set to app token) environment variables
1. create a key at Google Cloud.
1. add the GOOGLE_CLOUD_KEY environment variable, set to the JSON for the key.

Once those are in place, Circle CI can run `config.yml` do build,
test, push the image to Docker, push the image and update the
deployment at Google Cloud Run.

## Set up a Custom Domain

Thas was [really easy on Google](https://cloud.google.com/run/docs/mapping-custom-domains).  
They take care of getting the server certificate for TLS.

The steps:

- Buy the domain name.  I used [Google Domains](https://domains.google.com/m/registrar) for this one.
- Set up the mapping in Google Cloud Run.
- Copy the DNS entries from Google Cloud Run to Google Domains.

After waiting for the DNS to propagate, and for Google to set up the certificate, 
the [site is ready](https://maui-labs.net). 
