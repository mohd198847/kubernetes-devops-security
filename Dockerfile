FROM adoptopenjdk/openjdk8:alpine-slim
EXPOSE 8080
ARG JAR_FILE=target/*.jar
CopY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
