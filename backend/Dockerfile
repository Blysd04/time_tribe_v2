# Build backend TimeTribe thành file chạy tĩnh rồi chép sang image nhỏ (~25 MB).
# Zeabur: tạo service từ GitHub, đặt Root Directory = backend, Zeabur tự dùng Dockerfile này.
# Chạy thử ở máy:  docker build -t timetribe-api .  &&  docker run --env-file .env -p 8080:8080 timetribe-api

FROM golang:1.23-alpine AS build
WORKDIR /src
# Tải thư viện trước để Docker cache lại, sửa code không phải tải lại
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server \
 && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/seed ./cmd/seed

FROM alpine:3.20
# ca-certificates: kết nối TLS tới MongoDB Atlas, Firebase, Cloudinary
RUN apk add --no-cache ca-certificates \
 && adduser -D -H -u 10001 app
WORKDIR /app
COPY --from=build /out/server /out/seed /app/
USER app
ENV APP_ENV=production \
    PORT=8080 \
    GIN_MODE=release
EXPOSE 8080
CMD ["/app/server"]
