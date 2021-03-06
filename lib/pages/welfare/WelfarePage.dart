import 'package:flutter/material.dart';
import 'package:gank_io/model/Post.dart';
import 'package:gank_io/model/WelfareResult.dart';
import 'package:gank_io/api/Api.dart';
import 'package:gank_io/api/HttpManager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gank_io/eventbus/DownloadEvent.dart';
import 'package:gank_io/widget/LoadingDialog.dart';
import 'dart:async';

class WelfarePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WelfarePageState();
}

class WelfarePageState extends State<WelfarePage> {
  int _page = 1;
  static final int _pageSize = 10;
  List<Post> _images = List();
  ScrollController _controller = new ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      //最大可滑动距离
      var maxScroll = _controller.position.maxScrollExtent;
      //当前距离
      var pixels = _controller.position.pixels;
      //滑动到底部
      if (maxScroll == pixels) {
        _page++;
        _getImages();
      }
    });
    _getImages();
    HttpManager.eventBus.on<DownloadEvent>().listen((event) {
      if (event.progress == 0) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return new LoadingDialog(text: '下载中');
            });
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _getImages() {
    HttpManager.get(Api.WELFARE + '/${_pageSize}/${_page}').then((resultData) {
      WelfareResult result = WelfareResult.fromJson(resultData.data);
      if (result != null && !result.error) {
        setState(() {
          if (_page == 1) {
            _images.clear();
          }
          _images.addAll(result.results);
        });
      }
    });
  }

  void showPhoto(Post post, BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '美女福利',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: GestureDetector(
          child: PhotoView(
            imageProvider: NetworkImage(post.url),
          ),
          onLongPress: () {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return new AlertDialog(
                    content: new Text('确定下载该图片?'),
                    actions: <Widget>[
                      new FlatButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('取消')),
                      new FlatButton(
                          onPressed: () {
                            String fileNmae = post.url.split('/').last;
                            HttpManager.downloadFile(post.url, fileNmae);
                            Navigator.of(context).pop();
                          },
                          child: new Text('确定'))
                    ],
                  );
                });
          },
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildItem(Post post) {
      return new GestureDetector(
        child: Image.network(post.url, fit: BoxFit.cover),
        onTap: () {
          showPhoto(post, context);
        },
      );
    }

    List<Widget> _getItemList(List<Post> posts) {
      List<Widget> widgets = List();
      posts.forEach((post) {
        widgets.add(_buildItem(post));
      });
      return widgets;
    }

    Future<Null> _pullToRefresh() async {
      _page = 1;
      _getImages();
      return null;
    }

    if (_images.length == 0) {
      return Center(
        //圆形进度条
        child: CircularProgressIndicator(),
      );
    } else {
      return RefreshIndicator(
        child: GridView.count(
          crossAxisCount: 2,
          padding: EdgeInsets.all(8.0),
          mainAxisSpacing: 8.0, //主轴方向间距 （竖直方向）
          crossAxisSpacing: 8.0, //横向间距
          primary: false,
          children: _getItemList(_images),
          controller: _controller,
        ),
        onRefresh: _pullToRefresh, //必须是返回值是Future<Null> 的异步方法
      );
    }
  }
}
