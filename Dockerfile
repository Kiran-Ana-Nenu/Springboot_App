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
# ----------------------------------------------------------------------------------
# STAGE 1: BUILDER
# Purpose: Compiles the source code and creates the executable JAR using JDK 21.
# This stage ensures the correct Java version (21) is used for compilation, 
# solving the previous "release version not supported" error, assuming your
# pom.xml is set to <java.version>21</java.version>.
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# STAGE 1: BUILDER
# Purpose: Compiles the source code and creates the executable JAR using JDK 21.
# ----------------------------------------------------------------------------------
FROM eclipse-temurin:21-jdk-alpine AS builder

# Set working directory for the build
WORKDIR /build

# Copy Maven wrapper files and pom.xml first to leverage Docker cache
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# FIX: Grant executable permission to the Maven Wrapper script
RUN chmod +x mvnw

# Fetch all dependencies. If pom.xml doesn't change, this step is cached.
# The -B flag runs Maven in non-interactive (batch) mode.
RUN ./mvnw dependency:go-offline -B

# Copy the source code
COPY src src

# Build the application (package the JAR)
# -DskipTests flag is used to speed up the build process in the container
RUN ./mvnw package -DskipTests

# ----------------------------------------------------------------------------------
# STAGE 2: RUNTIME
# Purpose: Creates the final, minimal image using a JRE for security and size.
# ----------------------------------------------------------------------------------
FROM eclipse-temurin:21-jre-alpine AS final

# CRITICAL SECURITY FIX: Update and upgrade Alpine packages to patch libpng and others.
RUN apk update && \
    apk upgrade --available && \
    rm -rf /var/cache/apk/*

# Metadata (Good practice for tracking)
LABEL maintainer="Kiran Roy"
LABEL app="bankapp"

# Set working directory for the application
WORKDIR /app

# Arguments and Environment Variables (passed from the Docker build command)
ARG GIT_REF="unknown"
ARG APP_VERSION="snapshot"
ENV GIT_REF=${GIT_REF}
ENV APP_VERSION=${APP_VERSION}

# Copy the built JAR file from the builder stage
# Uses the standard Maven default JAR name format
COPY --from=builder /build/target/bankapp-0.0.1-SNAPSHOT.jar ./bankapp.jar

# Expose application port
EXPOSE 8080

# Start the application
# Define minimum and maximum JVM memory limits for stability in a containerized environment
ENTRYPOINT ["java", "-Xms128m", "-Xmx256m", "-jar", "bankapp.jar"]