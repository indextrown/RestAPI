# Dockerfile
FROM python:3.9-slim

# 작업 디렉토리
WORKDIR /app

# 종속성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 복사
COPY . .

# 포트 열기
EXPOSE 7000

# 앱 실행
CMD ["python", "app.py"]


# 빌드
# docker build -t api-app .

# 실행 (app.db는 컨테이너 내에 생성됨)
# docker run -d -p 6000:6000 --name api api-app

# 6. 데이터 유지하려면 볼륨 사용 (선택)
# docker run -d -p 6000:6000 \
#   -v $(pwd)/instance:/app/instance \
#   --name flask-todo flask-todo-app

