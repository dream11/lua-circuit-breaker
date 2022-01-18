build:
	cd ngx_lua_sample && docker-compose build nginx

up: down
	cd ngx_lua_sample && docker-compose up nginx

down:
	cd ngx_lua_sample && docker-compose down -v

.PHONY: build up down
