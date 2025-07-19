# python app.py
# http://127.0.0.1:5000/apidocs/
# http://127.0.0.1:5000/view

# app.py
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flasgger import Swagger
from models import db  # ✅ 이미 생성된 db 가져오기
from todo.todo_api import todo_api
from todo.todo_view import todo_view 
from book.book_api import book_api 
from book.book_view import book_view


app = Flask(__name__)
swagger = Swagger(app)

# ✅ SQLite 설정
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///app.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# ✅ 기존 db 인스턴스에 Flask 앱 연결
db.init_app(app)

# ✅ DB 테이블 생성
with app.app_context():
    db.create_all()

# ✅ 블루프린트 등록
app.register_blueprint(todo_api)
app.register_blueprint(todo_view)  
app.register_blueprint(book_api)
app.register_blueprint(book_view)

# ✅ 서버 실행
if __name__ == '__main__':
   # app.py
    app.run(host='0.0.0.0', port=7000)

