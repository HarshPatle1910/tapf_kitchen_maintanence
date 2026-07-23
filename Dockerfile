# Stage 1: Build the Flutter Web App
FROM ubuntu:22.04 AS build

# Install required dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa ca-certificates

# Set up environment variables
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
ENV FLUTTER_NO_CLI_ANALYTICS=true

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME}
RUN git config --global --add safe.directory ${FLUTTER_HOME}
RUN flutter config --no-analytics
RUN flutter doctor

# Copy the app source code
WORKDIR /app
COPY . .

# Build the Flutter web application
RUN git config --global --add safe.directory /app
RUN flutter clean
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Copy the custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built Flutter web files to Nginx's serving directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose the port Railway expects
EXPOSE 8080

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
