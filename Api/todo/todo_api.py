# todo_api.py
from flask import Blueprint, request, jsonify
from models import db, Todo

todo_api = Blueprint('todo_api', __name__)

# ✅ 목록 조회
@todo_api.route('/todos', methods=['GET'])
def get_todos():
    """
    전체 Todo 목록 조회
    ---
    tags:
      - GET: Todos
    responses:
      200:
        description: 목록 조회 성공
    """
    todos = Todo.query.all()
    return jsonify([todo.to_dict() for todo in todos])

@todo_api.route('/todos/<int:todo_id>', methods=['GET'])
def get_todo_by_id(todo_id):
    """
    특정 Todo 조회
    ---
    tags:
      - GET: Todos
    parameters:
      - in: path
        name: todo_id
        required: true
        type: integer
    responses:
      200:
        description: 조회 성공
        schema:
          type: object
          properties:
            id:
              type: integer
            title:
              type: string
            is_done:
              type: boolean
            created_at:
              type: string
            updated_at:
              type: string
      404:
        description: Todo를 찾을 수 없음
    """
    todo = Todo.query.get(todo_id)
    if not todo:
        return jsonify({"error": "Todo not found"}), 404
    return jsonify(todo.to_dict())

@todo_api.route('/todos/search', methods=['GET'])
def search_todos_by_title():
    """
    제목 키워드로 Todo 검색
    ---
    tags:
      - GET: Todos
    parameters:
      - in: query
        name: title
        required: true
        type: string
    responses:
      200:
        description: 검색 결과
        schema:
          type: array
          items:
            type: object
            properties:
              id:
                type: integer
              title:
                type: string
              is_done:
                type: boolean
              created_at:
                type: string
              updated_at:
                type: string
    """
    keyword = request.args.get('title')
    if not keyword:
        return jsonify({"error": "title 쿼리 파라미터를 제공해주세요"}), 400

    results = Todo.query.filter(Todo.title.contains(keyword)).all()
    return jsonify([todo.to_dict() for todo in results])


# ✅ 생성
@todo_api.route('/todos', methods=['POST'])
def create_todo():
    """
    Todo 추가
    ---
    tags:
      - Todos
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
            is_done:
              type: boolean
    responses:
      201:
        description: 생성 성공
    """
    data = request.json
    todo = Todo(title=data["title"], is_done=data.get("is_done", False))
    db.session.add(todo)
    db.session.commit()
    return jsonify(todo.to_dict()), 201

# ✅ 수정
@todo_api.route('/todos/<int:todo_id>', methods=['PUT'])
def update_todo(todo_id):
    """
    Todo 수정
    ---
    tags:
      - Todos
    parameters:
      - name: todo_id
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
            is_done:
              type: boolean
    responses:
      200:
        description: 수정 성공
    """
    todo = Todo.query.get(todo_id)
    if not todo:
        return jsonify({"error": "Not found"}), 404

    data = request.json
    todo.title = data.get("title", todo.title)
    todo.is_done = data.get("is_done", todo.is_done)
    db.session.commit()
    return jsonify(todo.to_dict())

# ✅ 삭제
@todo_api.route('/todos/<int:todo_id>', methods=['DELETE'])
def delete_todo(todo_id):
    """
    Todo 삭제
    ---
    tags:
      - Todos
    parameters:
      - name: todo_id
        in: path
        required: true
        type: integer
    responses:
      204:
        description: 삭제 성공
    """
    todo = Todo.query.get(todo_id)
    if not todo:
        return jsonify({"error": "Not found"}), 404

    db.session.delete(todo)
    db.session.commit()
    return '', 204

