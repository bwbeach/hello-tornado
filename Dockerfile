FROM python:3.8

EXPOSE 8888

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["/usr/src/app/hello.py"]
