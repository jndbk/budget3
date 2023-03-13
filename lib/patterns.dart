import 'package:budget3/categories.dart';
import 'package:flutter/material.dart';
import 'package:table_sticky_headers/table_sticky_headers.dart';

class BudgetPattern extends Object {
  String pattern;
  String category;
  BudgetPattern(this.pattern, this.category);
}

class BudgetPatternsPage extends StatelessWidget {
  final BuildContext context;
  final List<BudgetCategory> categories;
  final List<BudgetPattern> patterns;
  final Function addBudgetPatternCallback;
  final Function deleteBudgetPatternCallback;
  const BudgetPatternsPage(this.context, this.categories, this.patterns,
      this.addBudgetPatternCallback, this.deleteBudgetPatternCallback,
      {super.key});

  void addBudgetPatternCb(String pattern, String category) {
    addBudgetPatternCallback(pattern, category);
  }

  @override
  Widget build(BuildContext context) {
    const columnHeaders = <String>[
      "Category",
      "",
    ];
    var numBudgetPatterns = patterns.length;
    var rowFirstColumn = <String>[];
    for (var i = 0; i < numBudgetPatterns; i++) {
      rowFirstColumn.add(patterns[i].pattern);
    }
    var data = [];
    data.add([]);
    var column = 0;

    //String curCategory;
    for (var i = 0; i < numBudgetPatterns; i++) {
      data[column].add(categoryDropdown(patterns[i].category, (value) {
        //curCategory = value;
      }));
    }
    void onDelete(int i) {
      deleteBudgetPatternCallback(i);
    }

    data.add([]);
    column++;
    for (var i = 0; i < numBudgetPatterns; i++) {
      data[column].add(IconButton(
          onPressed: () => onDelete(i), icon: const Icon(Icons.delete)));
    }
    data.add([]);
    column++;
    for (var i = 0; i < numBudgetPatterns; i++) {
      data[column].add(const Text(""));
    }
    Widget getColumn(int i) {
      if (i < columnHeaders.length) {
        return Text(columnHeaders[i]);
      } else {
        return IconButton(
            onPressed: addBudgetPattern, icon: const Icon(Icons.add));
      }
    }

    return StickyHeadersTable(
      columnsLength: columnHeaders.length + 1,
      rowsLength: rowFirstColumn.length,
      columnsTitleBuilder: (i) => getColumn(i),
      rowsTitleBuilder: (i) => Text(rowFirstColumn[i]),
      contentCellBuilder: (i, j) => data[i][j],
      legendCell: const Text('Pattern'),
    );
  }

  DropdownButton<String> categoryDropdown(
      String initialValue, Function callback) {
    List<String> dropList = [];
    for (var cat in categories) {
      dropList.add(cat.name);
    }
    dropList.sort();
    return DropdownButton<String>(
        value: initialValue,
        icon: const Icon(Icons.arrow_downward),
        elevation: 16,
        style: const TextStyle(color: Colors.deepPurple),
        underline: Container(
          height: 2,
          color: Colors.deepPurpleAccent,
        ),
        onChanged: (String? value) {
          // This is called when the user selects an item.
          callback(value);
          value = value;
        },
        items: dropList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList());
  }

  void addBudgetPattern() {
    String? curCategory = categories[0].name;
    String? curPattern = '';
    void onAdd() {
      addBudgetPatternCallback(curPattern, curCategory);
      Navigator.pop(context);
    }

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setState /*You can rename this!*/) {
            return Expanded(
              child: Column(
                children: [
                  TextField(
                    onChanged: (text) => {curPattern = text},
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "BudgetPattern Name"),
                  ),
                  Row(
                    children: [
                      categoryDropdown(curCategory!, (value) {
                        setState(() {
                          curCategory = value;
                        });
                      }),
                      ElevatedButton(
                        onPressed: onAdd,
                        child: const Text('Add'),
                      )
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }
}
