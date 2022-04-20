# syntax=docker/dockerfile:1.4

FROM alpine as bikeshed

# build and consolidate all the things
RUN apk add --update \
	alpine-sdk \
	curl \
	gcc \
	jpeg-dev \
	libxml2-dev \
	libxslt-dev \
	py3-pip \
	python3 \
	python3-dev \
	zlib-dev
RUN pip3 install bikeshed
COPY --from=madnight/alpine-wkhtmltopdf-builder:0.12.5-alpine3.10-866998106 \
    /bin/wkhtmltopdf /usr/bin/wkhtmltopdf
ENV PHANTOMJS_ARCHIVE="phantomjs.tar.gz"
RUN curl -Lk -o $PHANTOMJS_ARCHIVE https://github.com/fgrehm/docker-phantomjs2/releases/download/v2.0.0-20150722/dockerized-phantomjs.tar.gz
RUN mkdir -p /phantomjs
RUN tar -xf $PHANTOMJS_ARCHIVE -C /phantomjs
RUN strip /usr/bin/wkhtmltopdf
RUN strip /phantomjs/usr/local/bin/phantomjs

# create the real container, copying build targets over
FROM alpine
LABEL org.opencontainers.image.authors="dwaite@pingidentity.com"

RUN --mount=type=bind,target=/mnt,source=/,from=bikeshed <<eot
	apk add --update \
		fontconfig \
		freetype \
		ghostscript \
		git \
		icu \
		libjpeg \
		libxml2 \
		libxrender \
		libxslt \
		make \
		py3-pip \
		python3 \
		ttf-dejavu \
		zlib
        for i in bikeshed normalizer pygmentize wkhtmltopdf; do
	  cp /mnt/usr/bin/$i /usr/bin
        done
        mkdir -p /usr/lib/python3.9/site-packages
	cp -pPrn /mnt/usr/lib/python3.9/site-packages/* /usr/lib/python3.9/site-packages/

	# copy over phantom build
	cp /mnt/phantomjs/usr/local/bin/phantomjs /usr/bin/
eot

WORKDIR /root
