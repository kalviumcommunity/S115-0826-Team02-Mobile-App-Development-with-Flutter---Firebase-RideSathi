import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/profile_controller.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/info_banner.dart';

/// Screen for viewing and updating authenticated user profile information.
///
/// Supports role-specific configurations:
/// - Riders can edit name and phone number.
/// - Drivers can edit name, phone number, and vehicle info.
/// - Immutable fields (UID, email, role, union verification, createdAt) are strictly read-only.
/// - Warns users before discarding unsaved modifications via [PopScope].
class ProfileScreen extends StatefulWidget {
  final AuthController? authController;
  final ProfileController? profileController;
  final UserProfileService? userProfileService;

  const ProfileScreen({
    super.key,
    this.authController,
    this.profileController,
    this.userProfileService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AuthController _authController;
  late final ProfileController _profileController;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vehicleInfoController;

  bool _isUpdatingFromController = false;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
    if (widget.profileController != null) {
      _profileController = widget.profileController!;
    } else {
      _profileController = ProfileController(
        authController: _authController,
        userProfileService: widget.userProfileService ?? _authController.userProfileService,
      );
    }

    _nameController = TextEditingController(text: _profileController.name);
    _phoneController = TextEditingController(text: _profileController.phoneNumber);
    _vehicleInfoController =
        TextEditingController(text: _profileController.vehicleInfo ?? '');

    _nameController.addListener(_onNameFieldChanged);
    _phoneController.addListener(_onPhoneFieldChanged);
    _vehicleInfoController.addListener(_onVehicleFieldChanged);

    _profileController.addListener(_onProfileStateChanged);
  }

  void _onNameFieldChanged() {
    if (_isUpdatingFromController) return;
    _profileController.setName(_nameController.text);
  }

  void _onPhoneFieldChanged() {
    if (_isUpdatingFromController) return;
    _profileController.setPhoneNumber(_phoneController.text);
  }

  void _onVehicleFieldChanged() {
    if (_isUpdatingFromController) return;
    _profileController.setVehicleInfo(_vehicleInfoController.text);
  }

  void _onProfileStateChanged() {
    if (!mounted) return;

    _isUpdatingFromController = true;
    try {
      if (_nameController.text != _profileController.name) {
        _nameController.text = _profileController.name;
      }
      if (_phoneController.text != _profileController.phoneNumber) {
        _phoneController.text = _profileController.phoneNumber;
      }
      final currentVehicle = _profileController.vehicleInfo ?? '';
      if (_vehicleInfoController.text != currentVehicle) {
        _vehicleInfoController.text = currentVehicle;
      }
    } finally {
      _isUpdatingFromController = false;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameFieldChanged);
    _phoneController.removeListener(_onPhoneFieldChanged);
    _vehicleInfoController.removeListener(_onVehicleFieldChanged);

    _nameController.dispose();
    _phoneController.dispose();
    _vehicleInfoController.dispose();

    _profileController.removeListener(_onProfileStateChanged);
    if (widget.profileController == null) {
      _profileController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_profileController.isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await _profileController.saveProfile();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDiscard() {
    _profileController.resetForm();
    _formKey.currentState?.reset();
  }

  Future<bool> _onWillPop() async {
    if (!_profileController.isDirty) {
      return true;
    }

    final shouldDiscard = await showAppConfirmationDialog(
      context,
      title: 'Discard Changes?',
      message:
          'You have unsaved changes to your profile. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep Editing',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (shouldDiscard == true) {
      _profileController.resetForm();
      return true;
    }
    return false;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Not available';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = _profileController.currentUser ?? _authController.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(
          child: Text('No authenticated user profile available.'),
        ),
      );
    }

    final isDriver = user.role == UserRole.driver;
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : '?';

    return PopScope(
      canPop: !_profileController.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _onWillPop();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_profileController.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceXL,
              vertical: AppConstants.spaceL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar & Identity Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.spaceXL),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: isDriver
                            ? AppConstants.primaryAmber
                            : theme.colorScheme.primary,
                        foregroundColor: isDriver
                            ? Colors.black
                            : theme.colorScheme.onPrimary,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceM),
                      Text(
                        user.name.isNotEmpty ? user.name : 'RideSathi User',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'No email provided',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceM),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppConstants.spaceS,
                        runSpacing: AppConstants.spaceS,
                        children: [
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDriver
                                  ? AppConstants.primaryAmber.withValues(alpha: 0.2)
                                  : theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                              border: Border.all(
                                color: isDriver
                                    ? AppConstants.primaryAmber
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDriver
                                      ? Icons.directions_car_rounded
                                      : Icons.person_rounded,
                                  size: 16,
                                  color: isDriver
                                      ? (isDark ? Colors.amber : const Color(0xFF946200))
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isDriver ? 'Driver' : 'Rider',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDriver
                                        ? (isDark ? Colors.amber : const Color(0xFF946200))
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Driver Union Verification Badge
                          if (isDriver)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: user.isUnionVerified
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                                border: Border.all(
                                  color: user.isUnionVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    user.isUnionVerified
                                        ? Icons.verified_rounded
                                        : Icons.pending_outlined,
                                    size: 16,
                                    color: user.isUnionVerified
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.isUnionVerified
                                        ? 'Union Verified'
                                        : 'Verification Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: user.isUnionVerified
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXL),

                // Error Banner
                if (_profileController.errorMessage != null) ...[
                  InfoBanner(
                    icon: Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                    message: _profileController.errorMessage!,
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                ],

                // Section: Personal Information
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceM),
                AuthTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  validator: Validators.name,
                ),
                const SizedBox(height: AppConstants.spaceL),
                AuthTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppConstants.spaceL),
                TextFormField(
                  initialValue: user.email ?? 'Not provided',
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    helperText: 'Account email cannot be modified.',
                    helperMaxLines: 1,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXL),

                // Section: Driver & Vehicle Information (Drivers Only)
                if (isDriver) ...[
                  Text(
                    'Driver & Vehicle Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  AuthTextField(
                    controller: _vehicleInfoController,
                    label: 'Vehicle Information',
                    icon: Icons.directions_car_outlined,
                    keyboardType: TextInputType.text,
                    validator: Validators.vehicleInfo,
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spaceM),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppConstants.spaceS),
                        Expanded(
                          child: Text(
                            'Union verification is managed by union administrators. It cannot be altered from your profile settings.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceXL),
                ],

                // Section: Account Details
                Text(
                  'Account Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceM),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spaceL),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account Role',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            isDriver ? 'Driver' : 'Rider',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Member Since',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _formatDate(user.createdAt),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (user.updatedAt != null) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Last Updated',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _formatDate(user.updatedAt),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXXL),

                // Form Action Buttons
                CustomButton(
                  label: 'Save Changes',
                  icon: Icons.save_outlined,
                  isLoading: _profileController.isSaving,
                  onPressed: (_profileController.isDirty && !_profileController.isSaving)
                      ? _handleSave
                      : null,
                ),
                if (_profileController.isDirty) ...[
                  const SizedBox(height: AppConstants.spaceM),
                  CustomButton(
                    label: 'Discard Changes',
                    icon: Icons.undo_rounded,
                    isSecondary: true,
                    onPressed: !_profileController.isSaving ? _handleDiscard : null,
                  ),
                ],
                const SizedBox(height: AppConstants.spaceXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
