FROM ruby:2.7-alpine
COPY main.rb Gemfile Gemfile.lock /
RUN apk add --no-cache git && \
    bundle

ENTRYPOINT ["ruby", "/main.rb"]
