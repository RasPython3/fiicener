import "manager.dart";
import "user.dart";
import 'package:html/parser.dart' as htmlParser;
import 'package:http/http.dart' as http;

class Circle {
  final String id;
  final User user;
  final String content;
  final String? imageUrl;
  final String? videoPoster;
  final String? videoUrl;
  final String? replyed_to;
  final String? reflew_name;
  bool liked = false;
  bool reflown = false;

  Circle({
    required this.id,
    required this.user,
    required this.content,
    required this.imageUrl,
    required this.videoPoster,
    required this.videoUrl,
    required this.replyed_to,
    required this.reflew_name,
    required this.liked,
    required this.reflown,
  });

  Future<List<Circle>> getReplys() async {
    String? session = await Manager.loadSessionToken();
    String? csrf = await Manager.loadCsrfToken();

    final response = await http.get(
      Uri.parse('https://fiicen.jp/circle/${id}/'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Cookie': 'sessionid=${session}; csrftoken=${csrf};',
      },
    );

    List<Circle> circleslist = [];

    // HTMLをパースする
    var document = htmlParser.parse(response.body);

    // サークル要素をすべて取得する
    var replys = document.querySelector('.replys');
    List circles = [];
    if (replys != null) {
      circles = replys.querySelectorAll('.circle');
    }

    // 各サークルの情報を抽出する
    for (var circle in circles) {
      String replyed_to = user.userName;

      String circle_id = "";

      RegExp regExp = RegExp(r"openSlidePanel\('\/circle\/(\d+)'\)");
      var match = regExp.firstMatch(circle?.innerHtml);

      // マッチした場合、(.*) の部分をリストに追加
      if (match != null) {
        circle_id = match.group(1)!;
      }

      // アカウント名
      String? accountName = circle.querySelector('.account-name')?.text.trim();
      if (accountName != null) {
        accountName = accountName.replaceAll('@', ''); // @を取り除く
      }

      // テキスト内容
      String? textContent = circle
          .querySelector('.circle-content > div')
          ?.text
          .trim();

      bool liked = false;
      if (circle.innerHtml.contains("/static/icon/liked.svg")) {
        liked = true;
      }
      bool reflown = false;
      if (circle.innerHtml.contains("reflown")) {
        reflown = true;
      }

      /* サークル情報を出力
      print('ユーザー名: $username');
      print('アカウント名: $accountName');
      print('テキスト: $textContent');
      if (imageUrl != null) {
        print('画像URL: $imageUrl');
      }
      print('---');
      */
      circleslist.add(Circle(
        id: circle_id,
        user: await Manager.getUserDetails("${accountName}"),
        content: '${textContent}',
        imageUrl: null,
        videoPoster: null,
        videoUrl: null,
        replyed_to: replyed_to,
        reflew_name: null,
        liked: liked,
        reflown: reflown,
      ));
    }
    return circleslist;
  }

  Future<int> getReplysCount() async {
    String? session = await Manager.loadSessionToken();
    String? csrf = await Manager.loadCsrfToken();

    final response = await http.get(
      Uri.parse('https://fiicen.jp/circle/${id}/'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Cookie': 'sessionid=${session}; csrftoken=${csrf};',
      },
    );
    // HTMLをパースする
    var document = htmlParser.parse(response.body);

    // サークル要素をすべて取得する
    List circles = document.querySelectorAll('.circle');
    return circles.length;
  }

  Future<List<User>> getReflyUsers() async {
    final reflys_res = await http.get(
      Uri.parse('https://fiicen.jp/circle/reflys/?circle_id=${id}'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Cookie':
            'sessionid=${await Manager.loadSessionToken()}; csrftoken=${await Manager.loadCsrfToken()};',
      },
    );

    // 抽出したい部分にマッチする正規表現
    RegExp regExp = RegExp(r'/field/([^/]+)/');

    // 結果を格納するリスト
    List<String> accountNames = [];

    // 正規表現で全てのマッチを見つける
    Iterable<Match> matches = regExp.allMatches(reflys_res.body);

    // 各マッチについて、キャプチャしたグループをリストに追加
    for (var match in matches) {
      accountNames.add(match.group(1)!); // マッチした部分をリストに追加
    }

    List<User> followers = [];

    for (String username in accountNames) {
      User follower = await Manager.getUserDetails(username);
      followers.add(follower);
    }

    return followers;
  }

  Future<int> getReflyUsersCount() async {
    final reflys_res = await http.get(
      Uri.parse('https://fiicen.jp/circle/reflys/?circle_id=${id}'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Cookie':
            'sessionid=${await Manager.loadSessionToken()}; csrftoken=${await Manager.loadCsrfToken()};',
      },
    );

    // 抽出したい部分にマッチする正規表現
    RegExp regExp = RegExp(r'/field/([^/]+)/');
    // 正規表現で全てのマッチを見つける
    Iterable<Match> matches = regExp.allMatches(reflys_res.body);
    return matches.length;
  }

  Future<List<User>> getLikedUsers() async {
    final likes_res = await http.get(
      Uri.parse('https://fiicen.jp/circle/likes/?circle_id=${id}'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Cookie':
            'sessionid=${await Manager.loadSessionToken()}; csrftoken=${await Manager.loadCsrfToken()};',
      },
    );

    // 抽出したい部分にマッチする正規表現
    RegExp regExp = RegExp(r'/field/([^/]+)/');

    // 結果を格納するリスト
    List<String> accountNames = [];

    // 正規表現で全てのマッチを見つける
    Iterable<Match> matches = regExp.allMatches(likes_res.body);

    // 各マッチについて、キャプチャしたグループをリストに追加
    for (var match in matches) {
      accountNames.add(match.group(1)!); // マッチした部分をリストに追加
    }

    List<User> followers = [];

    for (String username in accountNames) {
      User follower = await Manager.getUserDetails(username);
      followers.add(follower);
    }

    return followers;
  }

  Future<int> getLikedUsersCount() async {
    final likes_res = await http.get(
      Uri.parse('https://fiicen.jp/circle/likes/?circle_id=${id}'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Cookie':
            'sessionid=${await Manager.loadSessionToken()}; csrftoken=${await Manager.loadCsrfToken()};',
      },
    );

    // 抽出したい部分にマッチする正規表現
    RegExp regExp = RegExp(r'/field/([^/]+)/');
    // 正規表現で全てのマッチを見つける
    Iterable<Match> matches = regExp.allMatches(likes_res.body);
    return matches.length;
  }

  Future<bool> refly() async {
    final response = await http.post(
      Uri.parse('https://fiicen.jp/circle/refly/'),
      body: {"circle_id": id},
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'X-Csrftoken': '${await Manager.loadCsrfToken()}',
        'Cookie':
            'sessionid=${await Manager.loadSessionToken()}; csrftoken=${await Manager.loadCsrfToken()};',
      },
    );
    if (response.statusCode == 200) {
      this.reflown = !this.reflown;
      return true;
    } else {
      return false;
    }
  }

  Future<bool> like() async {
    final response = await http.post(
      Uri.parse('https://fiicen.jp/circle/refly/'),
      body: {"circle_id": id},
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'X-Csrftoken': '${await Manager.loadCsrfToken()}',
        'Cookie':
            'sessionid=${await Manager.loadSessionToken()}; csrftoken=${await Manager.loadCsrfToken()};',
      },
    );
    if (response.statusCode == 200) {
      this.liked = !this.liked;
      return true;
    } else {
      return false;
    }
  }
}
