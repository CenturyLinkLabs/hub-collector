FROM alpine:3.1
MAINTAINER CenturyLink Labs

RUN apk update && apk add ruby-dev ca-certificates make build-base postgresql-dev
RUN gem install --no-document json pg

WORKDIR /collector
COPY . /collector

ENTRYPOINT ["/usr/bin/ruby"]
CMD ["--help"]
