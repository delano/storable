# Usage: `$SHELL bin/docker-entrypoint`

#
# Expects environment variables from Dockerfile:
#
#   - CONTAINER_SHELL
#   - TRYOUTS_CACHE
#   - CODE_HOME
#

##
# Install the requested shell if it isn't already installed
#
SHELL_NAME=`basename ${CONTAINER_SHELL}`
if [ ! -f $CONTAINER_SHELL ]; then
  echo "File not found!"
  sudo apt-get install -y $SHELL_NAME
fi
#

##
# Copy the files that were cached by Dockerfile back where they
# belong. Why? Docker bolts the project directory on to the
# container as a volume named $CODE_HOME which (rightly)
# clobbers any pre-existing files. For containers that
# are used for testing like this one, we prefer this
# behavior to guarantee a pristine container.
#
cp -vurp ${TRYOUTS_CACHE}/. ${CODE_HOME}/

echo "Entering tryouts... $CONTAINER_SHELL"
$CONTAINER_SHELL
