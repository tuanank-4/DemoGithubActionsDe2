# =============================================
# Stage 1: BUILD - Biên dịch ứng dụng Spring Boot
# =============================================
FROM maven:3.9.12-eclipse-temurin-17 AS builder

LABEL authors="TDat"

WORKDIR /app

# Copy pom.xml trước để tận dụng Docker layer cache
# (Chỉ tải lại dependencies khi pom.xml thay đổi)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy toàn bộ source code và build
COPY src ./src
RUN mvn clean package -DskipTests -B

# =============================================
# Stage 2: RUNTIME - Chạy ứng dụng
# =============================================
FROM eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# Tạo user không phải root để tăng bảo mật
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy file JAR đã build từ stage 1
COPY --from=builder /app/target/*.jar app.jar

# Đổi quyền sở hữu file
RUN chown appuser:appgroup app.jar

# Chuyển sang user không phải root
USER appuser

# Mở cổng ứng dụng Spring Boot (mặc định 8080)
EXPOSE 8080

# Cấu hình JVM tối ưu cho container
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport"

# Khởi động ứng dụng
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
