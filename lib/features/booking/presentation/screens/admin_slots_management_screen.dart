// lib/features/booking/presentation/screens/admin_slots_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class AdminSlotsManagementScreen extends StatefulWidget {
  const AdminSlotsManagementScreen({super.key});

  @override
  State<AdminSlotsManagementScreen> createState() => _AdminSlotsManagementScreenState();
}

class _AdminSlotsManagementScreenState extends State<AdminSlotsManagementScreen> {
  final ApiConsumer _api = getIt<ApiConsumer>();
  List<dynamic> _slots = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get('slots/admin/all');
      if (response != null && response['data'] != null) {
        setState(() {
          _slots = response['data'] as List<dynamic>;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    try {
      final response = await _api.delete('slots/$slotId');
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot deleted successfully')),
        );
        _fetchSlots();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete slot: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.errorNormal,
        ),
      );
    }
  }

  Future<void> _createSlot(DateTime startTime, DateTime endTime, double price, int duration, String? notes) async {
    try {
      final response = await _api.post('slots', data: {
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        'price': price,
        'durationMins': duration,
        'notes': notes,
      });

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot created successfully')),
        );
        _fetchSlots();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create slot: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.errorNormal,
        ),
      );
    }
  }

  void _showAddSlotDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    final priceController = TextEditingController(text: '750.00');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: Text('Create Consultation Slot', style: AppTextStyles.bold18cairo),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selection
                    Text('Date', style: AppTextStyles.bold14cairo),
                    SizedBox(height: 8.h),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, color: AppColors.primaryNormal),
                      label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 44.h),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Time selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Time', style: AppTextStyles.bold12cairo),
                              SizedBox(height: 4.h),
                              OutlinedButton(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: startTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      startTime = picked;
                                      // Auto-set end time to 45 minutes later
                                      final startMinutes = startTime.hour * 60 + startTime.minute;
                                      final endMinutes = startMinutes + 45;
                                      final endHour = (endMinutes ~/ 60) % 24;
                                      final endMin = endMinutes % 60;
                                      endTime = TimeOfDay(hour: endHour, minute: endMin);
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 44.h),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Text(startTime.format(context)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Time', style: AppTextStyles.bold12cairo),
                              SizedBox(height: 4.h),
                              OutlinedButton(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: endTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      endTime = picked;
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 44.h),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Text(endTime.format(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Price
                    Text('Price (EGP)', style: AppTextStyles.bold14cairo),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Notes
                    Text('Notes / Topic (Optional)', style: AppTextStyles.bold14cairo),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Behavioral therapy session',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: AppColors.grey1)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate times
                    final startDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    
                    var endDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    // If end time is before start time, it means it crosses over into the next day (e.g., midnight)
                    if (endTime.hour < startTime.hour || (endTime.hour == startTime.hour && endTime.minute < startTime.minute)) {
                      endDateTime = endDateTime.add(const Duration(days: 1));
                    }

                    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('End time must be after start time'),
                          backgroundColor: AppColors.errorNormal,
                        ),
                      );
                      return;
                    }

                    // Enforce start time >= 7:00 AM
                    if (startTime.hour < 7) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Consultation slot cannot start before 7:00 AM'),
                          backgroundColor: AppColors.errorNormal,
                        ),
                      );
                      return;
                    }

                    // Enforce end time <= 12:00 AM Midnight of next day
                    final nextDayMidnight = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1, 0, 0);
                    if (endDateTime.isAfter(nextDayMidnight)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Consultation slot must end by 12:00 AM (Midnight)'),
                          backgroundColor: AppColors.errorNormal,
                        ),
                      );
                      return;
                    }

                    final price = double.tryParse(priceController.text) ?? 50.00;
                    final duration = endDateTime.difference(startDateTime).inMinutes;

                    Navigator.pop(dialogContext);

                    _createSlot(
                      startDateTime,
                      endDateTime,
                      price,
                      duration,
                      notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNormal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Manage Slots',
          style: AppTextStyles.bold20cairo.copyWith(color: AppColors.secondaryDarker),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkblack),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSlots,
        color: AppColors.primaryNormal,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotDialog,
        backgroundColor: AppColors.primaryNormal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60.sp, color: AppColors.errorNormal),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey8),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _fetchSlots,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNormal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_slots.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 100.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 64.sp, color: AppColors.grey1),
                SizedBox(height: 16.h),
                Text(
                  'No slots found',
                  style: AppTextStyles.bold16cairo.copyWith(color: AppColors.grey2),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Click the floating button (+) to add new consultation slots for users to book.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Sort slots chronologically
    final sortedSlots = List<dynamic>.from(_slots);
    sortedSlots.sort((a, b) {
      final startA = DateTime.parse(a['start_time']);
      final startB = DateTime.parse(b['start_time']);
      return startB.compareTo(startA); // Show newest/upcoming first
    });

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      itemCount: sortedSlots.length,
      itemBuilder: (context, index) {
        final slot = sortedSlots[index];
        final startTime = DateTime.parse(slot['start_time']).toLocal();
        final endTime = DateTime.parse(slot['end_time']).toLocal();
        final isBooked = slot['is_booked'] == true || slot['is_booked'] == 'true';
        final isAvailable = slot['is_available'] == true || slot['is_available'] == 'true';
        final price = slot['price'] != null ? (double.tryParse(slot['price'].toString()) ?? 0.0) : 0.0;
        final notes = slot['notes'] as String?;

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(12.w),
            title: Text(
              DateFormat('EEEE, MMM d, yyyy').format(startTime),
              style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)} (${slot['duration_mins']} mins)',
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      '${price.toStringAsFixed(2)} EGP',
                      style: AppTextStyles.bold14cairo.copyWith(color: AppColors.primaryNormalActive),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? AppColors.errorNormal.withValues(alpha: 0.1)
                            : isAvailable
                                ? AppColors.primaryNormal.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        isBooked ? 'Booked' : isAvailable ? 'Available' : 'Disabled',
                        style: AppTextStyles.bold12cairo.copyWith(
                          color: isBooked
                              ? AppColors.errorNormal
                              : isAvailable
                                  ? AppColors.primaryNormalActive
                                  : AppColors.grey1,
                        ),
                      ),
                    ),
                  ],
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    'Topic: $notes',
                    style: AppTextStyles.regular12cairo.copyWith(color: AppColors.grey1),
                  ),
                ]
              ], //
            ),
            trailing: isBooked
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.errorNormal),
                    onPressed: () {
                      _showDeleteConfirmation(slot['id']);
                    },
                  ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Slot?', style: AppTextStyles.bold18cairo),
        content: const Text('Are you sure you want to permanently delete this available slot? Parents will no longer be able to book it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey1)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteSlot(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorNormal, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
