FROM ruby:2.7-alpine:3.11
COPY main.rb Gemfile Gemfile.lock /
RUN bundle

ENTRYPOINT ["/main.rb"]
