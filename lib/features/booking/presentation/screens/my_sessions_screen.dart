// lib/features/booking/presentation/screens/my_sessions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/booking/domain/entities/session_entity.dart';
import 'package:rafiq/features/booking/presentation/logic/sessions_cubit.dart';
import 'package:rafiq/features/booking/presentation/logic/sessions_state.dart';
import 'session_join_screen.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionsCubit>(
      create: (_) => getIt<SessionsCubit>()..loadMySessions(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: Text(
            'My Sessions',
            style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDarker),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryNormal,
            labelColor: AppColors.primaryNormalActive,
            unselectedLabelColor: AppColors.grey1,
            labelStyle: AppTextStyles.bold14cairo,
            unselectedLabelStyle: AppTextStyles.regular14cairo,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past Sessions'),
            ],
          ),
        ),
        body: BlocConsumer<SessionsCubit, SessionsState>(
          listener: (context, state) {
            if (state is SessionJoined) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionJoinScreen(
                    sessionId: state.sessionId,
                    jitsiRoomName: state.jitsiRoomName,
                    jitsiUrl: state.jitsiUrl,
                    isAdmin: state.isAdmin,
                  ),
                ),
              ).then((_) {
                // Refresh list when returning from call
                context.read<SessionsCubit>().loadMySessions();
              });
            } else if (state is SessionsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorNormal,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SessionsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
                ),
              );
            }

            if (state is SessionsLoaded) {
              final sessions = state.sessions;
              final now = DateTime.now();

              // Filter upcoming (scheduled or active, and not yet ended past duration)
              final upcoming = sessions.where((s) {
                if (s.isCancelled || s.isCompleted) return false;
                if (s.scheduledStart == null) return false;
                final endTime = s.scheduledStart!.add(Duration(minutes: s.durationMins ?? 60));
                return endTime.isAfter(now);
              }).toList();

              // Sort upcoming chronologically
              upcoming.sort((a, b) => (a.scheduledStart ?? DateTime.now()).compareTo(b.scheduledStart ?? DateTime.now()));

              // Filter past (completed, cancelled, or scheduled start is already in past + duration)
              final past = sessions.where((s) {
                if (s.isCancelled || s.isCompleted) return true;
                if (s.scheduledStart == null) return true;
                final endTime = s.scheduledStart!.add(Duration(minutes: s.durationMins ?? 60));
                return endTime.isBefore(now);
              }).toList();

              // Sort past reverse-chronologically
              past.sort((a, b) => (b.scheduledStart ?? DateTime.now()).compareTo(a.scheduledStart ?? DateTime.now()));

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildSessionList(context, upcoming, isPast: false),
                  _buildSessionList(context, past, isPast: true),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, List<SessionEntity> sessions, {required bool isPast}) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPast ? Icons.history_toggle_off : Icons.video_camera_back_outlined,
                size: 64.sp,
                color: AppColors.grey1,
              ),
              SizedBox(height: 16.h),
              Text(
                isPast ? 'No past sessions found' : 'No upcoming sessions scheduled',
                style: AppTextStyles.bold16cairo.copyWith(color: AppColors.grey2),
              ),
              SizedBox(height: 8.h),
              Text(
                isPast
                    ? 'Your past video consultations will appear here.'
                    : 'Book a consultation slot to schedule a video call with a specialist.',
                textAlign: TextAlign.center,
                style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SessionsCubit>().loadMySessions(),
      color: AppColors.primaryNormal,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionCard(context, session, isPast);
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, SessionEntity session, bool isPast) {
    final start = session.scheduledStart;
    final end = session.scheduledEnd;
    final timeString = (start != null && end != null)
        ? '${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}'
        : 'Consultation Session';
    final dateString = start != null ? DateFormat('EEEE, MMMM d, yyyy').format(start) : 'Scheduled Date';
    final canJoin = session.canJoinNow;

    Color badgeColor;
    String badgeText;

    if (session.isCancelled) {
      badgeColor = AppColors.errorNormal;
      badgeText = 'Cancelled';
    } else if (session.isCompleted) {
      badgeColor = AppColors.grey1;
      badgeText = 'Completed';
    } else if (session.isActive) {
      badgeColor = Colors.green;
      badgeText = 'Active Now';
    } else {
      // scheduled
      final now = DateTime.now();
      if (start != null && start.subtract(const Duration(minutes: 15)).isBefore(now) && start.add(Duration(minutes: session.durationMins ?? 60)).isAfter(now)) {
        badgeColor = AppColors.primaryNormal;
        badgeText = 'Ready to Join';
      } else {
        badgeColor = Colors.blue;
        badgeText = 'Scheduled';
      }
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Date & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateString,
                  style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTextStyles.bold12cairo.copyWith(color: badgeColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Time & Duration
            Row(
              children: [
                Icon(Icons.access_time, size: 18.sp, color: AppColors.grey1),
                SizedBox(width: 8.w),
                Text(
                  timeString,
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                ),
                SizedBox(width: 16.w),
                Icon(Icons.hourglass_empty, size: 18.sp, color: AppColors.grey1),
                SizedBox(width: 8.w),
                Text(
                  '${session.durationMins ?? 60} mins',
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                ),
              ],
            ),

            if (!isPast) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      canJoin
                          ? 'You can now enter the video consultation.'
                          : 'Button unlocks 15 mins before starting.',
                      style: AppTextStyles.regular12cairo.copyWith(
                        color: canJoin ? AppColors.primaryNormalActive : AppColors.grey1,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton.icon(
                    onPressed: canJoin
                        ? () {
                            context.read<SessionsCubit>().joinSession(session.id);
                          }
                        : null,
                    icon: Icon(Icons.video_call, size: 18.sp),
                    label: Text(
                      'Join Call',
                      style: AppTextStyles.bold12cairo,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNormal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
