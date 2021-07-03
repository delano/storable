# syntax=docker/dockerfile:experimental

##
# A container for running tryouts with different versions
#
#  Supported versions: 2.7.3, 2.6.6, 1.9.3
#
#  Usage:
#
#   $ bin/tryouts
#   $ VERSION=2.6.6 bin/tryouts
#
#     OR
#
#   $ export NAME=tryouts RUN_HOME=/run/host-services
#   $ docker build -t $NAME .
#   $ docker run -d --name $NAME -it --volume ${PWD}:/code --rm -v $RUN_HOME/ssh-auth.sock:$RUN_HOME/ssh-auth.sock -e SSH_AUTH_SOCK="$RUN_HOME/ssh-auth.sock" $NAME $COMMAND
#   $ dssh $NAME
#   $ docker stop $NAME
#

ARG VERSION=2.6.6
FROM ruby:$VERSION
ARG VERSION

# The home directory for the application in the container
ARG CODE_ROOT=/code
ARG OWNER=coach
ARG COMMAND=/bin/bash
ARG HOME=/home/$OWNER
ARG BUNDLER_FROZEN=0

ARG PACKAGES="ruby1.9.1 openssh-client screen git"

WORKDIR $CODE_ROOT

# Create the most dedicated user
RUN adduser --disabled-password --home $HOME --shell $COMMAND $OWNER

# Get the latest package list (but skip upgrading for speed)
RUN set -eux && apt-get update -y

# Install the system dependencies
RUN apt-get install -y $PACKAGES

# Major and minor parts of the version
RUN echo ${VERSION} | egrep -o '[0-9]{1,2}.[0-9]{1,2}' > .ruby-version
RUN echo ${VERSION} | egrep -o '[0-9]{1,2}.[0-9]{1,2}' > $HOME/.ruby-version-yay

# This path is mounted in bin/tryouts
WORKDIR $HOME

RUN gem install bundler -v '1.17.3'
# RUN gem install bundler

# For <= 2.2, use "--system 2" otherwise just "--system`"
RUN gem update --system 2
# RUN gem install debugger -v 1.1.4

# ENV BUNDLE_SILENCE_ROOT_WARNING=1
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

RUN rbenv local system \
  && rbenv rehash \
  && rbenv shims

# This path is mounted in bin/tryouts
WORKDIR $CODE_ROOT

# Get. Ready. to Buuuuundllllle
ENV GEMFILE="Gemfile-${VERSION}"
COPY ${GEMFILE} $CODE_ROOT/Gemfile

# For <= 2.2, plain-jane is best, "-j4 --retry 3" for everything els
RUN bundle install

ENV VERSION=$VERSION
ENV COMMAND=$COMMAND
CMD $COMMAND
