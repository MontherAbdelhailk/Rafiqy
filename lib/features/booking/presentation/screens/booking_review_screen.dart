// lib/features/booking/presentation/screens/booking_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/booking/domain/entities/booking_entity.dart';
import 'package:rafiq/features/booking/domain/entities/slot_entity.dart';
import 'package:rafiq/features/booking/presentation/logic/booking_cubit.dart';
import 'package:rafiq/features/booking/presentation/logic/booking_state.dart';
import 'payment_webview_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final SlotEntity selectedSlot;

  const BookingReviewScreen({
    super.key,
    required this.selectedSlot,
  });

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();
  String _selectedPaymentMethod = 'card';
  BookingEntity? _createdBooking;

  @override
  void dispose() {
    _notesController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingCubit>(
      create: (_) => getIt<BookingCubit>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: Text(
            'Review Booking',
            style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDarker),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocConsumer<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingCreated) {
              _createdBooking = state.booking;
              // Immediately initiate payment once the booking is successfully created
              context.read<BookingCubit>().initiatePayment(
                    state.booking.id,
                    paymentMethod: _selectedPaymentMethod,
                    walletNumber: _selectedPaymentMethod == 'wallet'
                        ? _walletController.text.trim()
                        : null,
                  );
            } else if (state is PaymentInitiated) {
              // Navigate to the PaymentWebViewScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentWebViewScreen(
                    iframeUrl: state.iframeUrl,
                    paymentKey: state.paymentKey,
                    bookingId: state.bookingId,
                    amount: state.amount,
                  ),
                ),
              );
            } else if (state is BookingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorNormal,
                ),
              );
            } else if (state is PaymentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorNormal,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is BookingLoading || state is PaymentInitiating;

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.h),
                            // Booking Card
                            Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20.w),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      Icons.calendar_today_outlined,
                                      'Date',
                                      DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedSlot.startTime),
                                    ),
                                    const Divider(height: 32),
                                    _buildDetailRow(
                                      Icons.access_time,
                                      'Time',
                                      '${DateFormat('hh:mm a').format(widget.selectedSlot.startTime)} - ${DateFormat('hh:mm a').format(widget.selectedSlot.endTime)}',
                                    ),
                                    const Divider(height: 32),
                                    _buildDetailRow(
                                      Icons.hourglass_empty,
                                      'Duration',
                                      '${widget.selectedSlot.durationMins} minutes',
                                    ),
                                    const Divider(height: 32),
                                    _buildDetailRow(
                                      Icons.payments_outlined,
                                      'Consultation Fee',
                                      '${widget.selectedSlot.price.toStringAsFixed(2)} EGP',
                                      valueColor: AppColors.primaryNormalActive,
                                      isBold: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Notes section
                            Text(
                              'Add Notes for the Doctor (Optional)',
                              style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey2),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              maxLength: 300,
                              decoration: InputDecoration(
                                hintText: 'Share symptoms, questions, or notes...',
                                hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey9),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(color: AppColors.primaryNormal),
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Payment Method selection
                            Text(
                              'Select Payment Method',
                              style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey2),
                            ),
                            SizedBox(height: 10.h),

                            _buildPaymentMethodCard(
                              id: 'card',
                              title: 'Credit / Debit Card',
                              subtitle: 'Pay securely using Visa or Mastercard',
                              icon: Icons.credit_card_outlined,
                            ),
                            SizedBox(height: 8.h),

                            _buildPaymentMethodCard(
                              id: 'wallet',
                              title: 'Vodafone Cash / Digital Wallet',
                              subtitle: 'Pay via Vodafone Cash, Orange, Etisalat, etc.',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            if (_selectedPaymentMethod == 'wallet') ...[
                              SizedBox(height: 8.h),
                              TextField(
                                controller: _walletController,
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                decoration: InputDecoration(
                                  hintText: 'Enter Wallet Mobile Number (e.g. 01012345678)',
                                  hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey9),
                                  fillColor: Colors.white,
                                  filled: true,
                                  prefixIcon: const Icon(Icons.phone_android, color: AppColors.primaryNormal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(color: AppColors.primaryNormal),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 8.h),

                            _buildPaymentMethodCard(
                              id: 'meeza',
                              title: 'Meeza Card',
                              subtitle: 'Pay using national Meeza payment cards',
                              icon: Icons.payment_outlined,
                            ),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),

                    // Bottom confirm button
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: CustomButton(
                        text: 'Confirm Booking',
                        height: 55.h,
                        borderRadius: 15.r,
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_selectedPaymentMethod == 'wallet' && _walletController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your mobile wallet number to proceed'),
                                      backgroundColor: AppColors.errorNormal,
                                    ),
                                  );
                                  return;
                                }
                                if (_createdBooking != null) {
                                  // Re-initiate payment using the already created booking ID
                                  context.read<BookingCubit>().initiatePayment(
                                        _createdBooking!.id,
                                        paymentMethod: _selectedPaymentMethod,
                                        walletNumber: _selectedPaymentMethod == 'wallet'
                                            ? _walletController.text.trim()
                                            : null,
                                      );
                                } else {
                                  // Create a new booking
                                  context.read<BookingCubit>().createBooking(
                                        slotId: widget.selectedSlot.id,
                                        notes: _notesController.text.trim().isEmpty
                                            ? null
                                            : _notesController.text.trim(),
                                      );
                                }
                              },
                      ),
                    ),
                  ],
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22.sp, color: AppColors.grey3),
        SizedBox(width: 14.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.regular12cairo.copyWith(color: AppColors.grey1),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: AppTextStyles.bold16cairo.copyWith(
                color: valueColor ?? AppColors.darkblack,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryNormal : Colors.grey[200]!,
            width: isSelected ? 2.w : 1.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNormal.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryNormal.withOpacity(0.1)
                    : Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryNormal : AppColors.grey3,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bold14cairo.copyWith(
                      color: isSelected ? AppColors.primaryNormal : AppColors.darkblack,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.regular12cairo.copyWith(
                      color: AppColors.grey1,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryNormal,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.grey[300],
              ),
          ],
        ),
      ),
    );
  }
}
