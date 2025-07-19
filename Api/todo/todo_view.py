# todo_view.py
from flask import Blueprint, request, redirect, url_for, render_template_string
from models import db, Todo

todo_view = Blueprint('todo_view', __name__)

@todo_view.route('/view', methods=['GET', 'POST'])
def view_todos():
    # ✅ 추가: POST → 새 항목 생성
    if request.method == 'POST':
        title = request.form.get('title')
        is_done = request.form.get('is_done') == 'on'
        if title:
            new_todo = Todo(title=title, is_done=is_done)
            db.session.add(new_todo)
            db.session.commit()
        return redirect(url_for('view_todos'))

    # ✅ 추가: GET → 검색어 필터링
    query = request.args.get('query', '')
    if query:
        todos = Todo.query.filter(Todo.title.contains(query)).all()
    else:
        todos = Todo.query.all()

    # ✅ HTML 출력
    html = """
    <!doctype html>
    <html>
    <head>
        <title>Todo 목록 보기</title>
        <style>
            body { font-family: Arial; padding: 2em; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 2em; }
            th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
            th { background-color: #f5f5f5; }
            form.inline { display: inline; }
        </style>
    </head>
    <body>
        <h2>📝 Todo 목록</h2>

        <!-- ✅ 검색 폼 -->
        <form method="get" style="margin-bottom: 1.5em;">
            <input type="text" name="query" placeholder="검색어 입력" value="{{ request.args.get('query', '') }}">
            <button type="submit">검색</button>
            <a href="/view"><button type="button">초기화</button></a>
        </form>

        <!-- ✅ 추가 폼 -->
        <form method="post" style="margin-bottom: 2em;">
            <input type="text" name="title" placeholder="할 일 제목" required>
            <label><input type="checkbox" name="is_done"> 완료</label>
            <button type="submit">추가</button>
        </form>

        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>제목</th>
                    <th>완료 여부</th>
                    <th>생성일</th>
                    <th>수정일</th>
                    <th>수정</th>
                    <th>삭제</th>
                </tr>
            </thead>
            <tbody>
                {% for todo in todos %}
                <tr>
                    <form method="post" action="{{ url_for('todo_view.update_todo_html', todo_id=todo.id) }}">
                        <td>{{ todo.id }}</td>
                        <td><input type="text" name="title" value="{{ todo.title }}"></td>
                        <td><input type="checkbox" name="is_done" {% if todo.is_done %}checked{% endif %}></td>
                        <td>{{ todo.created_at.strftime("%Y-%m-%d %H:%M:%S") }}</td>
                        <td>{{ todo.updated_at.strftime("%Y-%m-%d %H:%M:%S") }}</td>
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
    return render_template_string(html, todos=todos)

@todo_view.route('/update/<int:todo_id>', methods=['POST'])
def update_todo_html(todo_id):
    todo = Todo.query.get(todo_id)
    if not todo:
        return redirect(url_for('view_todos'))

    action = request.form.get('action')
    if action == 'update':
        todo.title = request.form.get('title')
        todo.is_done = request.form.get('is_done') == 'on'
        db.session.commit()
    elif action == 'delete':
        db.session.delete(todo)
        db.session.commit()
    
    return redirect(url_for('view_todos'))