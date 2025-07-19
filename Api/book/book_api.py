# book_api.py
from flask import Blueprint, request, jsonify
from models import db, Book

book_api = Blueprint('book_api', __name__)

# 📘 전체 조회
@book_api.route('/books', methods=['GET'])
def get_books():
    """
    전체 Book 목록 조회
    ---
    tags:
      - GET: Books
    responses:
      200:
        description: 전체 목록 조회 성공
    """
    books = Book.query.all()
    return jsonify([book.to_dict() for book in books])

# 📘 단일 조회
@book_api.route('/books/<int:book_id>', methods=['GET'])
def get_book(book_id):
    """
    특정 Book 조회
    ---
    tags:
      - GET: Books
    parameters:
      - in: path
        name: book_id
        required: true
        type: integer
    responses:
      200:
        description: 조회 성공
      404:
        description: 해당 ID 없음
    """
    book = Book.query.get(book_id)
    if not book:
        return jsonify({"error": "Book not found"}), 404
    return jsonify(book.to_dict())

# 📘 제목 키워드로 검색
@book_api.route('/books/search', methods=['GET'])
def search_books_by_title():
    """
    책 제목으로 검색
    ---
    tags:
      - GET: Books
    parameters:
      - in: query
        name: title
        required: true
        type: string
    responses:
      200:
        description: 검색 결과 반환
    """
    keyword = request.args.get('title')
    if not keyword:
        return jsonify({"error": "title 쿼리 파라미터가 필요합니다"}), 400

    books = Book.query.filter(Book.title.contains(keyword)).all()
    return jsonify([book.to_dict() for book in books])


# 📘 생성
@book_api.route('/books', methods=['POST'])
def create_book():
    """
    Book 추가
    ---
    tags:
      - Books
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - title
          properties:
            title:
              type: string
            is_discontinued:
              type: boolean
            category:
              type: string
            rating:
              type: number
            quantity:
              type: integer
    responses:
      201:
        description: 생성 성공
    """
    data = request.json
    book = Book(
        title=data['title'],
        is_discontinued=data.get('is_discontinued', False),
        category=data.get('category'),
        rating=data.get('rating'),
        quantity=data.get('quantity')
    )
    db.session.add(book)
    db.session.commit()
    return jsonify(book.to_dict()), 201

# 📘 수정
@book_api.route('/books/<int:book_id>', methods=['PUT'])
def update_book(book_id):
    """
    Book 수정
    ---
    tags:
      - Books
    parameters:
      - name: book_id
        in: path
        required: true
        type: integer
      - in: body
        name: body
        schema:
          type: object
          properties:
            title:
              type: string
            is_discontinued:
              type: boolean
            category:
              type: string
            rating:
              type: number
            quantity:
              type: integer
    responses:
      200:
        description: 수정 성공
    """
    book = Book.query.get(book_id)
    if not book:
        return jsonify({"error": "Not found"}), 404

    data = request.json
    book.title = data.get('title', book.title)
    book.is_discontinued = data.get('is_discontinued', book.is_discontinued)
    book.category = data.get('category', book.category)
    book.rating = data.get('rating', book.rating)
    book.quantity = data.get('quantity', book.quantity)
    db.session.commit()
    return jsonify(book.to_dict())

# 📘 삭제
@book_api.route('/books/<int:book_id>', methods=['DELETE'])
def delete_book(book_id):
    """
    Book 삭제
    ---
    tags:
      - Books
    parameters:
      - name: book_id
        in: path
        required: true
        type: integer
    responses:
      204:
        description: 삭제 성공
    """
    book = Book.query.get(book_id)
    if not book:
        return jsonify({"error": "Not found"}), 404

    db.session.delete(book)
    db.session.commit()
    return '', 204
