# syntax=docker/dockerfile:experimental

##
# A container for running tryouts with different versions
#
#  Supported versions: 2.7.3, 2.6.6, 1.9.3
#
#  Usage:
#
#   $ bin/tryouts
#   $ VERSION=2.7.3 bin/tryouts
#
#     OR
#
#   $ export NAME=tryouts RUN_HOME=/run/host-services
#   $ docker build -t $NAME .
#   $
#   $ dssh $NAME
#   $ docker stop $NAME
#

# Set the default version, unless `--build-arg VERSION=1.2.3`
ARG VERSION=2.6.6
FROM ruby:$VERSION

# Bring VERSION back from the dead
ARG VERSION

# These arguments are for the build and as defaults for ENV
ARG CONTAINER_SHELL=/bin/bash
ARG OWNER=coach
ARG HOME=/home/$OWNER
ARG CODE_HOME=/code
ARG CODE_WOKE=100%
ARG BUNDLER_FROZEN=0
ARG PACKAGES="ruby-dev openssh-client git sudo"

ENV BUNDLE_HOME=$HOME/.bundle
ENV CODE_HOME=$CODE_HOME
ENV GEMFILE=etc/Gemfile-${VERSION}
ENV TRYOUTS_CACHE=$HOME/.tryouts/cache
ENV VERSION=$VERSION
ENV GEMFILE_TARGET=$TRYOUTS_CACHE/Gemfile
ENV CONTAINER_SHELL=$CONTAINER_SHELL

# Create the most dedicated user
RUN adduser --disabled-password --home $HOME --shell $CONTAINER_SHELL $OWNER
RUN usermod -a -G sudo $OWNER
RUN groupadd docker
RUN usermod -a -G docker $OWNER

# Get the latest package list (but skip upgrading for speed)
RUN set -eux && apt-get update -y

# Install the system dependencies
RUN apt-get install -y $PACKAGES

RUN apt-get autoremove && apt-get clean

# This path is mounted in bin/tryouts
WORKDIR $HOME
COPY etc/.gemrc .

RUN gem update --system
RUN gem install bundler

##
# Gear down into regular user world
#
# This change effects RUN, CMD, ENTRYPOINT
# but not COPY, ADD which take --chown argument instead
USER $OWNER
WORKDIR $TRYOUTS_CACHE

RUN bundle config set --local clean 'true'
RUN bundle config set --local path $BUNDLE_HOME

COPY $GEMFILE Gemfile

# Major and minor parts of the version
RUN echo ${VERSION} | egrep -o '[0-9]{1,2}.[0-9]{1,2}' > $TRYOUTS_CACHE/.ruby-version

# Creates the path as the current user. Without this, any
# attempt to change files will raise a permissions error.
WORKDIR $CODE_HOME

RUN bundle config set --global path $BUNDLE_HOME

# Get. Ready. to. Buuuuundllllle
# For <= 2.2, plain-jane; for > 2.2, "-j4 --retry 3"
RUN bundle install \
  --gemfile $GEMFILE_TARGET \
  --jobs 4
