library update_name.tweet;

import 'dart:async';
import 'dart:io';
import 'dart:convert' show JSON;
import 'package:oauth/oauth.dart' as oauth;

Future<oauth.Token> loadToken(String filename) {
  return new File(filename).readAsString()
    .then((String str) {
      var json = JSON.decode(str);
      return new oauth.Token(json["key"], json["secret"]);
    });
}

Future<Map> postAPI(String url, oauth.Token consumer, oauth.Token user, Map body) {
  var compl = new Completer();
  var client = new oauth.Client(consumer);
  client.userToken = user;
  client.post(url, body: body)
    .then((res) {
      if (res.statusCode == 200 || res.statusCode == 201) {
        compl.complete(JSON.decode(res.body));
      } else {
        compl.completeError(res);
      }
    });
  return compl.future;
}

void main(List<String> args) {
  oauth.Token consumer, user;

  var loadConsumer = loadToken(args[0]).then((t) => consumer = t);
  var loadUser     = loadToken(args[1]).then((t) => user     = t);
  Future.wait([loadConsumer, loadUser])
    .then((_) {
      stdout.write("tweet> ");
      var status = stdin.readLineSync();
      return postAPI("https://api.twitter.com/1.1/statuses/update.json",
        consumer, user, {"status": status});
    })
    .then((json) => print(json))
    .catchError((res) {
      print(res);
      print("${res.body}");
    });
}
