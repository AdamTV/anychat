# Use the official Flutter Docker image as the base image
FROM cirrusci/flutter:stable

# Copy the pubspec.yaml and pubspec.lock files to the container
COPY pubspec.yaml pubspec.lock ./

# Run flutter pub get to install dependencies
RUN flutter pub get

# Copy the rest of the project files to the container
COPY . .

# Run flutter doctor to verify the Flutter installation
RUN flutter doctor
