import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/widgets/apptextformfield.dart';
import 'package:rafiq/core/widgets/custom_appbar.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/core/widgets/label_field.dart';
import 'package:rafiq/features/profile/domain/entities/profile_entity.dart';
import 'package:rafiq/features/profile/persentation/logic/profile_cubit.dart';
import 'package:rafiq/features/profile/persentation/logic/profile_state.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';

class EditProfileView extends StatefulWidget {
  final ProfileEntity user;

  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController ageController;
  late TextEditingController childrenController;
  String? selectedStatus;
  String? selectedChildren;

  /// Tracks the current profile picture URL shown in the avatar.
  /// Starts as the value from the passed entity; updated when a new
  /// picture is uploaded successfully.
  String? _currentPictureUrl;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // All 3 SRS-required statuses
  static const _statuses = ['Single', 'Married', 'Divorced'];
  static const _childrenOptions = ['0', '1', '2', '3', '4+'];

  bool get _showChildrenField => selectedStatus == 'Married';

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user.firstName);
    lastNameController = TextEditingController(text: widget.user.lastName);
    phoneController = TextEditingController(text: widget.user.phone);
    ageController = TextEditingController(text: widget.user.age.toString());
    childrenController =
        TextEditingController(text: widget.user.childrenCount.toString());
    // Ensure the stored status is one of the valid values
    selectedStatus =
        _statuses.contains(widget.user.status) ? widget.user.status : 'Single';
    selectedChildren = widget.user.childrenCount.toString();
    _currentPictureUrl = widget.user.profilePicture;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    childrenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: "Edit Profile"),
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state is UpdateProfileSuccess) {
              // Text fields saved → navigate back; the profile view will refresh.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profile Updated!"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is UploadPictureSuccess) {
              // Picture uploaded → update avatar preview in place.
              AppAvatar.refreshCache();
              setState(() => _currentPictureUrl = state.pictureUrl);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profile picture updated!"),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is UpdateProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is UploadPictureError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is UpdateProfileLoading;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    20.verticalSpace,
                    _buildAvatar(context, isLoading),
                    30.verticalSpace,

                    const LabelField(text: "First Name"),
                    AppTextFormField(
                      hintText: "Enter your first name",
                      controller: firstNameController,
                      validator: (val) => val!.isEmpty ? "Required" : null,
                      suffixIcon: const Icon(Icons.person_outline,
                          color: Colors.grey),
                    ),

                    20.verticalSpace,
                    const LabelField(text: "Last Name"),
                    AppTextFormField(
                      hintText: "Enter your last name",
                      controller: lastNameController,
                      validator: (val) => val!.isEmpty ? "Required" : null,
                      suffixIcon: const Icon(Icons.person_outline,
                          color: Colors.grey),
                    ),

                    20.verticalSpace,
                    const LabelField(text: "Phone Number"),
                    AppTextFormField(
                      hintText: "Phone Number",
                      controller: phoneController,
                      validator: (val) => val!.isEmpty ? "Required" : null,
                      suffixIcon:
                          const Icon(Icons.phone_outlined, color: Colors.grey),
                    ),

                    20.verticalSpace,
                    const LabelField(text: "Age"),
                    AppTextFormField(
                      hintText: "Age",
                      controller: ageController,
                      validator: (val) => val!.isEmpty ? "Required" : null,
                      keyboardType: TextInputType.number,
                    ),

                    20.verticalSpace,
                    const LabelField(text: "Status"),
                    _buildDropdown(
                      _statuses,
                      selectedStatus,
                      (val) => setState(() => selectedStatus = val),
                    ),

                    // Conditional — only shown when Married (SRS §2.1)
                    if (_showChildrenField) ...[
                      20.verticalSpace,
                      const LabelField(text: "Number of Children"),
                      _buildDropdown(
                        _childrenOptions,
                        _childrenOptions.contains(selectedChildren)
                            ? selectedChildren
                            : '0',
                        (val) => setState(() => selectedChildren = val),
                      ),
                    ],

                    40.verticalSpace,

                    CustomButton(
                      text: isLoading ? "Saving..." : "Save Changes",
                      onPressed:
                          isLoading ? null : () => _save(context),
                    ),

                    12.verticalSpace,
                    CustomButton(
                      text: "Cancel",
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: Colors.white,
                      textColor: AppColors.primaryNormal,
                    ),
                    20.verticalSpace,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    if (formKey.currentState!.validate()) {
      final childCount = _showChildrenField
          ? int.tryParse((selectedChildren ?? '0').replaceAll('+', '')) ?? 0
          : 0;
      final updatedUser = ProfileEntity(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: phoneController.text.trim(),
        age: int.tryParse(ageController.text) ?? 0,
        status: selectedStatus ?? 'Single',
        childrenCount: childCount,
        bio: widget.user.bio,
        profilePicture: _currentPictureUrl,
      );
      context.read<ProfileCubit>().updateProfile(updatedUser);
    }
  }

  Widget _buildAvatar(BuildContext context, bool isLoading) {
    // Use _currentPictureUrl which is updated after a successful upload.
    final hasPicture =
        _currentPictureUrl != null && _currentPictureUrl!.isNotEmpty;
    final imageUrl =
        hasPicture ? "http://10.0.2.2:5000$_currentPictureUrl" : "";

    return Center(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null && mounted) {
                  context
                      .read<ProfileCubit>()
                      .uploadProfilePicture(image.path);
                }
              },
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            AppAvatar(
              imageUrl: _currentPictureUrl,
              radius: 60.r,
              name: widget.user.fullName,
            ),
            if (isLoading)
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18.r,
                  backgroundColor: AppColors.primaryNormal,
                  child: SizedBox(
                    width: 18.sp,
                    height: 18.sp,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primaryNormal,
                child:
                    Icon(Icons.camera_alt, color: Colors.white, size: 16.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(border: InputBorder.none),
        items:
            items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}