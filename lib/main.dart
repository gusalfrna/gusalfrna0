import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Todo {
  Todo({required this.id, required this.name, required this.checked});
  final String id;
  final String name;
  bool checked;

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      name: json['title'],
      checked: json['done'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'done': checked,
    };
  }
}

class TodoItem extends StatelessWidget {
  TodoItem({
    required this.todo,
    required this.onTodoChanged,
  }) : super(key: ObjectKey(todo));

  final Todo todo;
  final ValueChanged<Todo> onTodoChanged;

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTodoChanged(todo);
      },
      leading: CircleAvatar(
        child: Text(todo.name[0]),
      ),
      title: Text(todo.name, style: _getTextStyle(todo.checked)),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final TextEditingController _textFieldController = TextEditingController();
  final List<Todo> _todos = <Todo>[];
  String? _apiKey; // För att lagra API-nyckeln
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _registerAndFetchTodos();
    _loadTodos(); // Ladda todo-listan från SharedPreferences
  }

  Future<void> _registerAndFetchTodos() async {
    await _register();
    await _fetchTodos();
  }

  // Ladda todos från SharedPreferences
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todoList = prefs.getStringList('todos') ?? [];
    setState(() {
      _todos.clear();
      _todos.addAll(todoList.map((item) {
        final parts = item
            .split('|'); // Anta att du sparar varje todo som "id|name|checked"
        return Todo(
          id: parts[0],
          name: parts[1],
          checked: parts[2] == 'true',
        );
      }).toList());
    });
  }

  // Spara todos till SharedPreferences
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> todoList = _todos.map((todo) {
      return '${todo.id}|${todo.name}|${todo.checked}'; // Spara i formatet "id|name|checked"
    }).toList();
    await prefs.setStringList('todos', todoList);
  }

  Future<void> _register() async {
    final response = await http
        .get(Uri.parse("https://todoapp-api.apps.k8s.gu.se/register"));

    if (response.statusCode == 200) {
      _apiKey = response.body; // Direkt tilldela svaret som en sträng
    } else {
      // Hantera registreringsfel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to register for API key: ${response.body}')),
      );
    }
  }

  Future<void> _fetchTodos() async {
    if (_apiKey == null) return; // Ingen API-nyckel tillgänglig

    final response = await http.get(
        Uri.parse("https://todoapp-api.apps.k8s.gu.se/todos?key=$_apiKey"));

    if (response.statusCode == 200) {
      final List<dynamic> todoList = json.decode(response.body);
      setState(() {
        _todos.clear();
        _todos.addAll(todoList.map((data) => Todo.fromJson(data)).toList());
      });
    } else {
      // Hantera fel vid hämtning av todos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load todos: ${response.body}')),
      );
    }
  }

  void _handleTodoChange(Todo todo) async {
    final updatedTodo = Todo(
      id: todo.id,
      name: todo.name,
      checked: !todo.checked,
    );

    setState(() {
      todo.checked = !todo.checked;
    });

    await _saveTodos(); // Spara ändringar i todos
    // Din API-kod här för att uppdatera på servern...
  }

  void _addTodoItem(String name) async {
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Todo item cannot be empty';
      });
      return;
    }

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      checked: false,
    );

    setState(() {
      _todos.add(newTodo);
      _errorMessage = null;
    });

    await _saveTodos(); // Spara ändringar i todos
    _textFieldController.clear();
  }

  void _removeTodoItem(Todo todo) async {
    setState(() {
      _todos.remove(todo);
    });

    await _saveTodos(); // Spara ändringar i todos
    // Din API-kod här för att ta bort från servern...
  }

  Future<void> _displayDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a new todo item'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Type your new todo'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
                _addTodoItem(_textFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tig333 Todo list'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: _todos.map((Todo todo) {
                return Dismissible(
                  key: Key(todo.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) {
                    _removeTodoItem(todo);
                  },
                  child: TodoItem(
                    todo: todo,
                    onTodoChanged: _handleTodoChange,
                  ),
                );
              }).toList(),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(),
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Todo list',
      home: TodoList(),
    );
  }
}

void main() {
  runApp(const TodoApp());
}
