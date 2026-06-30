import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/video/persentation/age_stage_view.dart';
import 'package:rafiq/features/video/persentation/logic/video_card_cubit.dart';
import 'package:rafiq/features/video/persentation/logic/video_card_state.dart';
import 'package:rafiq/features/video/persentation/widgets/category_video_card.dart';
import 'package:rafiq/features/video/domain/entities/video_category_entity.dart';

class EducationalVideosView extends StatelessWidget {
  const EducationalVideosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CategoryCubit>()..fetchCategories(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryNormal),
              );
            } 
            else if (state is CategorySuccess) {
              return _buildCategoriesList(state.categories);
            } 
            else if (state is CategoryError) {
              return _buildErrorWidget(context, state.message);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Educational Videos",
        style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
      ),
    );
  }

  Widget _buildCategoriesList(List<VideoCategoryEntity> categories) {
    // Map category titles to their SRS-defined type identifiers
    const categoryTypeMap = {
      'Parenting': 'parenting',
      'Marital Relationships': 'marital',
      'Youth (21–30)': 'family',
    };

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryType = categoryTypeMap[category.title] ?? 'parenting';
        return CategoryVideoCard(
          title: category.title,
          description: category.description,
          iconName: category.iconName,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgeStagesView(categoryType: categoryType),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: AppTextStyles.regular16cairo),
          4.verticalSpace,
          TextButton(
            onPressed: () => context.read<CategoryCubit>().fetchCategories(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}