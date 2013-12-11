echo "Updating packages..."

if type apt-get >/dev/null 2>&1; then
    apt-get -y update && apt-get -y upgrade
    apt-get -y install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip
fi

if type yum >/dev/null 2>&1; then
    yum -y update && yum -y upgrade
    yum -y install gcc-c++ pcre-dev pcre-devel zlib-devel make
fi

if [ ! -f /usr/local/nginx/sbin/nginx ]; then
  echo "Building Nginx with PageSpeed module..."

  cd /home/vagrant
  wget -nv https://github.com/pagespeed/ngx_pagespeed/archive/v1.7.30.1-beta.zip
  unzip v1.7.30.1-beta
  cd ngx_pagespeed-1.7.30.1-beta/
  wget -nv https://dl.google.com/dl/page-speed/psol/1.7.30.1.tar.gz
  tar -xzvf 1.7.30.1.tar.gz

  cd /home/vagrant
  wget -nv http://nginx.org/download/nginx-1.4.4.tar.gz
  tar -xvzf nginx-1.4.4.tar.gz
  cd nginx-1.4.4/
  ./configure --add-module=/home/vagrant/ngx_pagespeed-1.7.30.1-beta
  make && make install

fi

echo "Starting Nginx..."
rm -rf /home/vagrant/cache
mkdir /home/vagrant/cache
cp /vagrant/nginx.conf /usr/local/nginx/conf/nginx.conf
/usr/local/nginx/sbin/nginx

echo "Proxy should be available on port 8000."
