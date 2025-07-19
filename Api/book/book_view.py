# book_view.py
from flask import Blueprint, request, redirect, url_for, render_template_string
from models import db, Book

book_view = Blueprint('book_view', __name__)

@book_view.route('/bookview', methods=['GET', 'POST'])
def view_books():
    # ✅ 추가 (POST)
    if request.method == 'POST':
        title = request.form.get('title')
        is_discontinued = request.form.get('is_discontinued') == 'on'
        category = request.form.get('category')
        rating = float(request.form.get('rating')) if request.form.get('rating') else None
        quantity = int(request.form.get('quantity')) if request.form.get('quantity') else None

        if title:
            new_book = Book(
                title=title,
                is_discontinued=is_discontinued,
                category=category,
                rating=rating,
                quantity=quantity
            )
            db.session.add(new_book)
            db.session.commit()
        return redirect(url_for('book_view.view_books'))

    # ✅ 검색 (GET)
    query = request.args.get('query', '')
    if query:
        books = Book.query.filter(Book.title.contains(query)).all()
    else:
        books = Book.query.all()

    # ✅ HTML
    html = """
    <!doctype html>
    <html>
    <head>
        <title>📚 Book 목록</title>
        <style>
            body { font-family: Arial; padding: 2em; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 2em; }
            th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
            th { background-color: #f5f5f5; }
        </style>
    </head>
    <body>
        <h2>📚 Book 목록</h2>

        <!-- 검색 -->
        <form method="get" style="margin-bottom: 1em;">
            <input type="text" name="query" placeholder="제목 검색" value="{{ request.args.get('query', '') }}">
            <button type="submit">검색</button>
            <a href="/bookview"><button type="button">초기화</button></a>
        </form>

        <!-- 추가 -->
        <form method="post" style="margin-bottom: 2em;">
            <input type="text" name="title" placeholder="제목" required>
            <input type="text" name="category" placeholder="분류">
            <input type="number" step="0.1" name="rating" placeholder="별점">
            <input type="number" name="quantity" placeholder="권수">
            <label><input type="checkbox" name="is_discontinued"> 절판</label>
            <button type="submit">추가</button>
        </form>

        <!-- 테이블 -->
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>제목</th>
                    <th>절판</th>
                    <th>분류</th>
                    <th>별점</th>
                    <th>권수</th>
                    <th>생성일</th>
                    <th>수정일</th>
                    <th>수정</th>
                    <th>삭제</th>
                </tr>
            </thead>
            <tbody>
                {% for book in books %}
                <tr>
                    <form method="post" action="{{ url_for('book_view.update_book_html', book_id=book.id) }}">
                        <td>{{ book.id }}</td>
                        <td><input type="text" name="title" value="{{ book.title }}"></td>
                        <td><input type="checkbox" name="is_discontinued" {% if book.is_discontinued %}checked{% endif %}></td>
                        <td><input type="text" name="category" value="{{ book.category or '' }}"></td>
                        <td><input type="number" step="0.1" name="rating" value="{{ book.rating or '' }}"></td>
                        <td><input type="number" name="quantity" value="{{ book.quantity or '' }}"></td>
                        <td>{{ book.created_at.strftime("%Y-%m-%d %H:%M:%S") }}</td>
                        <td>{{ book.updated_at.strftime("%Y-%m-%d %H:%M:%S") }}</td>
                        <td><button type="submit" name="action" value="update">수정</button></td>
                        <td><button type="submit" name="action" value="delete">삭제</button></td>
                    </form>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    </body>
    </html>
    """
    return render_template_string(html, books=books)

@book_view.route('/bookview/update/<int:book_id>', methods=['POST'])
def update_book_html(book_id):
    book = Book.query.get(book_id)
    if not book:
        return redirect(url_for('book_view.view_books'))

    action = request.form.get('action')
    if action == 'update':
        book.title = request.form.get('title')
        book.is_discontinued = request.form.get('is_discontinued') == 'on'
        book.category = request.form.get('category')
        book.rating = float(request.form.get('rating')) if request.form.get('rating') else None
        book.quantity = int(request.form.get('quantity')) if request.form.get('quantity') else None
        db.session.commit()
    elif action == 'delete':
        db.session.delete(book)
        db.session.commit()

    return redirect(url_for('book_view.view_books'))
