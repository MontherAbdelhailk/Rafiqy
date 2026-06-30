import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/video/domain/repos/video_repo.dart';
import 'package:rafiq/features/video/persentation/logic/video_card_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final VideoRepo videoRepo;
  CategoryCubit(this.videoRepo) : super(CategoryInitial());

  Future<void> fetchCategories() async {
    emit(CategoryLoading());
    try {
      final data = await videoRepo.getCategories();
      emit(CategorySuccess(data));
    } catch (e) {
      emit(CategoryError("حدث خطأ في تحميل الفئات"));
    }
  }
}