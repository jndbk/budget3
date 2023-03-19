import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class InstitutionInfo extends Object {
  String id;
  String name;
  String? logo;
  List<String> loginFields;
  String usernameField;
  String passwordField;
  InstitutionInfo(this.id, this.name, this.logo, this.loginFields,
      this.usernameField, this.passwordField);
}

class AccountInfo extends Object {
  String userInstitutionId;
  String logo;
  String name;
  int lastTransactionId;
  AccountInfo(
      this.userInstitutionId, this.logo, this.name, this.lastTransactionId);
}

class BudgetUserInfo extends Object {
  List<AccountInfo> accounts = <AccountInfo>[];
}

class BudgetTransaction extends Object {
  final String accountId;
  final String date;
  final String description;
  final double amount;
  final String category;
  BudgetTransaction(
      this.accountId, this.date, this.description, this.amount, this.category);
}

class LoadAccountsParams extends Object {
  final Function userIdCb;
  final Function transactionsCb;
  final BudgetUserInfo userInfo;
  const LoadAccountsParams(this.userIdCb, this.transactionsCb, this.userInfo);
}

class LoadAccountsPage extends StatefulWidget {
  late final BuildContext context;
  late final Function userIdCb;
  late final Function transactionsCb;
  late final BudgetUserInfo userInfo;
  LoadAccountsPage(BuildContext contextIn, LoadAccountsParams params,
      {super.key}) {
    context = contextIn;
    userIdCb = params.userIdCb;
    transactionsCb = params.transactionsCb;
    userInfo = params.userInfo;
  }
  static const userId = '8006e2a3-c488-4d00-9546-e0da8a3166c9';
  static const accessKeys = {
    '/getinstitutionbyname': '7lUUGDamBromYvGRbiX34Bl7rGwEq/CbNoRGD+NMBAQ=',
    '/createuserinstitutionwithrefresh':
        '267XJkP4xMWeiYmamFsClgc1qgbQA1yifYAPRzy3cn0=',
    '/getjobinformationbyid': 'YCApqcmlCtOsQw5PJi/WSRCFrCo7e3BYsasEWnmv4gU=',
    '/gettransactionsbytransactiondate':
        'aZGXW7aB+1hFAqE1uUQYyHcqd4wE/83390PlSzbcN8U=',
    '/getuserinstitutionaccounts':
        't472o4K7UM2qOC8M/jfjTPQ7YOUjF8inJ81R2h0O5O8=',
    '/createuserinstitution': '2TNegK+M1gG67wWpD+5exzyO636la1/gDE5qrWZAG28=',
    '/refreshuserinstitutionaccount':
        '/N2GBn6HC4e0Dri94Va1g3iKSGg9rhg0xCcc1d5H8dE=',
  };

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
  Future<http.Response> makeConnection(
      String url, Map<String?, String?> body) async {
    var operation = url.substring(url.lastIndexOf('/')).toLowerCase();
    var accessKey = LoadAccountsPage.accessKeys[operation];
    final response = await http.post(Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'FIApiAUTH:${LoadAccountsPage.userId}:$accessKey:$operation',
        },
        body: jsonEncode(body));
    if (kDebugMode) {
      print(response.statusCode);
      print(response.body);
    }
    return response;
  }

  /*
  String createAccessKey(
      String userId, String accessKey, String url, String httpMethod) {
    // Concat method (POST/GET) with the command
    var authPath = url.substring(url.lastIndexOf('/')).toLowerCase();
    String plainKey = '${httpMethod.toUpperCase()}\n$authPath';

    // Convert the access key from base64 to a plain string
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String decoded = stringToBase64.decode(accessKey);

    // Encode the access key with the concatenated string
    var hash = Hmac(sha256, utf8.encode(plainKey));
    Digest digest = hash.convert(utf8.encode(decoded));

    // Return a base64 version of the encoding
    var secret = base64.encode(digest.bytes);
    //return 'FIApiAUTH:$userId:$secret:$authPath';
    return 'FIApiAUTH:8006e2a3-c488-4d00-9546-e0da8a3166c9:7lUUGDamBromYvGRbiX34Bl7rGwEq/CbNoRGD+NMBAQ=:/getinstitutionbyname';
  }
  */
  Future<void> getAccountInfo(Function callback) async {
    var result = await makeConnection(
        'https://api.sophtron.com/api/Institution/GetInstitutionByName',
        <String, String>{
          "InstitutionName": "Wells Fargo Bank",
          "Extensive": "true",
          "InstitutionType": "Financial"
        });
    var info = jsonDecode(result.body);
    var institutionId = info[0]["InstitutionID"];

    result = await makeConnection(
        'https://api.sophtron.com/api/UserInstitution/CreateUserInstitution',
        <String, String>{
          "UserID": LoadAccountsPage.userId,
          "InstitutionID": institutionId,
          "UserName": "jndbk1",
          "Password": "au55iedog",
        });
    info = jsonDecode(result.body);
    var jobId = info['JobID'];
    var instId = info['UserInstitutionID'];
    do {
      result = await makeConnection(
          'https://api.sophtron.com/api/Job/GetJobInformationByID',
          <String, String>{
            "JobID": jobId,
          });
      info = jsonDecode(result.body);
      sleep(const Duration(seconds: 1));
    } while (info['LastStatus'] != 'Completed');
    if (kDebugMode) {
      print("Created user");
      print(info);
    }
    callback(instId);
  }

  Future<void> newAccount(String institutionId, Function callback) async {
    var result = await makeConnection(
        'https://api.sophtron.com/api/UserInstitution/CreateUserInstitution',
        <String, String>{
          "UserID": LoadAccountsPage.userId,
          "InstitutionID": institutionId,
          "UserName": "jndbk1",
          "Password": "au55iedog",
        });
    var info = jsonDecode(result.body);
    var jobId = info['JobID'];
    var instId = info['UserInstitutionID'];
    do {
      result = await makeConnection(
          'https://api.sophtron.com/api/Job/GetJobInformationByID',
          <String, String>{
            "JobID": jobId,
          });
      info = jsonDecode(result.body);
      sleep(const Duration(seconds: 1));
    } while (info['LastStatus'] != 'Completed');
    if (kDebugMode) {
      print("Created user");
      print(info);
    }
    callback(instId);
  }

  Future<void> getTransactions(Function callback) async {
    var result = await makeConnection(
        'https://api.sophtron.com/api/UserInstitution/GetUserInstitutionAccounts',
        <String?, String?>{
          "UserInstitutionID": widget.userInfo.accounts[0].userInstitutionId,
        });
    var info = jsonDecode(result.body);
    if (kDebugMode) {
      print("Got user accounts");
      print(info);
    }
    var accountId = info[0]['AccountID'];

    result = await makeConnection(
        'https://api.sophtron.com/api/UserInstitutionAccount/RefreshUserInstitutionAccount',
        <String, String>{
          "AccountID": accountId,
        });
    info = jsonDecode(result.body);
    var jobId = info['JobID'];
    do {
      result = await makeConnection(
          'https://api.sophtron.com/api/Job/GetJobInformationByID',
          <String, String>{
            "JobID": jobId,
          });
      info = jsonDecode(result.body);
      sleep(const Duration(seconds: 1));
    } while (info['LastStatus'] != 'Completed');
    if (kDebugMode) {
      print("Refreshed user");
      print(info);
    }
    result = await makeConnection(
        'https://api.sophtron.com/api/Transaction/GetTransactionsByTransactionDate',
        <String, String>{
          "AccountID": accountId,
          "StartDate": "2023-02-01T00:00:00.0000000+08:00",
          "EndDate": "2023-02-28T00:00:00.0000000+08:00",
        });
    info = jsonDecode(result.body) as List;
    var transOut = <BudgetTransaction>[];
    for (var item in info) {
      transOut.add(BudgetTransaction(
          item["UserInstitutionAccountID"],
          item["TransactionDate"],
          item["Description"],
          item["Amount"],
          "Home"));
    }
    if (kDebugMode) {
      print("Transactions");
      print(info);
    }
    callback(transOut);
  }

  void onPressed() {
    if (widget.userInfo.accounts.isNotEmpty) {
      getAccountInfo(widget.userIdCb);
    } else {
      getTransactions(widget.transactionsCb);
    }
  }

  void addBank() {
    newAccount(selectedBankInfo.id, widget.userIdCb);
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
          )
      ],
    );
  }

  void onSearch() {
    getInstitutions(curName);
    //addBudgetCategoryCallback(curName, curIgnore, curOnetime);
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

  void getAll() async {
    var result = await makeConnection(
        'https://api.sophtron.com/api/Institution/GetInstitutionByName',
        <String, String>{
          "InstitutionName": "Wells Fargo Bank",
          "Extensive": "true",
          "InstitutionType": "Financial"
        });
    var info = jsonDecode(result.body);
    var institutionId = info[0]["InstitutionID"];

    result = await makeConnection(
        'https://api.sophtron.com/api/UserInstitution/CreateUserInstitution',
        <String, String>{
          "UserID": LoadAccountsPage.userId,
          "InstitutionID": institutionId,
          "UserName": "jndbk1",
          "Password": "au55iedog",
        });
    info = jsonDecode(result.body);
    var jobId = info['JobID'];
    var instId = info['UserInstitutionID'];
    do {
      result = await makeConnection(
          'https://api.sophtron.com/api/Job/GetJobInformationByID',
          <String, String>{
            "JobID": jobId,
          });
      info = jsonDecode(result.body);
      sleep(const Duration(seconds: 1));
    } while (info['LastStatus'] != 'Completed');
    if (kDebugMode) {
      print("Created user");
      print(info);
    }
    sleep(const Duration(seconds: 10));
    result = await makeConnection(
        'https://api.sophtron.com/api/UserInstitution/GetUserInstitutionAccounts',
        <String, String>{
          "UserInstitutionID": instId,
        });
    info = jsonDecode(result.body);
    if (kDebugMode) {
      print("Got user accounts");
      print(info);
    }
    var accountId = info[0]['AccountID'];

    result = await makeConnection(
        'https://api.sophtron.com/api/UserInstitutionAccount/RefreshUserInstitutionAccount',
        <String, String>{
          "AccountID": accountId,
        });
    info = jsonDecode(result.body);
    jobId = info['JobID'];
    do {
      result = await makeConnection(
          'https://api.sophtron.com/api/Job/GetJobInformationByID',
          <String, String>{
            "JobID": jobId,
          });
      info = jsonDecode(result.body);
      sleep(const Duration(seconds: 10));
    } while (info['LastStatus'] != 'Completed');
    if (kDebugMode) {
      print("Refreshed user");
      print(info);
    }

    result = await makeConnection(
        'https://api.sophtron.com/api/Transaction/GetTransactionsByTransactionDate',
        <String, String>{
          "AccountID": accountId,
          "StartDate": "2023-02-01T00:00:00.0000000+08:00",
          "EndDate": "2023-02-28T00:00:00.0000000+08:00",
        });
    info = jsonDecode(result.body);
    if (kDebugMode) {
      print("Transactions");
      print(info);
    }
  }
}
