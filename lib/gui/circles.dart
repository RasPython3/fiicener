import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backends/circle.dart'; // Circle クラスを提供するファイルをインポート
import '../backends/user.dart';
import '../backends/manager.dart';
import 'profile.dart';

class CircleMenu extends StatefulWidget {
  const CircleMenu();

  @override
  _CircleMenuState createState() => _CircleMenuState();
}

class _CircleMenuState extends State<CircleMenu> {
  late Future<List<Circle>> _circlesFuture;
  List<Circle> circles = []; // circles リストを定義
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _circlesFuture = Manager.getHomeCircles();
      circles = await _circlesFuture;
    } catch (e) {
      // Handle errors if needed
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await _loadCircles();
  }

  void _onCommentButtonPressed(int index) {
    print("comment pressed");
  }

  void _onLikeButtonPressed(int index) {
    print("like pressed");
  }

  void _onRetweetButtonPressed(int index) {
    print("refly pressed");
  }

  Widget _buildCircleAvatar(Circle circle) {
    return GestureDetector(
      onTap: () => {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(user: circle.user)),
        )
      },
      child: CircleAvatar(
        backgroundImage: NetworkImage(circle.user.avatarUrl),
      ),
    );
  }

  Widget _buildUserInfo(Circle circle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          circle.user.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          circle.user.userHandle,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActions(int index, Circle circle) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.comment),
          onPressed: () => _onCommentButtonPressed(index),
        ),
        Text(circle.replys.length.toString()),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.repeat),
          onPressed: () => _onRetweetButtonPressed(index),
        ),
        Text(circle.reflyusers.length.toString()),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () => _onLikeButtonPressed(index),
        ),
        Text(circle.likedusers.length.toString()),
      ],
    );
  }

  Future<void> _onOpenLink(LinkableElement link) async {
    if (link.url.startsWith('@')) {
      // Handle mention tap
      // Extract the username without '@' symbol
      String username = link.url.substring(1);
      // Assuming you have a method to get user details by username
      User user = await Manager.getUserDetail(username);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(user: user)),
      );
    } else if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<Circle>>(
              future: _circlesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(); // Empty ListView to show refresh indicator
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  return Scrollbar(
                    child: ListView.builder(
                      itemCount: circles.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildCircleAvatar(circles[index]),
                                  const SizedBox(width: 8),
                                  _buildUserInfo(circles[index]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Linkify(
                                onOpen: _onOpenLink,
                                text: circles[index].content,
                                options: LinkifyOptions(humanize: false),
                                linkifiers: [
                                  UrlLinkifier(),
                                  EmailLinkifier(),
                                  CustomLinkifier(
                                    pattern: r"(?<=^|\s)@\w+",
                                    format: (match) => match.group(0)!,
                                    linkifier: (text) => LinkableElement(
                                      '@${text.substring(1)}',
                                      text,
                                    ),
                                  ),
                                ],
                              ),
                              _buildActions(index, circles[index]),
                              Divider(
                                color: Colors.grey,
                                thickness: 1,
                                height: 2,
                              ),
                            ],
                          ),
                          onTap: () {},
                        );
                      },
                    ),
                  );
                }
              },
            ),
          );
  }
}
