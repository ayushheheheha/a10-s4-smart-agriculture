FROM nginx:latest
RUN rm -f /usr/share/nginx/html/index.html
COPY index.html /usr/share/nginx/html/home.html
EXPOSE 80
