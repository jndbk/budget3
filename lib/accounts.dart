import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:budget3/sophtron_api.dart';

class BudgetUserInfo extends Object {
  Map<String, AccountInfo> accounts = {};
}

class LoadAccountsParams extends Object {
  final Function addBankCb;
  final Function transactionsCb;
  final Function accountCb;
  final BudgetUserInfo userInfo;
  final Map<String, UserInstitutionInfo> userInstitutionInfo;
  const LoadAccountsParams(this.addBankCb, this.transactionsCb, this.accountCb,
      this.userInfo, this.userInstitutionInfo);
}

class LoadAccountsPage extends StatefulWidget {
  late final BuildContext context;
  late final Function addBankCb;
  late final Function accountCb;
  late final Function transactionsCb;
  late final BudgetUserInfo userInfo;
  late final Map<String, UserInstitutionInfo> userInstitutionInfo;
  LoadAccountsPage(BuildContext contextIn, LoadAccountsParams params,
      {super.key}) {
    context = contextIn;
    addBankCb = params.addBankCb;
    accountCb = params.accountCb;
    transactionsCb = params.transactionsCb;
    userInfo = params.userInfo;
    userInstitutionInfo = params.userInstitutionInfo;
  }

  @override
  State<LoadAccountsPage> createState() => _LoadAccountsPageState();
}

class _LoadAccountsPageState extends State<LoadAccountsPage> {
  List<InstitutionInfo> institutionChoices = <InstitutionInfo>[];
  bool showSearch = false;
  String curName = '';
  String selectedBank = '';
  InstitutionInfo selectedBankInfo = InstitutionInfo('', '', '', [], '', '');
  Map<String, String> loginFields = {};

  void addBank() {
    newAccount(selectedBankInfo, widget.addBankCb, widget.accountCb,
        widget.transactionsCb);
    setState(() {
      showSearch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration:
              BoxDecoration(border: Border.all(color: Colors.blueAccent)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Accounts', style: TextStyle(fontSize: 22)),
              ),
              IconButton(onPressed: addAccount, icon: const Icon(Icons.add)),
            ],
          ),
        ),
        if (showSearch)
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (text) => {selectedBank = '', curName = text},
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Bank/Credit Card Company Name"),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: onSearch,
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (showSearch && institutionChoices.isNotEmpty)
          bankNameDropdown(null, bankSelected),
        if (showSearch)
          Column(
            children: [
              for (var loginField in selectedBankInfo.loginFields)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (text) => {loginFields[loginField = text]},
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: loginField),
                  ),
                ),
              if (showSearch)
                ElevatedButton(onPressed: addBank, child: const Text('Add')),
            ],
          ),
        for (var account in widget.userInfo.accounts.values)
          Row(
            children: [
              if (account.logo != null) Image.network(account.logo as String),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(account.name),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget
                    .userInstitutionInfo[account.userInstitutionId]!.name),
              ),
            ],
          )
      ],
    );
  }

  void onSearch() {
    getInstitutions(curName);
  }

  void getInstitutions(String? name) async {
    if (name == null) {
      return;
    }
    var result = await makeConnection(
        'https://api.sophtron.com/api/Institution/GetInstitutionByName',
        <String, String>{
          "InstitutionName": name,
          "Extensive": "true",
          "InstitutionType": "All"
        });
    var info = jsonDecode(result.body);
    List<InstitutionInfo> choices = [];
    for (var inst in info) {
      List<String> loginFields = [];
      for (var field in inst['InstitutionDetail']['LoginFormFields']) {
        loginFields.add(field['MappedField']);
      }
      choices.add(InstitutionInfo(inst['InstitutionID'],
          inst['InstitutionName'], inst['Logo'], loginFields, '', ''));
    }
    setState(() {
      institutionChoices = choices;
    });
    if (kDebugMode) {
      print(info);
    }
  }

  void addAccount() {
    setState(() {
      showSearch = true;
    });
  }

  void bankSelected(String value) {
    setState(() {
      selectedBank = value;
      for (var inst in institutionChoices) {
        if (inst.name == value) {
          selectedBankInfo = inst;
        }
      }
    });
  }

  DropdownButton<String> bankNameDropdown(
      String? initialValue, Function callback) {
    List<String> dropList = [];
    for (var bank in institutionChoices) {
      dropList.add(bank.name);
    }
    dropList.sort();
    if (selectedBank.isNotEmpty) {
      initialValue = selectedBank;
    } else if (institutionChoices.isNotEmpty) {
      initialValue = institutionChoices[0].name;
    }
    return DropdownButton<String>(
        menuMaxHeight: 300,
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
          setState(() {
            initialValue = value;
          });
        },
        items: dropList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList());
  }
}
