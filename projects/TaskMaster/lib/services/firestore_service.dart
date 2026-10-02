import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_item.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'todos';

  static Future<void> addTodo(TodoItem todo) async {
    try {
      await _firestore.collection(_collectionName).doc(todo.id).set(todo.toJson());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> batchAddTodos(List<TodoItem> todos) async {
    try {
      WriteBatch batch = _firestore.batch();
      for (var todo in todos) {
        batch.set(_firestore.collection(_collectionName).doc(todo.id), todo.toJson());
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateTodo(TodoItem todo) async {
    try {
      await _firestore.collection(_collectionName).doc(todo.id).update(todo.toJson());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteTodo(String todoId) async {
    try {
      await _firestore.collection(_collectionName).doc(todoId).delete();
    } catch (e) {
      rethrow;
    }
  }

  static Stream<List<TodoItem>> getTodosStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<TodoItem> todos = snapshot.docs.map((doc) {
        return TodoItem.fromJson(doc.data());
      }).toList();
      
      todos.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      
      return todos;
    });
  }

  static Future<List<TodoItem>> getTodosPaginated(
    String userId, {
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('dueDate', descending: false)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return TodoItem.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<TodoItem>> getTodos(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('dueDate', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        return TodoItem.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<DocumentSnapshot?> getLastDocument(String userId, int limit) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('dueDate', descending: false)
          .limit(limit)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.last;
    } catch (e) {
      rethrow;
    }
  }
}

