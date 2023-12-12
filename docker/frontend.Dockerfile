# Use the official Nginx image as the base image
FROM nginx:latest

# Copy the HTML file to the default Nginx web root directory
COPY ./frontend/index.html /usr/share/nginx/html/index.html

# Expose port 80 for incoming HTTP traffic
EXPOSE 80

# CMD instruction to start Nginx and serve the HTML file
CMD ["nginx", "-g", "daemon off;"]