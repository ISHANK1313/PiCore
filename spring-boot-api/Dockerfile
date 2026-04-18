# PiCore — Spring Boot API Dockerfile
# Multi-stage build for ARM64 (Raspberry Pi 4)

# Stage 1: Build
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
# Download dependencies first (Docker layer cache optimisation)
RUN mvn dependency:go-offline -B
COPY src/ src/
RUN mvn package -DskipTests -B

# Stage 2: Runtime (minimal JRE)
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Create non-root user
RUN groupadd -r nasapi && useradd -r -g nasapi nasapi

COPY --from=builder /app/target/nas-api-*.jar app.jar

# JVM flags optimised for ARM64 with 180MB heap limit
ENV JAVA_OPTS="-Xmx180m -Xms64m -XX:+UseSerialGC -XX:MaxRAM=200m -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8085

# Run as non-root (requires volume mounts with correct permissions)
USER nasapi

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
