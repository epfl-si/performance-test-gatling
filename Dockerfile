FROM denvazh/gatling:latest

# -------------- install AWS cli tools for S3
RUN \
	mkdir -p /aws && \
	apk -Uuv add groff less python py-pip curl && \
	pip install awscli && \
	apk --purge -v del py-pip && \
	rm /var/cache/apk/*

# -------------- install git
RUN apk --update add git openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

VOLUME ["/sim"]

COPY ./bin  /bin/sim

ENTRYPOINT ["/bin/sim/docker-ep.sh"]
