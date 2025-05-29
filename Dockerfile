# Dockerfile
FROM nginx:alpine

# Overwrite the default index.html with a test page
RUN echo '<!DOCTYPE html><html><body><h1>Hello from custom nginx!</h1></body></html>' \
    > /usr/share/nginx/html/index.html

# Expose the default HTTP port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

