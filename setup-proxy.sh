WORK_DIR=/home/vagrant

bash <(curl -f -L -sS https://ngxpagespeed.com/install) \
     --nginx-version latest --assume-yes


echo "Starting Nginx..."
rm -rf $WORK_DIR/cache
mkdir $WORK_DIR/cache
sudo cp /vagrant/nginx.conf /usr/local/nginx/conf/nginx.conf
sudo /usr/local/nginx/sbin/nginx

echo "Proxy should be available on port 8000."
