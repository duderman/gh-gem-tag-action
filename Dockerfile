FROM ruby:2.7-alpine
COPY main.rb Gemfile Gemfile.lock /
RUN bundle

ENTRYPOINT ["ruby", "main.rb"]
