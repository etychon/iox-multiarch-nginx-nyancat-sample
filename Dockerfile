FROM nginx
COPY nyan-cat /usr/share/nginx/html
# By default Nginx will run on port 80, so let's expose that port
EXPOSE 80
