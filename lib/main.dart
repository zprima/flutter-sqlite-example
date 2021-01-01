import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDB {
  AppDB._();
  static final AppDB instance = AppDB._();

  Database _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = await _createDB();
    }

    return _database;
  }

  Future<Database> _createDB() async {
    return openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'flutter_user_database.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          '''
          CREATE TABLE $DB_USER_TABLE(
            $DB_ID INTEGER PRIMARY KEY,
            $DB_USER_FIRST_NAME VARCHAR(255),
            $DB_USER_LAST_NAME VARCHAR(255)
          )
          ''',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  static const DB_ID = 'id';

  static const DB_USER_TABLE = 'users';
  static const DB_USER_FIRST_NAME = 'first_name';
  static const DB_USER_LAST_NAME = 'last_name';
}

class User {
  int id;
  String firstName;
  String lastName;

  User({this.id, this.firstName, this.lastName});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      AppDB.DB_USER_FIRST_NAME: firstName,
      AppDB.DB_USER_LAST_NAME: lastName
    };

    if (id != null) map[AppDB.DB_ID] = id;

    return map;
  }

  User.fromMap(Map<String, dynamic> map) {
    id = map[AppDB.DB_ID];
    firstName = map[AppDB.DB_USER_FIRST_NAME];
    lastName = map[AppDB.DB_USER_LAST_NAME];
  }

  String fullName() {
    return "$firstName $lastName";
  }
}

class UserRepo {
  Future<int> insert(User user) async {
    final Database db = await AppDB.instance.database;

    return await db.insert(AppDB.DB_USER_TABLE, user.toMap());
  }

  Future<List<User>> all() async {
    final Database db = await AppDB.instance.database;

    final List<Map<String, dynamic>> usersMap =
        await db.query(AppDB.DB_USER_TABLE);

    return List.generate(usersMap.length, (i) {
      return User.fromMap(usersMap[i]);
    });
  }

  Future<int> remove(int id) async {
    final Database db = await AppDB.instance.database;

    return await db
        .delete(AppDB.DB_USER_TABLE, where: 'id = ?', whereArgs: [id]);
  }
}

class ViewModel extends ChangeNotifier {
  final UserRepo _userRepo = UserRepo();

  List<User> users = List<User>();

  ViewModel() {
    refresh();
  }

  void all() async {
    users = await _userRepo.all();
    notifyListeners();
  }

  void refresh() {
    all();
  }

  void add(String firstName, String lastName) async {
    User user = User(firstName: firstName, lastName: lastName);
    await _userRepo.insert(user);
    refresh();
  }

  void remove(int id) async {
    await _userRepo.remove(id);
    refresh();
  }

  void removeLast() async {
    if (users.length - 1 <= 0) {
      return;
    }

    remove(users.last.id);
  }
}

void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ViewModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: HomePageContent(),
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ViewModel>(context);

    return Column(
      children: [
        FlatButton(
          onPressed: () {
            vm.add("M", "A");
          },
          child: Text("Add"),
        ),
        FlatButton(
          onPressed: () {
            vm.removeLast();
          },
          child: Text("Remove"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: vm.users.length,
            itemBuilder: (_, index) {
              User _user = vm.users[index];

              return ListTile(
                title: Text(_user.fullName()),
              );
            },
          ),
        ),
      ],
    );
  }
}
