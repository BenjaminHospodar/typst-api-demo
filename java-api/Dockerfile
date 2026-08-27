FROM gradle:8.7-jdk21-alpine AS build
WORKDIR /workspace
COPY java-api /workspace/java-api
COPY openapi/openapi.yaml /workspace/openapi/openapi.yaml
COPY rust-compiler/proto /workspace/rust-compiler/proto
WORKDIR /workspace/java-api
RUN chmod +x gradlew
RUN ./gradlew bootJar --no-daemon --no-watch-fs

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /workspace/java-api/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
