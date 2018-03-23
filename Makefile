all: up

down:
	docker-compose down

stop:
	docker-compose stop

build:
	docker-compose build

up:
	docker-compose up -d

logs:
	docker-compose logs -f
