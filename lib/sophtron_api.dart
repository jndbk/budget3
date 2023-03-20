import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
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

class UserInstitutionInfo extends Object {
  String id;
  String name;
  String? logo;
  UserInstitutionInfo(this.id, this.name, this.logo);
}

class AccountInfo extends Object {
  String userInstitutionId;
  String name;
  String accountId;
  int lastTransactionId;
  AccountInfo(this.userInstitutionId, this.name, this.accountId,
      this.lastTransactionId);
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

const userId = '8006e2a3-c488-4d00-9546-e0da8a3166c9';
const accessKeys = {
  '/getinstitutionbyname': '7lUUGDamBromYvGRbiX34Bl7rGwEq/CbNoRGD+NMBAQ=',
  '/createuserinstitutionwithrefresh':
      '267XJkP4xMWeiYmamFsClgc1qgbQA1yifYAPRzy3cn0=',
  '/getjobinformationbyid': 'YCApqcmlCtOsQw5PJi/WSRCFrCo7e3BYsasEWnmv4gU=',
  '/gettransactionsbytransactiondate':
      'aZGXW7aB+1hFAqE1uUQYyHcqd4wE/83390PlSzbcN8U=',
  '/getuserinstitutionaccounts': 't472o4K7UM2qOC8M/jfjTPQ7YOUjF8inJ81R2h0O5O8=',
  '/createuserinstitution': '2TNegK+M1gG67wWpD+5exzyO636la1/gDE5qrWZAG28=',
  '/refreshuserinstitutionaccount':
      '/N2GBn6HC4e0Dri94Va1g3iKSGg9rhg0xCcc1d5H8dE=',
};
Future<http.Response> makeConnection(
    String url, Map<String?, String?> body) async {
  var operation = url.substring(url.lastIndexOf('/')).toLowerCase();
  var accessKey = accessKeys[operation];
  final response = await http.post(Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'FIApiAUTH:$userId:$accessKey:$operation',
      },
      body: jsonEncode(body));
  if (kDebugMode) {
    print(response.statusCode);
    print(response.body);
  }
  return response;
}

Future<void> newAccount(
    InstitutionInfo instInfo,
    Map<String, String> loginFields,
    Function userInstCb,
    Function accountCb,
    Function transactionsCb) async {
  var result = await makeConnection(
      'https://api.sophtron.com/api/UserInstitution/CreateUserInstitution',
      <String, String>{
        "UserID": userId,
        "InstitutionID": instInfo.id,
        "UserName": loginFields['UserName'] as String,
        "Password": loginFields['Password'] as String,
      });
  var info = jsonDecode(result.body);
  var jobId = info['JobID'];
  var instId = info['UserInstitutionID'];
  var userInstInfo = UserInstitutionInfo(instId, instInfo.name, instInfo.logo);
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
  userInstCb(userInstInfo);
  getAccounts(userInstInfo.id, accountCb, transactionsCb);
}

Future<void> getAccounts(String userInstitutionId, Function accountCb,
    Function transactionCallback) async {
  var result = await makeConnection(
      'https://api.sophtron.com/api/UserInstitution/GetUserInstitutionAccounts',
      <String?, String?>{
        "UserInstitutionID": userInstitutionId,
      });
  var info = jsonDecode(result.body);
  if (kDebugMode) {
    print("Got user accounts");
    print(info);
  }
  List<AccountInfo> newAccounts = [];
  for (var account in info) {
    newAccounts.add(AccountInfo(
        userInstitutionId, account['AccountName'], account['AccountID'], 0));
  }
  accountCb(newAccounts);
  for (var account in info) {
    newAccounts.add(AccountInfo(
        userInstitutionId, account['AccountName'], account['AccountID'], 0));
    result = await makeConnection(
        'https://api.sophtron.com/api/Transaction/GetTransactionsByTransactionDate',
        <String, String>{
          "AccountID": account['AccountID'] as String,
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
    transactionCallback(transOut);
  }
  /*
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
  */
}
