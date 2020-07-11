FROM ruby:2.7-alpine
RUN apk add --no-cache git && \
    gem install -N octokit -v 4.18.0
COPY main.rb /

ENTRYPOINT ["ruby", "/main.rb"]
