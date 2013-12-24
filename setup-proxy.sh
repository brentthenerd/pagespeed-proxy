WORK_DIR=/home/vagrant

PAGESPEED_VERSION=latest-stable

NGINX_VERSION=1.4.4
NGINX_DOWNLOAD=http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
NGINX_DIR=$WORK_DIR/nginx-$NGINX_VERSION/

NGX_PAGESPEED_VERSION=1.7.30.1-beta
NGX_PAGESPEED_DOWNLOAD=https://github.com/pagespeed/ngx_pagespeed/archive/v$NGX_PAGESPEED_VERSION.zip
NGX_PAGESPEED_DIR=$WORK_DIR/ngx_pagespeed-$NGX_PAGESPEED_VERSION

GIT_VERSION=1.8.5.2
GIT_TARBALL=git-$GIT_VERSION.tar.gz
GIT_DOWNLOAD=https://www.kernel.org/pub/software/scm/git/$GIT_TARBALL
GIT_DIR=$WORK_DIR/git

echo "Updating packages..."
if type apt-get >/dev/null 2>&1; then
  sudo apt-get -y update && sudo apt-get -y upgrade
  sudo apt-get -y install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip
  sudo apt-get -y install apache2 python subversion gperf devscripts fakeroot git
fi

if type yum >/dev/null 2>&1; then
  sudo yum -y update && sudo yum -y upgrade
  sudo yum -y install gcc-c++ pcre-dev pcre-devel zlib-devel make
  sudo yum -y install httpd python subversion gperf rpm-build git
fi

INSTALL_GIT=0
if [ -d $GIT_DIR ]; then
  export PATH=$GIT_DIR/bin:$PATH
fi
if type git >/dev/null 2>&1; then
  if git --version | grep '1\.8'; then
    echo "Git is found."
  else
    echo "Git needs to be version 1.8."
    INSTALL_GIT=1
  fi
else
  echo "Git is not found."
  INSTALL_GIT=1
fi

if [ $INSTALL_GIT -eq 1 ]; then
  echo "Compiling Git $GIT_VERSION from source..."
  if type yum >/dev/null 2>&1; then
    sudo yum -y install curl-devel perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker
  fi
  wget -nv $GIT_DOWNLOAD
  tar -xf $GIT_TARBALL
  rm $GIT_TARBALL
  cd git-$GIT_VERSION
  ./configure --prefix=$GIT_DIR --with-curl --with-expat
  make NO_MSGFMT=YesPlease NO_TCLTK=YesPlease NO_GETTEXT=YesPlease install
fi
if [ -d $GIT_DIR ]; then
  export PATH=$GIT_DIR/bin:$PATH
  echo "Using Git"
  which git
  git --version
fi

if [ ! -d $WORK_DIR/depot_tools ]; then
  echo "Getting Google depot tools..."
  cd $WORK_DIR
  svn co https://src.chromium.org/svn/trunk/tools/depot_tools
fi
export PATH=$PATH:$WORK_DIR/depot_tools

# See https://github.com/pagespeed/ngx_pagespeed/wiki/Building-PSOL-From-Source
echo "Building mod_pagespeed from source..."
if [ ! -d $WORK_DIR/mod_pagespeed ]; then
  cd $WORK_DIR
  mkdir mod_pagespeed
fi
cd $WORK_DIR/mod_pagespeed
gclient config http://modpagespeed.googlecode.com/svn/branches/$PAGESPEED_VERSION/src
gclient sync --force --jobs=1

cd src
make AR.host="$PWD/build/wrappers/ar.sh" \
     AR.target="$PWD/build/wrappers/ar.sh" \
     BUILDTYPE=Release \
     mod_pagespeed_test pagespeed_automatic_test

cd net/instaweb/automatic
make CXXFLAGS="-DSERF_HTTPS_FETCHING=0" \
     BUILDTYPE=Release \
     AR.host="$PWD/../../../build/wrappers/ar.sh" \
     AR.target="$PWD/../../../build/wrappers/ar.sh" \
     all

echo "Building Nginx with PageSpeed module..."
cd $WORK_DIR
if [ ! -d $NGX_PAGESPEED_DIR ]; then
  wget -nv $NGX_PAGESPEED_DOWNLOAD
  unzip v$NGX_PAGESPEED_VERSION
fi
if [ ! -d $NGINX_DIR ]; then
  wget -nv $NGINX_DOWNLOAD
  tar -xvzf nginx-$NGINX_VERSION.tar.gz
fi
cd $NGINX_DIR
MOD_PAGESPEED_DIR="$WORK_DIR/mod_pagespeed/src" ./configure --add-module=$NGX_PAGESPEED_DIR
make

echo "Installing Nginx..."
sudo make install

echo "Starting Nginx..."
rm -rf $WORK_DIR/cache
mkdir $WORK_DIR/cache
sudo cp /vagrant/nginx.conf /usr/local/nginx/conf/nginx.conf
sudo /usr/local/nginx/sbin/nginx

echo "Proxy should be available on port 8000."
