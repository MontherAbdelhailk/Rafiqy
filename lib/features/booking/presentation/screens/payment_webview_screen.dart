// lib/features/booking/presentation/screens/payment_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/booking/presentation/logic/booking_cubit.dart';
import 'package:rafiq/features/booking/presentation/logic/booking_state.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_result_screen.dart';

// ─── Environment Toggle ───────────────────────────────────────────────────────
// DEV MODE: The "Verify Payment" button calls POST /api/payments/verify-dev/:id
//           which executes the full booking confirmation + session + notifications.
//
// PRODUCTION: Set this to false before releasing to production.
//             In production the Paymob webhook fires automatically after a
//             successful payment, so the button only needs to check the status.
//
// You can also control this via --dart-define at build time:
//   flutter run  --dart-define=DEV_MODE=true
//   flutter build --dart-define=DEV_MODE=false
// ─────────────────────────────────────────────────────────────────────────────
const bool kDevMode = bool.fromEnvironment('DEV_MODE', defaultValue: true);

class PaymentWebViewScreen extends StatefulWidget {
  final String iframeUrl;
  final String paymentKey;
  final String bookingId;
  final double amount;

  const PaymentWebViewScreen({
    super.key,
    required this.iframeUrl,
    required this.paymentKey,
    required this.bookingId,
    required this.amount,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _webViewController;
  bool _isLoadingWebView = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoadingWebView = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoadingWebView = false;
            });

            // Auto-detect Paymob redirect after user completes/fails payment.
            // In kDevMode: triggers verifyDevPayment (full success flow).
            // In production: triggers checkPaymentStatus (read-only, webhook
            //                has already confirmed the booking).
            if (url.contains('success=true') ||
                url.contains('success=false') ||
                url.contains('txn_response_code=')) {
              _triggerVerification(context);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.iframeUrl));
  }

  /// Dispatches the correct cubit action depending on the environment mode.
  ///
  /// kDevMode = true  → verifyDevPayment()   → POST /api/payments/verify-dev/:id
  ///                    Executes full success flow immediately.
  ///
  /// kDevMode = false → checkPaymentStatus() → GET /api/payments/status/:id
  ///                    Read-only check; webhook has already done the work.
  void _triggerVerification(BuildContext ctx) {
    if (kDevMode) {
      ctx.read<BookingCubit>().verifyDevPayment(
            widget.bookingId,
            amount: widget.amount,
          );
    } else {
      ctx.read<BookingCubit>().checkPaymentStatus(widget.bookingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingCubit>(
      create: (_) => getIt<BookingCubit>(),
      child: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          // ── DEV path: full success flow completed ──────────────────────────
          if (state is PaymentDevVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentResultScreen(
                  isSuccess: true,
                  bookingId: state.bookingId,
                  amount: state.amount,
                ),
              ),
            );
          }

          // ── PRODUCTION path: read-only status check result ─────────────────
          else if (state is PaymentStatusLoaded) {
            if (state.bookingStatus == 'confirmed') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentResultScreen(
                    isSuccess: true,
                    bookingId: widget.bookingId,
                    amount: widget.amount,
                  ),
                ),
              );
            } else if (state.bookingStatus == 'cancelled' ||
                (state.payment != null && state.payment!['status'] == 'failed')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentResultScreen(
                    isSuccess: false,
                    bookingId: widget.bookingId,
                    amount: widget.amount,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Payment is still being processed. Please wait a moment and try again.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }

          // ── Error handling (both paths) ────────────────────────────────────
          else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorNormal,
              ),
            );
          }
        },
        builder: (context, state) {
          final isVerifying = state is BookingLoading;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Online Payment',
                style: AppTextStyles.bold18cairo.copyWith(color: AppColors.darkblack),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.darkblack),
                onPressed: () {
                  _showDiscardDialog(context);
                },
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
            ),
            body: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoadingWebView)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
                    ),
                  ),
                if (isVerifying)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            kDevMode
                                ? 'Confirming your booking...'
                                : 'Verifying transaction status...',
                            style: AppTextStyles.bold16cairo.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total: ${widget.amount.toStringAsFixed(2)} EGP',
                      style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
                    ),
                  ),
                  SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: isVerifying
                          ? null
                          : () => _triggerVerification(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNormal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                      ),
                      child: Text(
                        'Verify Payment',
                        style: AppTextStyles.bold14cairo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Cancel Payment?', style: AppTextStyles.bold18cairo),
        content: Text(
          'Are you sure you want to exit the payment process? If you already paid, make sure to tap Verify Payment first.',
          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Go Back', style: TextStyle(color: AppColors.grey1)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // pop dialog
              Navigator.pop(context); // pop webview screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorNormal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
