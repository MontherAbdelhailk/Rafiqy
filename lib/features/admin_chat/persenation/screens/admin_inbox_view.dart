import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/admin_chat/persenation/logic/admin_chat_cubit.dart';
import 'package:rafiq/features/admin_chat/persenation/logic/admin_chat_state.dart';

import 'package:rafiq/core/widgets/app_avatar.dart';

class AdminInboxView extends StatefulWidget {
  const AdminInboxView({super.key});

  @override
  State<AdminInboxView> createState() => _AdminInboxViewState();
}

class _AdminInboxViewState extends State<AdminInboxView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<AdminChatCubit>().loadConversations(search: _searchController.text.trim());
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${localTime.day}/${localTime.month}';
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
        backgroundColor: AppColors.babypink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.grey2, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Admin Inbox", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.grey2)),
        actions: [
IconButton(
  icon: const RotatedBox(
    quarterTurns: 1, 
    child: Icon(Icons.tune, color: AppColors.grey2),
  ),
  onPressed: () {
  },
)        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            10.verticalSpace,
            // 🔍 Search Bar
            TextField(
              controller: _searchController,
              
              decoration: InputDecoration(
                hintText: "Search conversations...",
                hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey9),
                prefixIcon: const Icon(Icons.search, color: AppColors.grey9),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            20.verticalSpace,
            // Filter Tabs (All)
            Row(
              children: [
                _buildTab("All", isSelected: true),
              ],
            ),
            20.verticalSpace,
            Expanded(
              child: BlocBuilder<AdminChatCubit, AdminChatState>(
                builder: (context, state) {
                  if (state.isConversationsLoading && state.conversations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.conversationsError != null && state.conversations.isEmpty) {
                    return Center(
                      child: Text(
                        "Error: ${state.conversationsError}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (state.conversations.isEmpty) {
                    return Center(
                      child: Text(
                        "No conversations found",
                        style: AppTextStyles.regular14cairo.copyWith(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: state.conversations.length,
                    separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final chat = state.conversations[index];
                      print("👤 Name: ${chat.fullName}");
print("🖼️ Profile: ${chat.profilePicture}");

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        leading: AppAvatar(
                          imageUrl: chat.profilePicture,
                          radius: 26.r,
                          name: chat.fullName,
                        ),
                        title: Text(chat.fullName, style: AppTextStyles.bold16cairo.copyWith(color: AppColors.grey2)),
                        subtitle: Text(
                          chat.lastMessage.isEmpty ? "No messages yet" : chat.lastMessage, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey9),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(chat.lastMessageTime), 
                              style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey12, fontSize: 12.sp),
                            ),
                            5.verticalSpace,
                            if (chat.unreadCount > 0)
                              CircleAvatar(
                                radius: 10.r,
                                backgroundColor: AppColors.primaryNormal,
                                child: Text(
                                  chat.unreadCount.toString(), 
                                  style: AppTextStyles.bold14cairo.copyWith(color: Colors.white, fontSize: 10.sp),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          final chatCubit = context.read<AdminChatCubit>();
                          context.push(
                            AppRouter.adminChatRoom,
                            extra: {
                              'userId': chat.id,
                              'userName': chat.fullName,
                              'userImage': chat.profilePicture,
                            },
                          ).then((_) {
                            chatCubit.loadConversations();
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, {required bool isSelected}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.lightYellow : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: isSelected ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: AppTextStyles.bold14cairo.copyWith(
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}