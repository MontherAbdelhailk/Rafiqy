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

// ─── Payment outcome states ────────────────────────────────────────────────────
enum _PaymentOutcome {
  /// iFrame is open, user hasn't completed payment yet.
  waiting,

  /// Paymob redirect URL contained success=true — payment approved.
  /// Safe to show the "Verify Payment" button.
  approved,

  /// Paymob redirect URL contained success=false — payment rejected.
  failed,

  /// User closed the WebView before Paymob redirected.
  cancelled,
}

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

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _webViewController;
  bool _isLoadingWebView = true;
  _PaymentOutcome _outcome = _PaymentOutcome.waiting;

  // Pulse animation for the "waiting" indicator
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Set up subtle pulse for "Waiting..." indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoadingWebView = true),
          onPageFinished: (String url) {
            setState(() => _isLoadingWebView = false);
            _handleRedirectUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.iframeUrl));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── URL parsing — the only place that decides payment outcome ──────────────
  //
  // Paymob's iFrame redirects to the merchant's return URL after the user
  // completes (or fails) a payment. The URL contains query params like:
  //   ?success=true&txn_response_code=APPROVED&...
  //   ?success=false&txn_response_code=DECLINED&...
  //
  // We inspect ONLY these params to determine outcome. We do NOT show
  // "Verify Payment" until success=true is confirmed here.
  void _handleRedirectUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Only react when Paymob redirects (URL contains payment response params)
    final hasSuccessParam = uri.queryParameters.containsKey('success');
    final hasTxnCode = uri.queryParameters.containsKey('txn_response_code');

    if (!hasSuccessParam && !hasTxnCode) return; // still on Paymob iFrame pages

    final successParam = uri.queryParameters['success'];
    final isSuccess = successParam == 'true';
    final isPending = uri.queryParameters['pending'] == 'true';

    if (isSuccess && !isPending) {
      // ✅ Payment approved — now it's safe to show the button
      setState(() => _outcome = _PaymentOutcome.approved);
    } else {
      // ❌ Payment failed, declined, or cancelled
      setState(() => _outcome = _PaymentOutcome.failed);
    }
  }

  // ─── Dispatches the correct cubit action ────────────────────────────────────
  //
  // kDevMode = true  → verifyDevPayment()   → POST /api/payments/verify-dev/:id
  //                    Executes full success flow immediately.
  //
  // kDevMode = false → checkPaymentStatus() → GET /api/payments/status/:id
  //                    Read-only check; webhook has already done the work.
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
          // ── DEV path: full success flow completed ────────────────────────────
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

          // ── PRODUCTION path: read-only status check result ───────────────────
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
                (state.payment != null &&
                    state.payment!['status'] == 'failed')) {
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

          // ── Error handling (both paths) ──────────────────────────────────────
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
                style: AppTextStyles.bold18cairo
                    .copyWith(color: AppColors.darkblack),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.darkblack),
                onPressed: () => _showDiscardDialog(context),
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
            ),
            body: Stack(
              children: [
                // ── The Paymob iFrame ─────────────────────────────────────────
                WebViewWidget(controller: _webViewController),

                // ── WebView page loading spinner ──────────────────────────────
                if (_isLoadingWebView)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryNormal),
                    ),
                  ),

                // ── Booking verification overlay ──────────────────────────────
                if (isVerifying)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryNormal),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            kDevMode
                                ? 'Confirming your booking...'
                                : 'Verifying transaction status...',
                            style: AppTextStyles.bold16cairo
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Dynamic bottom bar — changes based on payment outcome ──────────
            bottomNavigationBar: _buildBottomBar(context, isVerifying),
          );
        },
      ),
    );
  }

  // ─── Bottom bar state machine ────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, bool isVerifying) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: switch (_outcome) {
        // ── Waiting: pulsing indicator ─────────────────────────────────────────
        _PaymentOutcome.waiting => _buildWaitingBar(),

        // ── Approved: show the Verify Payment button ───────────────────────────
        _PaymentOutcome.approved => _buildApprovedBar(context, isVerifying),

        // ── Failed: show error, no button ─────────────────────────────────────
        _PaymentOutcome.failed => _buildFailedBar(context),

        // ── Cancelled: show neutral message ───────────────────────────────────
        _PaymentOutcome.cancelled => _buildCancelledBar(),
      },
    );
  }

  // Waiting state — pulsing "Waiting for payment confirmation..." text
  Widget _buildWaitingBar() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) => Opacity(
            opacity: _pulseAnimation.value,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: const BoxDecoration(
                color: AppColors.primaryNormal,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waiting for payment confirmation...',
                style: AppTextStyles.bold14cairo
                    .copyWith(color: AppColors.darkblack),
              ),
              SizedBox(height: 2.h),
              Text(
                'Complete your payment in the form above',
                style: AppTextStyles.regular12cairo
                    .copyWith(color: AppColors.grey1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Approved state — show the verify button prominently
  Widget _buildApprovedBar(BuildContext context, bool isVerifying) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success badge
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Payment Approved by Paymob',
                    style: AppTextStyles.bold12cairo
                        .copyWith(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Amount + Verify button row
        Row(
          children: [
            Expanded(
              child: Text(
                'Total: ${widget.amount.toStringAsFixed(2)} EGP',
                style: AppTextStyles.bold16cairo
                    .copyWith(color: AppColors.darkblack),
              ),
            ),
            SizedBox(
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: isVerifying
                    ? null
                    : () => _triggerVerification(context),
                icon: isVerifying
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined, size: 20),
                label: Text(
                  isVerifying ? 'Confirming...' : 'Verify Payment',
                  style: AppTextStyles.bold14cairo,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Failed state — error message, no button
  Widget _buildFailedBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.errorNormal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border:
                Border.all(color: AppColors.errorNormal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: AppColors.errorNormal, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Failed or Declined',
                      style: AppTextStyles.bold14cairo
                          .copyWith(color: AppColors.errorNormal),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Please go back and try a different payment method.',
                      style: AppTextStyles.regular12cairo
                          .copyWith(color: AppColors.grey1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text('Go Back & Retry',
                style: AppTextStyles.bold14cairo
                    .copyWith(color: AppColors.primaryNormal)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryNormal,
              side: const BorderSide(color: AppColors.primaryNormal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Cancelled state
  Widget _buildCancelledBar() {
    return Row(
      children: [
        Icon(Icons.info_outline, color: AppColors.grey3, size: 22.sp),
        SizedBox(width: 12.w),
        Text(
          'Payment cancelled. You can go back and retry.',
          style:
              AppTextStyles.regular14cairo.copyWith(color: AppColors.grey1),
        ),
      ],
    );
  }

  // ─── Discard dialog ──────────────────────────────────────────────────────────
  void _showDiscardDialog(BuildContext context) {
    // If payment is already approved, warn the user more strongly
    final isApproved = _outcome == _PaymentOutcome.approved;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          isApproved ? 'Payment Approved — Are You Sure?' : 'Cancel Payment?',
          style: AppTextStyles.bold18cairo,
        ),
        content: Text(
          isApproved
              ? 'Your payment was approved. If you exit now without verifying, your booking will NOT be confirmed. Please tap "Verify Payment" first.'
              : 'Are you sure you want to exit? Your payment will not be processed.',
          style:
              AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              isApproved ? 'Stay & Verify' : 'Go Back',
              style: TextStyle(color: AppColors.primaryNormal),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
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
