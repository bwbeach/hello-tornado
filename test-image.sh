#!/bin/bash

#
# This script runs the image specified on the command line, and
# calls the web server inside it as a quick smoke test.
#

container_id=$(docker run -d -p 8888:8888 $1)
echo "Container is: ${container_id}"

# It's not possible to call the remote container directly
# When running in circle-ci, docker runs remotely, and
# it's not possible to call the remote container.  So,
# we'll run the test inside the container.
#
# See: https://circleci.com/docs/2.0/building-docker-images/#accessing-the-remote-docker-environment
#
# The server is not ready instantly, so we have to wait
# until it is.  I've tried these options to curl: --retry 10 --retry-connrefused --retry-delay 1
# but they still result in a return code of 7 (fail to connect) and failure.
#

for n in $(seq 10); do
    status=$(docker exec ${container_id} curl -s http://localhost:8888/status)
    curl_return_code=$?
    echo "curl_return_code = ${curl_return_code}"
    if [[ ${curl_return_code} != 7 ]]; then
        break
    fi
done

echo "Container status is: ${status}"

docker stop ${container_id}
docker rm ${container_id}
echo "Container stopped and removed: ${container_id}"

if [[ "$status" != healthy ]]; then
  echo TEST FAILED
  exit 1
fi
