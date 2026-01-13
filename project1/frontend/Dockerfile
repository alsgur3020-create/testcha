FROM nginx:alpine

# Copy static files
COPY index.html /usr/share/nginx/html/

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# nginx는 기본적으로 root로 실행되지만, worker process는 nginx 사용자로 실행됩니다.
# 보안을 위해 필요한 권한만 설정
RUN chown -R nginx:nginx /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]