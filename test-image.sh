#!/bin/bash

#
# This script runs the image specified on the command line, and
# calls the web server inside it as a quick smoke test.
#

container_id=$(docker run -d -p 8000:8888 $1)
echo "Container is: ${container_id}"

# The server is not ready instantly, so we have to wait
# until it is
while true; do
  status=$(curl -s http://localhost:8000/status)
  if [[ ! -z "$(curl -s http://localhost:8000/status)" ]]; then
    break
  fi
  sleep 1
done

echo "Container status is: ${status}"

docker stop ${container_id}
docker rm ${container_id}
echo "Container stopped and removed: ${container_id}"

if [[ "$status" != healthy ]]; then
  exit 1
fi
