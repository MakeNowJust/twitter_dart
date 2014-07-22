library update_name.authorize;

import 'dart:async';
import 'dart:io';
import 'dart:convert' show JSON;
import 'package:oauth/oauth.dart' as oauth;

Future get async => new Future.delayed(const Duration(milliseconds: 0), () => null);

Future<Map> readConsumer(String filename) => new File(filename)
  .readAsString()
  .then((String str) {
    var json = JSON.decode(str);
    return async.then((_) => {"consumer": new oauth.Token(json["key"], json["secret"])});
  });

Future<Map> getRequestToken(Map state) {
  var compl = new Completer();
  var client = new oauth.Client(state["consumer"]);
  client.post("https://api.twitter.com/oauth/request_token",
    body: {"oauth_callback": "oob"})
    .then((res) {
      if (res.statusCode == 200 || res.statusCode == 201) {
        var q = Uri.splitQueryString(res.body);
        state["request"] = new oauth.Token(q["oauth_token"], q["oauth_token_secret"]);
        compl.complete(state);
      } else {
        compl.completeException(res);
      }
    });
  return compl.future;
}

Future<Map> readPin(Map state) {
  stdout.writeln("Open in browser: https://api.twitter.com/oauth/authorize?oauth_token=" + state["request"].key);
  return async.then((_) {
    stdout.write("PIN> ");
    return stdin.readLineSync();
  }).then((String line) {
    state["pin"] = line;
    return state;
  });
}

dynamic getAccessToken (String filename) => (Map state) {
  var compl = new Completer();
  var client = new oauth.Client(state["consumer"]);
  client.userToken = state["request"];
  client.post("https://api.twitter.com/oauth/access_token",
    body: {"oauth_verifier": state["pin"]})
    .then((res) {
      if (res.statusCode == 200 || res.statusCode == 201) {
        var q = Uri.splitQueryString(res.body);
        var access = {"key": q["oauth_token"], "secret": q["oauth_token_secret"]};
        new File(filename).writeAsString(JSON.encode(access)).then(compl.complete);
      } else {
        compl.completeException(res);
      }
    });
  return compl.future;
};

void main(List<String> args) {
  readConsumer(args[0])
    .then(getRequestToken)
    .then(readPin)
    .then(getAccessToken(args[1]));
}
