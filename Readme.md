# Docker Compose dev environment with Nginx reverse

This repository tends to help developers using multi projects on their machine and have issues to manage them easily.
Basically, there is 2 kind of docker users
- The first one sticks using a fully docker-compose with all the requires service to run the project.
- The second try to use global service and a minimal docker-compose on their project.

Still here ? Alright! If you ever had issues connecting your local projects between them with a proper domain, this is for you. Or if you are tired to use different port to reach your services ;).

Enough to talk, let's go for the examples and explanations.

## docker-compose.yml

This file contains minimal services we used to work with locally:
- mysql
- redis
- maildev

All the required ports are exposed, first for the external services and even if you need to connect to one of them.

Below, we have a network:
```yml
networks:
    local.dev:
        name: local.dev
```
This network will be used to connect the external services between them.

(Feel free to fork or make PR to add new services. It's very easy to manage them individually)

## Makefile

It contains basic shortcut commands :) 

## Connect others services

So let's take a project call 'HelloYou', this project contains a docker-compose like this:
```yml
version: "3.5"

services:
  # PHP-FPM exposing 9000
  app:
    container_name: ${DOCKER_CONTAINER_PREFIX}.app
    build: ./docker/app
    volumes:
      - type: bind
        source: .
        target: ${DOCKER_WORK_DIR}
    networks:
      - project-backend
      - local.dev

  web:
    container_name: ${DOCKER_CONTAINER_PREFIX}.web
    build: ./docker/nginx
    volumes:
      - type: bind
        source: .
        target: ${DOCKER_WORK_DIR}
    expose:
      - 80
    networks:
      - project--backend
      - local.dev
    environment:
      - VIRTUAL_HOST=project.local

  websocket:
    container_name: ${DOCKER_CONTAINER_PREFIX}.io
    build: ./docker/io
    networks:
      - local.dev
    expose:
      - 6001
    environment:
      - VIRTUAL_HOST=project.local.io
      - WEBSOCKETS=1

networks:
  project-backend:
  local.dev:
    external: true
```

So step by step, you noticed I use 2 networks here, the first one is just here to connect my services between them (even if docker use a default network) and then there is the `local-dev` network created by this repository.

Second important thing, as Nginx reverse is connected to the Docker socket to use their API, he needs to know what are your URL/Domain and associated ports you want to bind them using upstream inside its generated conf.
To make it happends, for our service exposing a server, we need to add an `environment` variable called:
- VIRTUAL_HOST=project.local

And for the PORT, we have to `expose` (or use `ports`) the port we want. 

Once it's done, Nginx will create an entry in its /etc/nginx/conf.d/default.conf :
```bash
# project.local
upstream project.local {
				## Can be connected with "local.dev" network
			# {container_name}.web
			server 172.23.0.6:80;
}
server {
	server_name project.local;
	listen 80 ;
	access_log /var/log/nginx/access.log vhost;
	location / {
		proxy_pass http://project.local;
	}
}

# project.local.io
upstream project.local.io {
				## Can be connected with "local.dev" network
			# project.local.io
			server 172.23.0.8:6001;
}
server {
	server_name project.local.io;
	listen 80 ;
	access_log /var/log/nginx/access.log vhost;
	location / {
		proxy_pass http://project.local.io;
	}
}
```

### Last step: /etc/hosts

Ok there is no magic here, you need to add your domains entry inside your `/etc/hosts` like:
- 127.0.0.1 project.local project.local.io

You can use a dnsmasq server on your machine and add the domain there if you prefer.

And voila! You can open your browser, use your terminal to reach a service using its domain only.

### Websocket

To use websocket with the reverse proxy, just add an `environment` variable in your service:
- WEBSOCKETS=1

And it's gonna be handled :) 

# Nginx Author

I use this repository to manage my workflow, thanks to the author and the contributors for the hard work done! You're awesome guys

[https://github.com/jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy)

If you need more information for advanced settings to cover your need, feel free to read his documention.

# Improvement

Feel free to create issue if you have some ideas, bug to reports.
