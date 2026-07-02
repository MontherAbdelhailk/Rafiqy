import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart'; 
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/chatbot_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/chatbot_states.dart';

class ChatPage extends StatefulWidget { 
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isChatStarted = false; 

  // @override
  // void initState() {
  //   super.initState();
  //   context.read<ChatBloc>().getChatHistory('tokaa_mohamed_99');
  // }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, 
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
      surfaceTintColor: AppColors.babypink,
        title: Text("Rafiqy AI", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {})],
      ),
      body: BlocConsumer<ChatBloc, ChatState>( 
        listener: (context, state) {
          if (state is ChatLoaded || state is ChatLoading) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is ChatHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.lightYellow),
            );
          }

          List<ChatMessage> messages = [];
          if (state is ChatLoaded) {
            messages = state.messages; 
          } else if (state is ChatLoading) {
            messages = context.read<ChatBloc>().allMessages; 
          }


  return Column(
    children: [
      SizedBox(height: 20.h),
      Expanded(
        child: !_isChatStarted 
            ? _buildWelcomeView(context) 
            : _buildChatConversation(messages),
      ),
      _buildMessageInput(context),
    ],
  );
          },
      ),
    );
  }

  Widget _buildWelcomeView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 50.h),
          CircleAvatar(
            radius: 65.r,
            backgroundColor: AppColors.lightYellow.withOpacity(0.2),
            child: Icon(Icons.smart_toy, size: 70.sp, color: AppColors.lightYellow),
          ),
          SizedBox(height: 30.h),
          Text("How can I help you today?", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
          SizedBox(height: 40.h),
          _suggestionCard(context, "Parenting Advice"),
          _suggestionCard(context, "Relationship Help"),
          SizedBox(height: 20.h),
          CustomButton(
            text: 'Start Assessment',
            backgroundColor: AppColors.primaryNormalHover,
            textColor: Colors.white,
            textstyle: AppTextStyles.bold16cairo.copyWith(color: Colors.white),
            height: 50.h,
            width: 310.w,
            borderRadius: 10.r,
            onPressed: () {
              context.push(AppRouter.kAssessmentIntro);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatConversation(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true, 
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _buildChatBubble(messages[index]);
      },
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.isBot) ...[
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.lightYellow, 
              child: Icon(Icons.smart_toy, size: 18.sp, color: Colors.white),
            ),
            SizedBox(width: 8.w),
          ],

          Flexible(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: msg.isBot ? Colors.white : AppColors.lightYellow, 
                borderRadius: BorderRadius.only(
                  topLeft: msg.isBot ? const Radius.circular(0) : Radius.circular(20.r),
                  topRight: msg.isBot ? Radius.circular(20.r) : const Radius.circular(0),
                  bottomLeft: Radius.circular(20.r), 
                  bottomRight: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: AppTextStyles.regular12inter.copyWith(
                  color: msg.isBot ? Colors.black87 : Colors.white,
                  height: 1.4, 
                ),
              ),
            ),
          ),

          if (!msg.isBot) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 18.r,
              backgroundColor: const Color(0xFFF0DCD3), 
              child: Icon(Icons.person, size: 18.sp, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _suggestionCard(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isChatStarted = true; 
        });
        _messageController.text = title;
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30.w, vertical: 8.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bold16cairo.copyWith(color: AppColors.black2)),
            Icon(Icons.arrow_forward_ios, size: 10.sp, color: AppColors.lightYellow),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.lightYellow.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.lightYellow.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.face, color: const Color(0xFF96A53A), size: 24.sp),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Ask anything...",
                hintStyle: AppTextStyles.regular14merr.copyWith(color: AppColors.grey7),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: const BorderSide(color: AppColors.lightYellow, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: const BorderSide(color: AppColors.primaryNormal, width: 2),
                ),
                suffixIcon: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: GestureDetector(
                    onTap: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        setState(() {
                          _isChatStarted = true; 
                        });
                        context.read<ChatBloc>().sendMessage(_messageController.text);
                        _messageController.clear();
                        FocusScope.of(context).unfocus(); 
                      }
                    },
                    child: Container(
                      width: 28.w,
                      height: 28.h,
                      decoration: BoxDecoration(
                        color: AppColors.lightYellow,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.send, color: Colors.white, size: 18.sp),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}