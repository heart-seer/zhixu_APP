import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../shared/data_providers.dart';

final registerControllerProvider = ChangeNotifierProvider.autoDispose<RegisterController>((ref) => RegisterController(ref));

class RegisterController extends ChangeNotifier {
  RegisterController(this.ref);

  final Ref ref;
  bool isLoading = false;

  Future<void> register({required String phone, required String password}) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await ref.read(dioClientProvider).dio.post(ApiEndpoints.register, data: {
        'phone': phone,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
      final token = payload['accessToken']?.toString();
      if (token == null || token.isEmpty) throw const FormatException('注册响应缺少访问令牌');
      await ref.read(secureStorageProvider).saveToken(token);
      final refreshToken = payload['refreshToken']?.toString();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ref.read(secureStorageProvider).saveRefreshToken(refreshToken);
      }
      ref.invalidate(repositoryProvider);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit(RegisterController controller) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await controller.register(phone: _phone.text.trim(), password: _password.text);
      if (mounted) context.go(RouteNames.home);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('注册智序')),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 24),
                const Text('创建你的账号', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                const Text('注册后即可同步管理任务与日程', style: AppTextStyles.caption),
                const SizedBox(height: 28),
                AppTextField(controller: _phone, label: '手机号', hint: '请输入手机号', keyboardType: TextInputType.phone, prefix: const Icon(Icons.phone_iphone), maxLength: 11, validator: Validators.phone),
                const SizedBox(height: 16),
                AppTextField(controller: _password, label: '设置密码', hint: '至少8位', obscureText: true, prefix: const Icon(Icons.lock_outline), validator: Validators.password),
                const SizedBox(height: 16),
                AppTextField(controller: _confirmPassword, label: '确认密码', hint: '请再次输入密码', obscureText: true, prefix: const Icon(Icons.lock_reset), validator: (value) => value == _password.text ? null : '两次输入的密码不一致'),
                const SizedBox(height: 24),
                AppButton(label: '注 册', isLoading: state.isLoading, onPressed: () => _submit(controller)),
                const SizedBox(height: 12),
                Center(child: TextButton(onPressed: () => context.go(RouteNames.auth), child: const Text('已有账号？返回登录'))),
                const SizedBox(height: 8),
                Center(child: Text.rich(TextSpan(style: AppTextStyles.caption, children: const [TextSpan(text: '注册即表示同意'), TextSpan(text: '《用户协议》', style: TextStyle(color: AppColors.primary)), TextSpan(text: '与'), TextSpan(text: '《隐私政策》', style: TextStyle(color: AppColors.primary))]))),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        )),
      ),
    );
  }
}
