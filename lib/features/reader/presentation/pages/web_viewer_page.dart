import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;

class WebViewerPage extends StatefulWidget {
  final String url;

  const WebViewerPage({super.key, required this.url});

  @override
  State<WebViewerPage> createState() => _WebViewerPageState();
}

class _WebViewerPageState extends State<WebViewerPage> {
  // For Android/iOS
  late final WebViewController _webViewController;

  // For Windows
  final _windowsController = windows_webview.WebviewController();

  bool _isLoading = true;
  String _pageTitle = '';

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.url;
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    if (Platform.isWindows) {
      await _windowsController.initialize();
      await _windowsController.loadUrl(widget.url);
      _windowsController.title.listen((title) {
        if (mounted) {
          setState(() {
            _pageTitle = title;
          });
        }
      });
      // For Windows, loading is handled internally, but we can listen to state.
      _windowsController.loadingState.listen((state) {
        if (mounted) {
          setState(() {
            _isLoading = state == windows_webview.LoadingState.loading;
          });
        }
      });

    } else {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) async {
              if (mounted) {
                final title = await _webViewController.getTitle();
                setState(() {
                  _isLoading = false;
                  _pageTitle = title ?? widget.url;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
               if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Platform.isWindows
          ? windows_webview.Webview(_windowsController)
          : WebViewWidget(controller: _webViewController),
    );
  }
}