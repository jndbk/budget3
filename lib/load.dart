import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class LoadExpensesPage extends StatelessWidget {
  const LoadExpensesPage({super.key});
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

  Future<http.Response> makeConnection(
      String url, Map<String, String> body) async {
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
      print(response.body.length);
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

  void onPressed() async {
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
          "UserID": userId,
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: const Text("Load"));
  }
}
