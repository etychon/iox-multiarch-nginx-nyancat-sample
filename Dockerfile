FROM nginx:stable
COPY nyan-cat /usr/share/nginx/html
# Not needed but handy should you want to use console
# 	for troubleshooting.
RUN apt-get update && apt install -y iproute2 iputils-ping telnet \
	procps net-tools joe
# Defaulting to /dev/stderr which does not work well when LXC's on IR829
RUN rm /var/log/nginx/access.log && rm /var/log/nginx/error.log
RUN touch /var/log/nginx/access.log \
	&& touch /var/log/nginx/error.log
RUN chmod 666 /var/log/nginx/access.log \
    	&& chmod 666 /var/log/nginx/error.log
COPY loop.sh /root/loop.sh
# By default Nginx will run on port 80, so let's expose that port
EXPOSE 80
