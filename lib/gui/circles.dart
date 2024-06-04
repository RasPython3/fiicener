import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backends/circle.dart'; // Circle クラスを提供するファイルをインポート
import '../backends/manager.dart';
import '../backends/textagent.dart';
import '../backends/user.dart';
import 'profile.dart';
import 'circle.dart';
import 'footer.dart';

class CircleMenu extends StatefulWidget {
  const CircleMenu();

  @override
  _CircleMenuState createState() => _CircleMenuState();
}

class _CircleMenuState extends State<CircleMenu> {
  late Future<List<Circle>> _circlesFuture;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    try {
      _circlesFuture = Manager.getHomeCircles();
      await _circlesFuture;
      setState(() {});
    } catch (e) {
      // Handle errors if needed
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await _loadCircles();
    await Footer.footerKey.currentState?.fetchNotificationCount();
  }

  void _onCommentButtonPressed() {
    print("comment pressed");
  }

  void _onLikeButtonPressed() {
    print("like pressed");
  }

  void _onRetweetButtonPressed() {
    print("refly pressed");
  }

  Widget _buildCircleAvatar(Circle circle) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(user: circle.user)),
      ),
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

  Widget _buildActions(Circle circle) {
    return FutureBuilder(
      future: Future.wait([
        circle.getReplysCount(),
        circle.getReflyUsersCount(),
        circle.getLikedUsersCount()
      ]),
      builder: (context, AsyncSnapshot<List<int>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: const [
              CircularProgressIndicator(),
            ],
          );
        } else if (snapshot.hasError) {
          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () {},
              ),
              const Text("Error"),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.repeat),
                onPressed: () {},
              ),
              const Text("Error"),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () {},
              ),
              const Text("Error"),
            ],
          );
        } else {
          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () => _onCommentButtonPressed(),
              ),
              Text(snapshot.data![0].toString()),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.repeat),
                onPressed: () => _onRetweetButtonPressed(),
              ),
              Text(snapshot.data![1].toString()),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () => _onLikeButtonPressed(),
              ),
              Text(snapshot.data![2].toString()),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No circles available'),
            );
          } else {
            final circles = snapshot.data!;
            return Scrollbar(
              child: ListView.builder(
                itemCount: circles.length,
                itemBuilder: (context, index) {
                  final circle = circles[index];
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        circle.reflew_name != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center, // Aligns children in the center horizontally
                                      children: [
                                        Row(children: [
                                          GestureDetector(
                                            onTap: () async {
                                              User _user =
                                                  await Manager.getUserDetails(
                                                      '${circle.reflew_name}');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProfilePage(
                                                            user: _user)),
                                              );
                                            },
                                            child: Text(
                                                '@${circle.reflew_name}',
                                                style: TextStyle(
                                                    color: Colors.lightBlue)),
                                          ),
                                          Text(
                                            ' がリポストしました',
                                          ),
                                        ]),
                                        const Icon(Icons.repeat),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    // 下線を追加
                                    color: Colors.grey,
                                    thickness: 1,
                                    height: 2,
                                  ),
                                ],
                              )
                            : SizedBox(),
                        Row(
                          children: [
                            _buildCircleAvatar(circle),
                            const SizedBox(width: 8),
                            _buildUserInfo(circle),
                          ],
                        ),
                        const SizedBox(height: 8),
                        circle.reflew_name != null
                            ? Row(children: [
                                const Text('返信先: '),
                                GestureDetector(
                                  onTap: () async {
                                    User _user = await Manager.getUserDetails(
                                        '${circle.reflew_name}');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ProfilePage(user: _user)),
                                    );
                                  },
                                  child: Text('@${circle.reflew_name}',
                                      style:
                                          TextStyle(color: Colors.lightBlue)),
                                ),
                              ])
                            : SizedBox(),
                        Text.rich(TextAgent.generate(circle.content)),
                        circle.imageUrl != null
                            ? FittedBox(
                                child: Image.network('${circle.imageUrl}'),
                                fit: BoxFit.contain,
                              )
                            : SizedBox(),
                        circle.videoPoster != null
                            ? FittedBox(
                                child: Image.network('${circle.videoPoster}'),
                                fit: BoxFit.contain,
                              )
                            : SizedBox(),
                        _buildActions(circle),
                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                          height: 2,
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CircleDetailPage(circle: circle)),
                    ),
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
