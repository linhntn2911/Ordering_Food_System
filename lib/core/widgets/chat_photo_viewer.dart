import 'package:flutter/material.dart';

class ChatPhotoViewer extends StatefulWidget {
  const ChatPhotoViewer({
    super.key,
    required this.count,
    required this.initialIndex,
    required this.itemBuilder,
  });

  final int count;
  final int initialIndex;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<ChatPhotoViewer> createState() => _ChatPhotoViewerState();
}

class _ChatPhotoViewerState extends State<ChatPhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Ảnh ${_index + 1}/${widget.count}')),
    body: SafeArea(
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.count,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) =>
            Center(child: widget.itemBuilder(context, index)),
      ),
    ),
  );
}
