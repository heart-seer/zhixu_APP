import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../shared/data_providers.dart';

final loginControllerProvider = ChangeNotifierProvider.autoDispose<LoginController>((ref) => LoginController(ref));

enum LoginMode { phone, password }

class LoginController extends ChangeNotifier {
  LoginController(this.ref);

  final Ref ref;
  LoginMode mode = LoginMode.password;
  bool isLoading = false;
  int countdown = 0;
  Timer? _timer;

  void setMode(LoginMode value) {
    mode = value;
    notifyListeners();
  }

  Future<void> requestCode(String phone) async {
    if (Validators.phone(phone) != null || countdown > 0) return;
    try {
      await ref.read(dioClientProvider).dio.post(ApiEndpoints.sendCode, data: {'phone': phone});
      countdown = AppConstants.codeCountdownSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        countdown--;
        if (countdown <= 0) timer.cancel();
        notifyListeners();
      });
      notifyListeners();
    } finally {
      // 网络错误由页面提交操作统一展示。
    }
  }

  Future<bool> login({required String phone, required String password, required String code}) async {
    isLoading = true;
    notifyListeners();
    try {
      final endpoint = mode == LoginMode.phone ? ApiEndpoints.loginByCode : ApiEndpoints.loginByPassword;
      final response = await ref.read(dioClientProvider).dio.post(endpoint, data: mode == LoginMode.phone
          ? {'phone': phone, 'code': code}
          : {'phone': phone, 'password': password});
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
      final token = payload['accessToken']?.toString();
      if (token == null || token.isEmpty) throw const FormatException('登录响应缺少访问令牌');
      await ref.read(secureStorageProvider).saveToken(token);
      final refreshToken = payload['refreshToken']?.toString();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ref.read(secureStorageProvider).saveRefreshToken(refreshToken);
      }
      ref.invalidate(repositoryProvider);
      return true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginController controller) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (await controller.login(phone: _phone.text.trim(), password: _password.text, code: _code.text.trim()) && mounted) {
        context.go(RouteNames.home);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 38),
                Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)), child: const Icon(Icons.auto_awesome, color: Colors.white)),
                  const SizedBox(width: 12),
                  const Text('智序', style: AppTextStyles.title),
                ]),
                const SizedBox(height: 40),
                const Text('欢迎回来', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                const Text('登录智序，开启高效工作与生活', style: AppTextStyles.caption),
                const SizedBox(height: 30),
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.border.withValues(alpha: .45), borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                  child: Row(children: [
                    _tab('手机号登录', LoginMode.phone, state.mode),
                    _tab('账号密码', LoginMode.password, state.mode),
                  ]),
                ),
                const SizedBox(height: 22),
                AppTextField(controller: _phone, label: '手机号', hint: '请输入手机号', keyboardType: TextInputType.phone, prefix: const Icon(Icons.phone_iphone), maxLength: 11, validator: Validators.phone),
                const SizedBox(height: 16),
                if (state.mode == LoginMode.phone)
                  AppTextField(
                    controller: _code,
                    label: '短信验证码',
                    hint: '请输入验证码',
                    keyboardType: TextInputType.number,
                    prefix: const Icon(Icons.verified_user_outlined),
                    maxLength: 6,
                    validator: Validators.verificationCode,
                    suffix: TextButton(
                      onPressed: state.countdown > 0 ? null : () async {
                        try { await controller.requestCode(_phone.text.trim()); }
                        catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
                      },
                      child: Text(state.countdown > 0 ? '${state.countdown}s 后重试' : '获取验证码'),
                    ),
                  )
                else
                  AppTextField(controller: _password, label: '密码', hint: '请输入密码', obscureText: true, prefix: const Icon(Icons.lock_outline), validator: Validators.password),
                const SizedBox(height: 24),
                AppButton(label: '登 录', isLoading: state.isLoading, onPressed: () => _submit(controller)),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(RouteNames.register),
                    child: const Text('新用户？立即注册'),
                  ),
                ),
                Center(child: TextButton(onPressed: () {}, child: const Text('登录遇到问题？'))),
                const SizedBox(height: 10),
                Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('其他登录方式', style: AppTextStyles.caption)), const Expanded(child: Divider())]),
                const SizedBox(height: 22),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _social(Icons.wechat, '微信登录', AppColors.success, () => _showNotice('微信一键登录')),
                  _social(Icons.apple, 'Apple 登录', AppColors.textPrimary, () => _showNotice('Apple 登录')),
                  _social(Icons.business_outlined, '企业 SSO', AppColors.primary, () => _showNotice('企业 SSO 登录')),
                ]),
                const SizedBox(height: 30),
                Center(child: Text.rich(TextSpan(style: AppTextStyles.caption, children: const [TextSpan(text: '登录即表示同意'), TextSpan(text: '《用户协议》', style: TextStyle(color: AppColors.primary)), TextSpan(text: '与'), TextSpan(text: '《隐私政策》', style: TextStyle(color: AppColors.primary))]))),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        )),
      ),
    );
  }

  Widget _tab(String label, LoginMode value, LoginMode selected) => Expanded(
        child: GestureDetector(
          onTap: () => ref.read(loginControllerProvider).setMode(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: selected == value ? AppColors.surface : Colors.transparent, borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: selected == value ? FontWeight.w600 : FontWeight.w400, color: selected == value ? AppColors.textPrimary : AppColors.textSecondary)),
          ),
        ),
      );

  Widget _social(IconData icon, String label, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: SizedBox(width: 92, child: Column(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppDimensions.radiusMd)), child: Icon(icon, color: color, size: 25)),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ])),
      );

  void _showNotice(String method) => showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: Text(method),
        content: const Text('该登录方式需要接入对应的服务配置。'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))],
      ));
}
