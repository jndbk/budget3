import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_sticky_headers/table_sticky_headers.dart';

class BudgetCategory extends Object {
  String name = '';
  bool ignore = false;
  bool onetime = false;
  BudgetCategory(this.name, this.ignore, this.onetime);
}

class CategoriesPage extends StatelessWidget {
  final BuildContext context;
  final List<BudgetCategory> categories;
  final Function addBudgetCategoryCallback;
  final Function deleteBudgetCategoryCallback;
  final Function updateBudgetCategoryCallback;
  const CategoriesPage(
    this.context,
    this.categories,
    this.addBudgetCategoryCallback,
    this.deleteBudgetCategoryCallback,
    this.updateBudgetCategoryCallback, {
    super.key,
  });

  void addBudgetCategoryCb(String name, bool ignore, bool onetime) {
    addBudgetCategoryCallback(name, ignore, onetime);
  }

  void updateBudgetCategoryCb(
      int index, String name, bool ignore, bool onetime) {
    updateBudgetCategoryCallback(name, ignore, onetime);
  }

  void onCheckChange(bool? checked, int col, int row) {
    if (kDebugMode) {
      print("Checked: $col $row $checked");
    }
    updateBudgetCategoryCallback(row, col, checked);
  }

  void onPressed(int row) {
    if (kDebugMode) {
      print("row$row");
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleColumn = <String>[
      "Hide",
      "Onetime",
      "",
    ];
    var numCategories = categories.length;
    var titleRow = <String>[];
    for (var i = 0; i < numCategories; i++) {
      titleRow.add(categories[i].name);
    }
    var data = [];
    data.add([]);
    for (var i = 0; i < numCategories; i++) {
      data[0].add(Checkbox(
        value: categories[i].ignore,
        onChanged: (check) => onCheckChange(check, 0, i),
      ));
    }
    data.add([]);
    for (var i = 0; i < numCategories; i++) {
      data[1].add(Checkbox(
        value: categories[i].onetime,
        onChanged: (check) => onCheckChange(check, 1, i),
      ));
    }
    void onDelete(int i) {
      deleteBudgetCategoryCallback(i);
    }

    data.add([]);
    for (var i = 0; i < numCategories; i++) {
      data[2].add(IconButton(
          onPressed: () => onDelete(i), icon: const Icon(Icons.delete)));
    }
    data.add([]);
    for (var i = 0; i < numCategories; i++) {
      data[3].add(const Text(""));
    }
    Widget getColumn(int i) {
      if (i < titleColumn.length) {
        return Text(titleColumn[i]);
      } else {
        return IconButton(
            onPressed: addBudgetCategory, icon: const Icon(Icons.add));
      }
    }

    return StickyHeadersTable(
      columnsLength: titleColumn.length + 1,
      rowsLength: titleRow.length,
      columnsTitleBuilder: (i) => getColumn(i),
      rowsTitleBuilder: (i) => Text(titleRow[i]),
      contentCellBuilder: (i, j) => data[i][j],
      legendCell: const Text('BudgetCategory'),
    );
  }

  void addBudgetCategory() {
    bool? curIgnore = false;
    bool? curOnetime = false;
    String? curName = '';
    void ignoreChecked(bool? checked) {
      curIgnore = checked;
    }

    void onetimeChecked(bool? checked) {
      curOnetime = checked;
    }

    void onAdd() {
      addBudgetCategoryCallback(curName, curIgnore, curOnetime);
      Navigator.pop(context);
    }

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setState /*You can rename this!*/) {
            return Center(
                child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (text) => {curName = text},
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "BudgetCategory Name"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text("Hide"),
                      Checkbox(
                          value: curIgnore,
                          onChanged: (check) {
                            setState(() {
                              ignoreChecked(check);
                            });
                          }),
                      const Text(
                        "Onetime",
                      ),
                      Checkbox(
                          value: curOnetime,
                          onChanged: (check) {
                            setState(() {
                              onetimeChecked(check);
                            });
                          }),
                      ElevatedButton(
                        onPressed: onAdd,
                        child: const Text('Add'),
                      )
                    ],
                  ),
                ),
              ],
            ));
          });
        });
  }
}

class PeriodTotals extends StatelessWidget {
  const PeriodTotals({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const titleColumn = <String>[
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "June",
      "July",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    var titleRow = <String>[];
    for (var i = 0; i < 40; i++) {
      titleRow.add("BudgetCategory$i");
    }
    var data = List.generate(
        titleColumn.length, (_) => List.filled(titleRow.length, "xx"));
    return StickyHeadersTable(
      columnsLength: titleColumn.length,
      rowsLength: titleRow.length,
      columnsTitleBuilder: (i) => Text(titleColumn[i]),
      rowsTitleBuilder: (i) => Text(titleRow[i]),
      contentCellBuilder: (i, j) => Text(data[i][j]),
      legendCell: const Text(''),
    );
  }
}
