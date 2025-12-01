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

# ----------------------------------------------------------------------------------
# STAGE 1: BUILD STAGE (Use a full JDK for compilation, if needed. Assuming pre-built JAR)
# ----------------------------------------------------------------------------------
# NOTE: The provided Dockerfile assumes the JAR is ALREADY built outside.
# If you were building inside the container, this would be the stage for Maven/Gradle.
# Skipping this stage to match your input, which copies a pre-built JAR.

# ----------------------------------------------------------------------------------
# STAGE 2: DEPLOY STAGE (The final, minimal runtime image)
# ----------------------------------------------------------------------------------
# CHANGE: Updated to use Java 21 (LTS) to align with modern best practices.
FROM eclipse-temurin:21-jre-alpine AS final

# CRITICAL SECURITY FIX: Update and upgrade Alpine packages to patch libpng and others.
RUN apk update && \
    apk upgrade --available && \
    rm -rf /var/cache/apk/*

# Metadata
LABEL maintainer="Kiran Roy"
LABEL app="bankapp"

# Set working directory
WORKDIR /app

# Arguments and Environment Variables
ARG GIT_REF
ARG APP_VERSION
ENV GIT_REF=${GIT_REF}
ENV APP_VERSION=${APP_VERSION}

# Copy the pre-built jar from Jenkins workspace
# The path must match your CI/CD output structure. Assuming 'target/bankapp.jar'.
COPY target/bankapp.jar ./bankapp.jar

# Expose application port
EXPOSE 8080

# Start the application
# Use the minimum memory settings for a typical Spring Boot app in a container
ENTRYPOINT ["java", "-Xms128m", "-Xmx256m", "-jar", "bankapp.jar"]

# ----------------------------------------------------------------------------------
# Action Required: Update your Jenkins script to build for Java 21 (or set pom.xml to 17).
# ----------------------------------------------------------------------------------
