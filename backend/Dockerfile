# Build backend TimeTribe thành file chạy tĩnh rồi chép sang image nhỏ (~25 MB).
# Render: file render.yaml ở gốc repo trỏ tới Dockerfile này (xem docs/DEPLOY.md).
# Render tự đặt biến PORT, server đọc biến đó nên không cần cấu hình cổng.
# Chạy thử ở máy:  docker build -t timetribe-api .  &&  docker run --env-file .env -p 8080:8080 timetribe-api

FROM golang:1.23-alpine AS build
WORKDIR /src
# Tải thư viện trước để Docker cache lại, sửa code không phải tải lại
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN mkdir -p public
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server \
 && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/seed ./cmd/seed

FROM alpine:3.20
# ca-certificates: kết nối TLS tới MongoDB Atlas, Firebase, Cloudinary
RUN apk add --no-cache ca-certificates \
 && adduser -D -H -u 10001 app
WORKDIR /app
COPY --from=build /out/server /out/seed /app/
# File APK cho GET /download: đặt ở backend/public/timetribe.apk trước khi build (không có cũng được)
COPY --from=build /src/public/ /app/public/
USER app
ENV APP_ENV=production \
    PORT=8080 \
    GIN_MODE=release
EXPOSE 8080
CMD ["/app/server"]
