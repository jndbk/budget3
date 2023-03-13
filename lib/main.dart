import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'categories.dart';
import 'patterns.dart';
import 'load.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBvDRJPpJyN0_b37_9p4ErnFRqfwgxWoYQ",
            authDomain: "budget-app-379022.firebaseapp.com",
            databaseURL:
                "https://budget-app-379022-default-rtdb.firebaseio.com",
            projectId: "budget-app-379022",
            storageBucket: "budget-app-379022.appspot.com",
            messagingSenderId: "44655120540",
            appId: "1:44655120540:web:1d1a3cd3ec322dd6a7dd59",
            measurementId: "G-W29GBPT2HF"));
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Expense Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var pageIndex = 0;
  var categories = <BudgetCategory>[];
  var patterns = <BudgetPattern>[];
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  DatabaseReference containerRef =
      FirebaseDatabase.instance.ref("/categories/0");
  late StreamSubscription categoryListener;
  late StreamSubscription patternListener;

  void _activateCategoryListener() {
    categoryListener = ref.child('/categories/0').onValue.listen((event) {
      if (event.snapshot.value == null) {
        setState(() {
          categories = <BudgetCategory>[];
        });
      } else {
        final data = event.snapshot.value as List;
        setState(() {
          categories = <BudgetCategory>[];
          for (var cat in data) {
            if (cat != null) {
              categories.add(
                  BudgetCategory(cat['name'], cat['ignore'], cat['onetime']));
            }
          }
        });
      }
    });
  }

  void _activatePatternListener() {
    patternListener = ref.child('/patterns/0').onValue.listen((event) {
      if (event.snapshot.value == null) {
        setState(() {
          patterns = <BudgetPattern>[];
        });
      } else {
        final data = event.snapshot.value as List;
        setState(() {
          patterns = <BudgetPattern>[];
          for (var pat in data) {
            if (pat != null) {
              patterns.add(BudgetPattern(pat['pattern'], pat['category']));
            }
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _activateCategoryListener();
    _activatePatternListener();
  }

  @override
  void deactivate() {
    categoryListener.cancel();
    super.deactivate();
  }

  void _setPageIndex(int index) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      pageIndex = index;
    });
  }

  void updateCategories() {
    const uid = 0;
    var val = {"categories": {}};
    val["categories"]?[uid] = [];
    val["categories"]?[uid].add({});
    var newCats = val["categories"]?[uid];
    for (var cat in categories) {
      newCats?.add([]);
      newCats?[newCats.length - 1] = {};
      newCats?[newCats.length - 1]["name"] = cat.name;
      newCats?[newCats.length - 1]["ignore"] = cat.ignore;
      newCats?[newCats.length - 1]["onetime"] = cat.onetime;
    }
    ref.update(val);
  }

  void updatePatterns() {
    const uid = 0;
    var val = {"patterns": {}};
    val["patterns"]?[uid] = [];
    val["patterns"]?[uid].add({});
    var newPats = val["patterns"]?[uid];
    for (var pat in patterns) {
      newPats?.add([]);
      newPats?[newPats.length - 1] = {};
      newPats?[newPats.length - 1]["pattern"] = pat.pattern;
      newPats?[newPats.length - 1]["category"] = pat.category;
    }
    ref.update(val);
  }

  void _addBudgetCategory(String name, bool ignore, bool onetime) async {
    categories.add(BudgetCategory(name, ignore, onetime));
    updateCategories();
  }

  void _deleteBudgetCategory(int index) {
    categories.removeAt(index);
    updateCategories();
  }

  void _addBudgetPattern(String pattern, String category) async {
    patterns.add(BudgetPattern(pattern, category));
    updatePatterns();
  }

  void _deleteBudgetPattern(int index) {
    patterns.removeAt(index);
    updatePatterns();
  }

  void _updateBudgetCategory(int index, int which, bool checked) {
    if (which == 0) {
      categories[index] = BudgetCategory(
          categories[index].name, checked, categories[index].onetime);
    } else {
      categories[index] = BudgetCategory(
          categories[index].name, categories[index].ignore, checked);
    }
    updateCategories();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var statusTitles = <String>[
      "Expense Summary",
      "Item Details",
      "Patterns",
      "Categories",
      "Load Expenses"
    ];
    var statusTitle = statusTitles[pageIndex];
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(statusTitle),
      ),
      body: CurrentPage(
          context,
          pageIndex,
          categories,
          patterns,
          _addBudgetCategory,
          _deleteBudgetCategory,
          _updateBudgetCategory,
          _addBudgetPattern,
          _deleteBudgetPattern),
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: Text("${statusTitles[0]}..."),
              onTap: () {
                _setPageIndex(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Item details...'),
              onTap: () {
                _setPageIndex(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Patterns...'),
              onTap: () {
                _setPageIndex(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Categories...'),
              onTap: () {
                _setPageIndex(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Load expenses...'),
              onTap: () {
                _setPageIndex(4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ));
  }
}

class CurrentPage extends StatelessWidget {
  final BuildContext context;
  final int pageIndex;
  final List<BudgetCategory> categories;
  final List<BudgetPattern> patterns;
  final Function addBudgetCategoryCallback;
  final Function deleteBudgetCategoryCallback;
  final Function updateBudgetCategoryCallback;
  final Function addBudgetPatternCallback;
  final Function deleteBudgetPatternCallback;
  const CurrentPage(
      this.context,
      this.pageIndex,
      this.categories,
      this.patterns,
      this.addBudgetCategoryCallback,
      this.deleteBudgetCategoryCallback,
      this.updateBudgetCategoryCallback,
      this.addBudgetPatternCallback,
      this.deleteBudgetPatternCallback,
      {super.key});
  final curColumn = 0;
  final curRow = 0;
  @override
  Widget build(BuildContext context) {
    if (pageIndex == 0) {
      return const PeriodTotals();
    } else if (pageIndex == 2) {
      return BudgetPatternsPage(context, categories, patterns,
          addBudgetPatternCallback, deleteBudgetPatternCallback);
    } else if (pageIndex == 3) {
      return CategoriesPage(context, categories, addBudgetCategoryCallback,
          deleteBudgetCategoryCallback, updateBudgetCategoryCallback);
    } else if (pageIndex == 4) {
      return const LoadExpensesPage();
    }
    return const Text("hi");
  }
}
