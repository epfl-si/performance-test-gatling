.PHONY: aws_push build

build:
	docker-compose -f docker-compose.yml build
	docker tag performancetestgatling_runner multiscan/idevelop-gatling
	docker login
	docker push multiscan/idevelop-gatling

aws_push:
	aws --profile gatling-eu s3 cp --recursive ./simulations s3://idevelop-gatling-results/simulations
