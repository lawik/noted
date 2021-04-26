postgres:
	docker run -dit --restart unless-stopped -e POSTGRES_PASSWORD="postgres" -p 5432:5432 postgres