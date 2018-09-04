username?=abogatikov
reponame?=mtproxy
version?=SNAPSHOT

clean:
	docker rmi $(shell docker images |grep '${username}/${reponame}') || echo "NO IMAGES HERE"

build:
	docker build -t ${username}/${reponame}:${version} -t ${username}/${reponame}:latest .

push:
	docker push ${username}/${reponame}:${version}
	docker push ${username}/${reponame}:latest

publish: clean build push