# #----------------------------------
# # Stage 1
# #----------------------------------

# # Import docker image with maven installed
# FROM maven:3.8.3-openjdk-17 as builder 

# # Add maintainer, so that new user will understand who had written this Dockerfile
# MAINTAINER Kiranroy

# # Add labels to the image to filter out if we have multiple application running
# LABEL app=bankapp

# # Set working directory
# WORKDIR /src

# # Copy source code from local to container
# COPY . /src

# # Build application and skip test cases
# #RUN mvn clean install -DskipTests=true

# #--------------------------------------
# # Stage 2
# #--------------------------------------

# # Import small size java image
# FROM openjdk:17-alpine as deployer

# # Copy build from stage 1 (builder)
# COPY --from=builder /src/target/*.jar /src/target/bankapp.jar

# # Expose application port 
# EXPOSE 8080

# # Start the application
# ENTRYPOINT ["java", "-jar", "/src/target/bankapp.jar"]
#----------------------------------
# Stage 1: Deploy pre-built JAR
#----------------------------------

# Use small Java runtime image
FROM eclipse-temurin:17-jdk-alpine AS deployer

# Metadata
LABEL maintainer="Kiran Roy"
LABEL app="bankapp"

# Set working directory
WORKDIR /app

# Arguments for metadata (optional, useful for CI/CD tagging)
ARG GIT_REF
ARG APP_VERSION
ENV GIT_REF=${GIT_REF}
ENV APP_VERSION=${APP_VERSION}

# Copy the pre-built jar from Jenkins workspace
COPY target/*.jar ./bankapp.jar

# Expose application port
EXPOSE 8080

# Start the application
ENTRYPOINT ["java", "-jar", "bankapp.jar"]
