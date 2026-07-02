import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/admin_chat/models/admin_chat_models.dart';
import 'package:rafiq/features/admin_chat/persenation/logic/admin_chat_cubit.dart';
import 'package:rafiq/features/admin_chat/persenation/logic/admin_chat_state.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';

class AdminChatRoomView extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserImage;

  const AdminChatRoomView({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserImage,
  });

  @override
  State<AdminChatRoomView> createState() => _AdminChatRoomViewState();
}

class _AdminChatRoomViewState extends State<AdminChatRoomView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageTextChanged);
    
    // Initial scroll after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomImmediate();
    });
  }

  void _onMessageTextChanged() {
    final text = _messageController.text;
    if (text.isNotEmpty) {
      context.read<AdminChatCubit>().sendTypingStatus(widget.targetUserId, true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          context.read<AdminChatCubit>().sendTypingStatus(widget.targetUserId, false);
        }
      });
    }
  }

  void _scrollToBottomImmediate() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<AdminChatCubit>().sendMessage(text, receiverId: widget.targetUserId == 'admin' ? null : widget.targetUserId);
      _messageController.clear();
      context.read<AdminChatCubit>().sendTypingStatus(widget.targetUserId, false);
      _scrollToBottom();
    }
  }

  Future<void> _handlePickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      if (mounted) {
        context.read<AdminChatCubit>().sendImageMessage(
          image.path,
          receiverId: widget.targetUserId == 'admin' ? null : widget.targetUserId,
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    // Format local time to standard HH:MM AM/PM
    final localTime = dateTime.toLocal();
    final hour = localTime.hour > 12 
        ? localTime.hour - 12 
        : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.targetUserId == 'admin' ? 'Admin' : widget.targetUserName;
    final initials = displayName.trim().isEmpty 
        ? 'DY' 
        : displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();

    return Scaffold(
      backgroundColor: AppColors.babypink, 
      appBar: AppBar(
        backgroundColor: AppColors.babypink,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.grey2, size: 20),
          onPressed: () {
            // Clear active room state when leaving
            context.read<AdminChatCubit>().setActiveRoom(null);
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: widget.targetUserId == 'admin' ? 'assets/images/admin_logo.svg' : widget.targetUserImage,
                radius: 18.r,
                name: displayName,
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.targetUserId == 'admin' ? "Chat with Admin" : widget.targetUserName, 
                      style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    BlocBuilder<AdminChatCubit, AdminChatState>(
                      builder: (context, state) {
                        if (state.isTyping) {
                          return Text(
                            "Typing...", 
                            style: AppTextStyles.regular14cairo.copyWith(color: Colors.green, fontSize: 10.sp),
                          );
                        }
                        return Text(
                          "Online", 
                          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey12, fontSize: 10.sp),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          )
        ],
      ),
      body: BlocListener<AdminChatCubit, AdminChatState>(
        listenWhen: (previous, current) => previous.messages.length != current.messages.length,
        listener: (context, state) {
          _scrollToBottom();
        },
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<AdminChatCubit, AdminChatState>(
                builder: (context, state) {
                  if (state.isMessagesLoading && state.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.messagesError != null && state.messages.isEmpty) {
                    return Center(
                      child: Text(
                        "Error: ${state.messagesError}", 
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (state.messages.isEmpty) {
                    return Center(
                      child: Text(
                        "No messages yet. Say hello!",
                        style: AppTextStyles.regular14cairo.copyWith(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      // Message is sent by me if the senderId matches the state's cached currentUserId.
                      final isMe = msg.senderId == state.currentUserId;
                      return _buildChatBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(AdminChatMessage msg, bool isMe) {
    final timeStr = _formatTime(msg.createdAt);
    final hasMedia = msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty;
    
    // Resolve full media URL
    final baseUrl = 'http://10.0.2.2:5000';
    final fullImageUrl = hasMedia
        ? (msg.mediaUrl!.startsWith('http') ? msg.mediaUrl! : '$baseUrl${msg.mediaUrl}')
        : '';

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4.h),
            padding: hasMedia ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryNormal : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: isMe ? Radius.circular(15.r) : Radius.zero,
                topRight: isMe ?  Radius.zero: Radius.circular(15.r) ,
                bottomLeft:  Radius.circular(15.r) ,
                bottomRight:   Radius.circular(15.r),
              ),
              boxShadow: [
                if (!isMe)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
              ],
            ),
            clipBehavior: hasMedia ? Clip.antiAlias : Clip.none,
            child: hasMedia
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        fullImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200.h,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150.h,
                            color: Colors.grey.shade100,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey),
                                SizedBox(height: 8),
                                Text("Failed to load image", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                      if (msg.content.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          child: Text(
                            msg.content,
                            style: AppTextStyles.regular14cairo.copyWith(
                              color: isMe ? Colors.white : AppColors.grey2,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Text(
                      msg.content,
                      style: AppTextStyles.regular14cairo.copyWith(
                        color: isMe ? Colors.white : AppColors.grey2,
                        height: 1.3,
                      ),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 8.h, left: isMe ? 4.w : 0, right: isMe ? 0 : 4.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: AppTextStyles.regular12inter.copyWith(color: Colors.grey.shade400, fontSize: 10.sp),
              ),
              if (isMe) ...[
                4.horizontalSpace,
                Icon(
                  msg.isRead ? Icons.done_all : Icons.done,
                  size: 12.sp,
                  color: msg.isRead ? AppColors.primaryNormal : Colors.grey.shade400,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 24.h, top: 8.h),
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppColors.grey12),
            onPressed: _handlePickImage,
          ),
          5.horizontalSpace,
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _handleSendMessage(),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey9),
                filled: true,
                fillColor: AppColors.grey13,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          10.horizontalSpace,
          GestureDetector(
            onTap: _handleSendMessage,
            child: CircleAvatar(
              radius: 22.r,
              backgroundColor: AppColors.primaryNormal,
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}