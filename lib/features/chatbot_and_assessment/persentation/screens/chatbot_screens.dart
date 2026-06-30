import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart'; // أو AppRouter حسب ملف الـ Routing بتاعك
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
  
  // 🌟 العلم السحري: الأبلكيشن هيبدأ دايماً بـ false عشان يثبت على شاشة الـ Welcome
  bool _isChatStarted = false; 

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
        title: Text("Rafiq AI", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
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
              const SizedBox(height: 20),
              Expanded(
                // 🚀 الـ Logic الجديد: لو الشات مابتدأش بـ فعل من اليوزر، اعرض الـ Welcome View دايماً!
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

  // 1️⃣ شاشة الترحيب (تفتح دايماً كـ بداية أساسية للشاشة)
  Widget _buildWelcomeView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 50),
          CircleAvatar(
            radius: 65,
            backgroundColor: AppColors.lightYellow.withOpacity(0.2),
            child: const Icon(Icons.smart_toy, size: 70, color: AppColors.lightYellow),
          ),
          const SizedBox(height: 30),
          Text("How can I help you today?", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
          const SizedBox(height: 40),
          _suggestionCard(context, "Parenting Advice"),
          _suggestionCard(context, "Relationship Help"),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Start Assessment',
            textColor: Colors.white,
            textstyle: AppTextStyles.bold16cairo,
            height: 50,
            width: 298,
            borderRadius: 10,
            onPressed: () {
              context.push(AppRouter.kAssessmentIntro);
            },
          ),
        ],
      ),
    );
  }

  // 2️⃣ شاشة عرض المحادثة
  Widget _buildChatConversation(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController, 
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildChatBubble(messages[index]),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: msg.isBot ? Colors.white : AppColors.lightYellow,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          msg.text,
          style: AppTextStyles.regular12inter.copyWith(
            color: msg.isBot ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }

  // 3️⃣ كروت الاقتراحات (Parenting Advice / Relationship Help)
  Widget _suggestionCard(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isChatStarted = true; // 🌟 اقلب الشاشة فوراً لشكل المحادثة
        });
        // يكتب الكلمة جوه الـ TextField تلقائياً
        _messageController.text = title;
        // 💡 اختياري: لو عاوزاها تتبعت تلقائي أول ما يضغط على الكارت، فكي التعليق عن السطرين دول:
        // context.read<ChatBloc>().sendMessage(title);
        // _messageController.clear();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bold16cairo.copyWith(color: AppColors.black2)),
            const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.lightYellow),
          ],
        ),
      ),
    );
  }

  // 4️⃣ منطقة إدخال الرسائل
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
              child: const Icon(Icons.face, color: Color(0xFF96A53A)),
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
                          _isChatStarted = true; // 🌟 إذا كتب رسالة بنفسه وداس إرسال، اقلب الشاشة للمحادثة
                        });
                        context.read<ChatBloc>().sendMessage(_messageController.text);
                        _messageController.clear();
                        FocusScope.of(context).unfocus(); 
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.lightYellow,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
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