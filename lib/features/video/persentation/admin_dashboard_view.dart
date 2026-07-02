import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/video/domain/entities/video_entity.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_cubit.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_state.dart';
import 'package:rafiq/features/home/widgets/post_sheet.dart';
import 'package:intl/intl.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/features/booking/presentation/screens/admin_slots_management_screen.dart';
import 'package:rafiq/features/booking/presentation/screens/session_join_screen.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Real sessions management
  List<dynamic> _sessions = [];
  bool _loadingSessions = true;
  String? _sessionsError;
  String _sessionsFilter = 'all';
  final TextEditingController _sessionsSearchController = TextEditingController();

  // Mock comments list for moderation
  final List<Map<String, String>> _mockComments = [
    {
      "id": "1",
      "userName": "Hassan Ibrahim",
      "postTitle": "Understanding child emotions",
      "text": "Great insights Rafiqy! This really helped with my 5-year-old child.",
    },
    {
      "id": "2",
      "userName": "Sara Youssef",
      "postTitle": "Tips for early childhood",
      "text": "Are there any video sessions available on this topic this week?",
    },
    {
      "id": "3",
      "userName": "Amr Gamal",
      "postTitle": "Transition to Maturity",
      "text": "I disagree with some points but overall a helpful topic.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Eagerly load sessions so data is ready when the admin opens the Sessions tab.
    // Also re-fetch whenever the admin switches back to the Sessions tab (index 2)
    // so the list is always fresh after a booking is confirmed.
    _fetchAdminSessions();

    _tabController.addListener(() {
      // indexIsChanging is true during the animation frame; skip it to avoid
      // calling _fetchAdminSessions twice per tab switch.
      if (!_tabController.indexIsChanging && _tabController.index == 2) {
        _fetchAdminSessions();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessionsSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminSessions() async {
    setState(() {
      _loadingSessions = true;
      _sessionsError = null;
    });

    try {
      final queryParams = <String, dynamic>{};
      if (_sessionsFilter != 'all') {
        queryParams['status'] = _sessionsFilter;
      }
      if (_sessionsSearchController.text.trim().isNotEmpty) {
        queryParams['search'] = _sessionsSearchController.text.trim();
      }

      final response = await getIt<ApiConsumer>().get('sessions', queryParameters: queryParams);
      // Backend returns: { success: true, sessions: [...], pagination: {...} }
      // Handle both populated and empty session lists correctly.
      if (response != null && response['success'] == true) {
        setState(() {
          _sessions = (response['sessions'] as List<dynamic>?) ?? [];
        });
      } else if (response != null && response['sessions'] == null) {
        // Unexpected shape — clear the list so we show "no sessions" rather than
        // an infinite spinner or stale data.
        setState(() {
          _sessions = [];
        });
      }
    } catch (e) {
      setState(() {
        _sessionsError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _loadingSessions = false;
      });
    }
  }

  Future<void> _adminCompleteSession(String sessionId) async {
    try {
      final response = await getIt<ApiConsumer>().patch('sessions/$sessionId/complete');
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session marked as completed successfully')),
        );
        _fetchAdminSessions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete session: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.errorNormal,
        ),
      );
    }
  }

  Future<void> _adminCancelBooking(String bookingId) async {
    try {
      final response = await getIt<ApiConsumer>().patch('bookings/$bookingId/cancel', data: {
        'reason': 'Cancelled by Doctor / Admin',
      });
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session cancelled successfully')),
        );
        _fetchAdminSessions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel session: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.errorNormal,
        ),
      );
    }
  }

  /// Admin-only: Hard-delete a booking and all associated records.
  /// The session card is removed from the list immediately (optimistic update).
  Future<void> _adminDeleteBooking(String bookingId, int sessionIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorNormal, size: 24.sp),
            12.horizontalSpace,
            Text('Delete Booking?', style: AppTextStyles.bold18cairo),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this booking?\n\n'
          'This will:\n'
          '• Remove the booking and session records\n'
          '• Release the time slot for future bookings\n'
          '• Notify the user\n\n'
          'This action cannot be undone.',
          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey1)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorNormal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await getIt<ApiConsumer>().delete('bookings/$bookingId');
      if (response != null && response['success'] == true) {
        // Optimistic UI: remove the card immediately without waiting for a full re-fetch
        setState(() {
          _sessions.removeAt(sessionIndex);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking deleted successfully'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete booking: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.errorNormal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _adminJoinSession(dynamic session) async {
    try {
      final response = await getIt<ApiConsumer>().post('sessions/${session['id']}/join');
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionJoinScreen(
                sessionId: data['sessionId'] ?? session['id'],
                jitsiRoomName: data['jitsiRoomName'] ?? '',
                jitsiUrl: data['jitsiUrl'] ?? '',
                isAdmin: true,
              ),
            ),
          ).then((_) => _fetchAdminSessions());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join call: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.errorNormal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AdminVideoCubit>()..fetchAdminVideos(),
      child: Scaffold(
        backgroundColor: AppColors.babypink,
        appBar: AppBar(
          backgroundColor: AppColors.babypink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkblack),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Admin Control Panel",
            style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primaryNormalActive,
            labelColor: AppColors.darkblack,
            unselectedLabelColor: AppColors.grey8,
            labelStyle: AppTextStyles.bold14cairo,
            tabs: const [
              Tab(text: "Actions", icon: Icon(Icons.dashboard_outlined)),
              Tab(text: "Videos", icon: Icon(Icons.video_library_outlined)),
              Tab(text: "Sessions", icon: Icon(Icons.calendar_month_outlined)),
            //  Tab(text: "Comments", icon: Icon(Icons.comment_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActionsTab(context),
            _buildVideosTab(context),
            _buildSessionsTab(),
     //       _buildCommentsTab(),
          ],
        ),
      ),
    );
  }

  // 1. Actions Tab
  Widget _buildActionsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack),
          ),
          16.verticalSpace,
          _buildQuickActionCard(
            title: "Manage Consultation Slots",
            description: "Create, view, and delete available consultation slots.",
            icon: Icons.calendar_today_rounded,
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSlotsManagementScreen()),
              );
            },
          ),
          16.verticalSpace,
          _buildQuickActionCard(
            title: "Upload Educational Video",
            description: "Upload a new video for any developmental age stages.",
            icon: Icons.video_call_rounded,
            color: const Color(0xFFC4D35D),
            onTap: () => context.push(AppRouter.uploadVideoMediaView),
          ),
          16.verticalSpace,
          _buildQuickActionCard(
            title: "Create Brand Post",
            description: "Write and publish advice, news, or articles to the feed.",
            icon: Icons.article_rounded,
            color: const Color(0xFF8BAE4A),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: const CreatePostSheet(),
                  ),
                ),
              );
            },
          ),
          16.verticalSpace,
          _buildQuickActionCard(
            title: "Upload Reel / Short",
            description: "Share short dynamic clips under 60 seconds with users.",
            icon: Icons.flash_on_rounded,
            color: const Color(0xFF6B8A33),
            onTap: () => context.push(AppRouter.uploadVideoMediaView), // Reels use same flow starting with picker
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            20.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
                  ),
                  4.verticalSpace,
                  Text(
                    description,
                    style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.grey8, size: 16.sp),
          ],
        ),
      ),
    );
  }

  // 2. Videos Tab
  Widget _buildVideosTab(BuildContext context) {
    return Column(
      children: [
        16.verticalSpace,
        Expanded(
          child: BlocListener<AdminVideoCubit, AdminVideoState>(
            listener: (context, state) {
              if (state is DeleteVideoSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Video deleted successfully!"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else if (state is DeleteVideoError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.black,
                  ),
                );
              }
            },
            child: BlocBuilder<AdminVideoCubit, AdminVideoState>(
              builder: (context, state) {
                if (state is AdminFetchLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormalActive),
                    ),
                  );
                } else if (state is AdminFetchSuccess) {
                  final videos = state.videos;
                  if (videos.isEmpty) {
                    return Center(
                      child: Text(
                        "No videos currently uploaded",
                        style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey8),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return _buildVideoItem(context, video);
                    },
                  );
                } else if (state is AdminFetchError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: AppTextStyles.regular16cairo.copyWith(color: AppColors.errorNormal),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoItem(BuildContext context, VideoEntity video) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.asset(
            video.thumbnailUrl,
            width: 60.w,
            height: 60.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              width: 60.w,
              height: 60.h,
              child: const Icon(Icons.video_library),
            ),
          ),
        ),
        title: Text(
          video.title,
          style: AppTextStyles.bold16cairo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          video.tag,
          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.primaryNormal),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                context.read<AdminVideoCubit>().removeVideo(video.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3. Sessions Tab
  Widget _buildSessionsTab() {
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _sessionsSearchController,
                    onChanged: (val) => _fetchAdminSessions(),
                    decoration: InputDecoration(
                      hintText: 'Search parents...',
                      hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey1),
                      prefixIcon: const Icon(Icons.search, color: AppColors.grey1),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ),
              12.horizontalSpace,
              Container(
                height: 44.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sessionsFilter,
                    icon: const Icon(Icons.filter_list, color: AppColors.grey3),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _sessionsFilter = val;
                        });
                        _fetchAdminSessions();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Session list content
        Expanded(
          child: _buildSessionsListContent(),
        ),
      ],
    );
  }

  Widget _buildSessionsListContent() {
    if (_loadingSessions) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
        ),
      );
    }

    if (_sessionsError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60.sp, color: AppColors.errorNormal),
              SizedBox(height: 16.h),
              Text(
                _sessionsError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey8),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _fetchAdminSessions,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNormal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAdminSessions,
        color: AppColors.primaryNormal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 80.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_camera_front_outlined, size: 64.sp, color: AppColors.grey1),
                  SizedBox(height: 16.h),
                  Text(
                    'No session bookings found',
                    style: AppTextStyles.bold16cairo.copyWith(color: AppColors.grey2),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Sessions will appear here once users complete booking and payment.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAdminSessions,
      color: AppColors.primaryNormal,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final String status = session["effective_status"] ?? session["status"] ?? 'scheduled';
          final startTime = DateTime.parse(session['start_time']).toLocal();
          final endTime = DateTime.parse(session['end_time']).toLocal();
          final bookingCreatedAt = session['booking_created_at'] != null 
              ? DateTime.parse(session['booking_created_at']).toLocal() 
              : null;
          final parentName = session['user_full_name'] ?? session['username'] ?? 'Parent';
          final username = session['username'] ?? '';
          final duration = session['duration_mins'] ?? 60;
          final notes = session['booking_notes'] ?? '';
          final paymentStatus = session['payment_status'] ?? 'pending';
          final jitsiRoomName = session['jitsi_room_name'] ?? 'N/A';
          final jitsiUrl = session['jitsi_url'] ?? '';

          Color statusColor = Colors.orange;
          if (status == "scheduled") statusColor = Colors.blue;
          if (status == "active") statusColor = Colors.green;
          if (status == "completed") statusColor = AppColors.grey1;
          if (status == "cancelled") statusColor = AppColors.errorNormal;

          Color paymentColor = Colors.orange;
          if (paymentStatus == "success") paymentColor = Colors.green;
          if (paymentStatus == "failed") paymentColor = AppColors.errorNormal;

          final now = DateTime.now();
          final earliest = startTime.subtract(const Duration(minutes: 15));
          final latest = startTime.add(Duration(minutes: duration));
          final canJoin = (status == 'scheduled' || status == 'active') &&
              now.isAfter(earliest) &&
              now.isBefore(latest);

          return Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parentName,
                              style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
                            ),
                            if (username.isNotEmpty)
                              Text(
                                '@$username',
                                style: AppTextStyles.regular12cairo.copyWith(color: AppColors.grey1),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          4.verticalSpace,
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: paymentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              paymentStatus.toUpperCase(),
                              style: TextStyle(
                                color: paymentColor,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14.sp, color: AppColors.grey8),
                      6.horizontalSpace,
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(startTime),
                        style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                      ),
                    ],
                  ),
                  4.verticalSpace,
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14.sp, color: AppColors.grey8),
                      6.horizontalSpace,
                      Text(
                        '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)} ($duration mins)',
                        style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                      ),
                    ],
                  ),
                  if (bookingCreatedAt != null) ...[
                    4.verticalSpace,
                    Row(
                      children: [
                        Icon(Icons.edit_calendar_outlined, size: 14.sp, color: AppColors.grey8),
                        6.horizontalSpace,
                        Text(
                          'Booked on: ${DateFormat('MMM d, yyyy hh:mm a').format(bookingCreatedAt)}',
                          style: AppTextStyles.regular12cairo.copyWith(color: AppColors.grey8),
                        ),
                      ],
                    ),
                  ],
                  4.verticalSpace,
                  Row(
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 14.sp, color: AppColors.grey8),
                      6.horizontalSpace,
                      Expanded(
                        child: Text(
                          'Room Name: $jitsiRoomName',
                          style: AppTextStyles.regular12cairo.copyWith(color: AppColors.grey8),
                        ),
                      ),
                    ],
                  ),
                  if (jitsiUrl.isNotEmpty) ...[
                    4.verticalSpace,
                    Row(
                      children: [
                        Icon(Icons.link, size: 14.sp, color: AppColors.primaryNormal),
                        6.horizontalSpace,
                        Expanded(
                          child: SelectableText(
                            jitsiUrl,
                            style: AppTextStyles.regular12cairo.copyWith(
                              color: AppColors.primaryNormalActive,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (notes.isNotEmpty) ...[
                    8.verticalSpace,
                    Text(
                      "Parent Notes: \"$notes\"",
                      style: AppTextStyles.regular12cairo.copyWith(color: AppColors.grey1, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ── Delete button (admin only, always visible) ──────────
                      TextButton.icon(
                        onPressed: () => _adminDeleteBooking(session['booking_id'], index),
                        icon: Icon(Icons.delete_outline, size: 16.sp, color: AppColors.errorNormal),
                        label: Text(
                          'Delete',
                          style: AppTextStyles.bold12cairo.copyWith(color: AppColors.errorNormal),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        ),
                      ),
                      // ── Right-side: Join / Complete / Cancel or status text ──
Wrap(
  alignment: WrapAlignment.end, // بيخلي الأزرار تترص من اليمين للشمال
  spacing: 4.w,                 // مسافة أفقية صغيرة بين كل زرار والتاني
  runSpacing: 8.h,              // مسافة رأسية لو الأزرار نزلت سطر جديد
  children: [
    if (status == 'scheduled' || status == 'active') ...[
      ElevatedButton.icon(
        onPressed: canJoin ? () => _adminJoinSession(session) : null,
        icon: const Icon(Icons.video_call, size: 16),
        label: const Text('Join'), // اختصرت الكلمة عشان توفر مساحة
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNormal,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          elevation: 0,
        ),
      ),
      TextButton(
        onPressed: () => _adminCompleteSession(session['id']),
        child: Text('Complete', style: AppTextStyles.bold12cairo.copyWith(color: Colors.green)),
      ),
      TextButton(
        onPressed: () => _adminCancelBooking(session['booking_id']),
        child: Text('Cancel', style: AppTextStyles.bold12cairo.copyWith(color: AppColors.errorNormal)),
      ),
    ] else ...[
      Text(
        status == 'completed' ? 'Session completed' : 'Session cancelled',
        style: AppTextStyles.regular12cairo.copyWith(color: AppColors.grey1),
      ),
    ],
  ],
),


                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. Comments Tab
  Widget _buildCommentsTab() {
    if (_mockComments.isEmpty) {
      return Center(
        child: Text(
          "No comments pending moderation.",
          style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey8),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _mockComments.length,
      itemBuilder: (context, index) {
        final comment = _mockComments[index];
        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment["userName"]!,
                      style: AppTextStyles.bold14cairo.copyWith(color: AppColors.darkblack),
                    ),
                    Text(
                      "on: ${comment["postTitle"]}",
                      style: AppTextStyles.regular14cairo.copyWith(
                        color: AppColors.primaryNormal,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
                Text(
                  "\"${comment["text"]}\"",
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                ),
                12.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.errorNormal),
                      onPressed: () {
                        setState(() {
                          _mockComments.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Comment deleted successfully!"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
