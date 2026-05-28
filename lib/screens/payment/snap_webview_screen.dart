import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';

class SnapWebViewScreen extends StatefulWidget {
  final String snapUrl;
  final String title;

  const SnapWebViewScreen({
    super.key,
    required this.snapUrl,
    this.title = 'Pembayaran',
  });

  @override
  State<SnapWebViewScreen> createState() => _SnapWebViewScreenState();
}

class _SnapWebViewScreenState extends State<SnapWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _paymentDone = false;

  // Midtrans Snap redirect result paths
  static const _successPaths = ['/finish', '/success'];
  static const _pendingPaths = ['/pending'];
  static const _errorPaths = ['/error', '/failure', '/cancel', '/unfinish'];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            _checkRedirect(req.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  void _checkRedirect(String url) {
    if (_paymentDone) return;
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';

    if (_successPaths.any((p) => path.endsWith(p))) {
      _paymentDone = true;
      _showResult(success: true, message: 'Pembayaran berhasil!');
    } else if (_pendingPaths.any((p) => path.endsWith(p))) {
      _paymentDone = true;
      _showResult(success: null, message: 'Pembayaran sedang diproses.');
    } else if (_errorPaths.any((p) => path.endsWith(p))) {
      _paymentDone = true;
      _showResult(success: false, message: 'Pembayaran dibatalkan atau gagal.');
    }
  }

  void _showResult({required bool? success, required String message}) {
    if (!mounted) return;
    final color = success == true
        ? AppColors.success
        : success == false
            ? AppColors.error
            : AppColors.warning;
    final icon = success == true
        ? Icons.check_circle_rounded
        : success == false
            ? Icons.cancel_rounded
            : Icons.hourglass_top_rounded;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Icon(icon, color: color, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (success == null)
              const Text(
                'Status akan diperbarui setelah konfirmasi dari Midtrans.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context, success == true || success == null); // return to prev screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kembali ke Aplikasi'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.transparent,
            ),
        ],
      ),
    );
  }
}
