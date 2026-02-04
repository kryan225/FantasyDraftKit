# syntax=docker/dockerfile:1

# Development Dockerfile - optimized for local development with volume mounts
FROM ruby:3.3-slim

# Install dependencies needed for gems with native extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install bundler
RUN gem install bundler

# Copy Gemfile first for layer caching
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
