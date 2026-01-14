FROM nginx:alpine

# 기본 nginx 설정 제거
RUN rm /etc/nginx/conf.d/default.conf

# 커스텀 nginx 설정 복사
COPY nginx.conf /etc/nginx/conf.d/

# HTML 파일 복사
COPY index.html /usr/share/nginx/html/

# 포트 노출
EXPOSE 8080

# nginx 실행
CMD ["nginx", "-g", "daemon off;"]