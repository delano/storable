# syntax=docker/dockerfile:experimental

##
# A container for running the tryouts
#
#  Usage:
#
#   $ bin/tryouts
#
#     OR
#
#   $ export NAME=tryouts RUN_HOME=/run/host-services
#   $ docker build -t $NAME .
#   $ docker run -d --name $NAME -it --volume ${PWD}:/code --rm -v $RUN_HOME/ssh-auth.sock:$RUN_HOME/ssh-auth.sock -e SSH_AUTH_SOCK="$RUN_HOME/ssh-auth.sock" $NAME
#   $ dssh $NAME
#   $ docker stop $NAME
#

#
ARG VERSION=2.7.2

# FROM ruby:2.4.2-slim
FROM ruby:$VERSION

# The home directory for the application in the container
ARG CODE_ROOT=/code
ARG OWNER=coach
ARG SHELL=/bin/bash
ARG HOME=/home/$OWNER

# Change to 1 to exepct a Gemfile.lock
ARG BUNDLER_FROZEN=0

ARG PACKAGES="build-essential ruby-dev openssh-client screen git"

# Create the most dedicated user
RUN adduser --disabled-password --home $HOME --shell $SHELL $OWNER

# Get the latest package list (but skip upgrading for speed)
RUN set -eux && apt-get update -y

# Install the system dependencies
RUN apt-get install -y $PACKAGES

# This path is mounted in bin/tryouts
WORKDIR $HOME

# RUN gem install bundler
RUN gem install bundler -v '1.17.3'

# For <= 2.2
RUN gem update --system 2

ENV BUNDLE_SILENCE_ROOT_WARNING=1
RUN mkdir -p /usr/local/bundle && chown -R $OWNER /usr/local/bundle
RUN mkdir -p .bundle .gem && chown -R $OWNER .bundle $HOME/.gem
RUN bundle config --global frozen $BUNDLER_FROZEN

##
# Gear down into regular user world
#
# This change effects RUN, CMD, ENTRYPOINT
# but not COPY, ADD which take --chown argument instead
USER $OWNER

##
# Install rbenv with build capability
#
RUN git clone git://github.com/sstephenson/rbenv.git .rbenv
RUN git clone git://github.com/sstephenson/ruby-build.git .rbenv/plugins/ruby-build

ENV PATH=$HOME/.rbenv/shims:$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH
# ARG PATH=$PATH

RUN echo "$VERSION" >> .ruby-version

RUN rbenv install --version $VERSION \
  && rbenv rehash \
  && rbenv shims

#
#RUN $SHELL -c "if [ '${VERSION}' == *'1.9'* ]; then echo 'RUBY1'; else echo 'RUBY2'; fi"

# This path is mounted in bin/tryouts
WORKDIR $CODE_ROOT

# Get. Ready. to Buuuuundllllle
COPY ./Gemfile $CODE_ROOT/

## Ruby 2.4+
# RUN bundle install -j4 --retry 3

# Ruby 1.9.3
RUN bundle install

ENV SHELL=$SHELL
CMD $SHELL
