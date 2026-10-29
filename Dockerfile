FROM nginx:stable-alpine
COPY index.html kickstrap.css mine.css /usr/share/nginx/html/
COPY Scripts/ /usr/share/nginx/html/Scripts/
COPY Kickstrap/ /usr/share/nginx/html/Kickstrap/
EXPOSE 80
