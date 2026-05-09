import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class StudentExamPlayerScreen extends StatefulWidget {
  final String examId;

  const StudentExamPlayerScreen({super.key, required this.examId});

  @override
  State<StudentExamPlayerScreen> createState() => _StudentExamPlayerScreenState();
}

class _StudentExamPlayerScreenState extends State<StudentExamPlayerScreen> {
  bool _isLoading = true;
  double _progress = 0;
  InAppWebViewController? webViewController;
  bool _cookieInjected = false;

  @override
  void initState() {
    super.initState();
    _setupCookies();
  }

  Future<void> _setupCookies() async {
    final token = await AuthService.getToken();
    if (token != null) {
      CookieManager cookieManager = CookieManager.instance();
      final webUrlStr = ApiConfig.webUrl;
      await cookieManager.setCookie(
        url: WebUri(webUrlStr),
        name: "token",
        value: token,
        isHttpOnly: false,
        isSecure: false,
      );
    }
    setState(() {
      _cookieInjected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_cookieInjected) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Direct user to the web portal's exam taking page
    final url = '${ApiConfig.webUrl}/student/exams/${widget.examId}/take';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Exam Player'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              webViewController?.reload();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useHybridComposition: true,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                });
                // Optional: Inject token into localStorage as fallback
                final token = await AuthService.getToken();
                if (token != null) {
                  await controller.evaluateJavascript(
                    source: "window.localStorage.setItem('token', '$token');",
                  );
                }
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              // Auto-grant camera and mic permissions for AI Proctoring
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
            ),
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
