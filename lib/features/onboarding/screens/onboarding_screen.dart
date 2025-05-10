import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/core/models/user_profile.dart';
import 'package:medalarmm/features/profile/providers/user_profile_provider.dart';
import 'package:medalarmm/app/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 4;
  bool _isNameEntered = false;
  
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Onboarding tamamlandı bilgisini kaydet
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (!mounted) return;
    
    // Kullanıcı adını kaydet ve ana ekrana git
    final userProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final profile = userProvider.userProfile?.copyWith(name: _nameController.text) ??
        UserProfile(name: _nameController.text);
    
    await userProvider.updateUserProfile(profile);
    
    // Ana ekrana yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [            // Üst kısım - İlerleme göstergesi ve atla butonu
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // İlerleme göstergesi
                  Row(
                    children: List.generate(
                      _numPages,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                      .animate(target: _currentPage == index ? 1 : 0)
                      .scaleX(begin: 1, end: 3, duration: 300.ms, curve: Curves.easeOutQuad)
                      .animate(target: _currentPage == index ? 1 : 0)
                      .shimmer(
                        duration: 1200.ms,
                        color: Colors.white.withOpacity(0.7),
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                  ),
                  
                  // Atla butonu - son sayfada gizlenir
                  if (_currentPage < _numPages - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _numPages - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Atla'),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms),
                ],
              ),
            ),
              // Sayfa içeriği
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },              physics: const ClampingScrollPhysics(),
                children: [
                  _buildOnboardingPage(
                    image: 'assets/images/placeholder.png',
                    title: 'MedAlarm\'a Hoş Geldiniz',
                    description: 'İlaçlarınızı düzenli almanıza yardımcı olacak akıllı ilaç takip uygulaması.',
                    icon: Icons.medication_liquid,
                    lottieAsset: 'assets/animations/welcome.json',
                  ),
                  _buildOnboardingPage(
                    image: 'assets/images/placeholder.png',
                    title: 'İlaç Hatırlatıcıları',
                    description: 'İlaçlarınızı zamanında almanız için sesli ve görsel hatırlatmalar alın.',
                    icon: Icons.alarm_on,
                    lottieAsset: 'assets/animations/notifications.json',
                  ),
                  _buildOnboardingPage(
                    image: 'assets/images/placeholder.png',
                    title: 'Sağlık Takibi',
                    description: 'İlaç kullanımınızı ve sağlık durumunuzu analiz edin, raporlar alın.',
                    icon: Icons.monitor_heart,
                    lottieAsset: 'assets/animations/health_tracking.json',
                  ),
                  _buildFinalPage(),
                ],
              ),
            ),
              // Alt kısım - İleri veya başla butonu
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage == _numPages - 1
                      ? (_isNameEntered ? _completeOnboarding : null)
                      : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.paddingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    ),
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: Text(
                    _currentPage == _numPages - 1 ? 'Başla' : 'Devam Et',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms)
              .then()
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: 1.seconds,
              )
              .scaleXY(
                begin: 1.0, 
                end: 1.05, 
                duration: 2.seconds, 
                curve: Curves.easeInOut
              ),
            ),
          ],
        ),
      ),
    );
  }  // Normal onboarding sayfası şablonu
  Widget _buildOnboardingPage({
    required String image,
    required String title,
    required String description,
    required IconData icon,
    String? lottieAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animasyonlu ikon
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 100,
              color: AppColors.primary,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .fadeIn(duration: 600.ms)
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 1200.ms,
          )
          .then()
          .shimmer(
            duration: 1800.ms,
            color: Colors.white.withOpacity(0.6),
            curve: Curves.easeInOutCubic,
          )
          .animate(delay: 2.seconds)
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 800.ms,
          )
          .then(delay: 600.ms)
          .scale(
            begin: const Offset(1.05, 1.05),
            end: const Offset(1.0, 1.0),
            duration: 800.ms,
          ),
          
          const SizedBox(height: AppDimens.paddingXL),
          
          // Başlık
          Text(
            title,
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(duration: 500.ms, delay: 300.ms)
          .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
          
          const SizedBox(height: AppDimens.paddingL),
          
          // Açıklama
          Text(
            description,
            style: AppTextStyles.bodyText,
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(duration: 500.ms, delay: 500.ms)
          .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
        ],
      ),
    );
  }
  // Son sayfa - Kullanıcı adı girişi
  Widget _buildFinalPage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_pin,
              size: 120,
              color: AppColors.primary,
            )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.0, 1.0),
              duration: 700.ms,
              curve: Curves.elasticOut,
            )
            .then(delay: 1.seconds)
            .shimmer(
              duration: 1800.ms,
              color: Colors.white.withOpacity(0.6),
              curve: Curves.easeInOutCubic,
            ),
            
            const SizedBox(height: AppDimens.paddingL),
            
            Text(
              'Son Adım',
              style: AppTextStyles.heading1,
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 300.ms)
            .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
            
            const SizedBox(height: AppDimens.paddingM),
            
            Text(
              'Kişiselleştirilmiş deneyim için lütfen adınızı girin.',
              style: AppTextStyles.bodyText,
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 500.ms)
            .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
            
            const SizedBox(height: AppDimens.paddingXL),
            
            // İsim giriş formu
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Adınız',
                  hintText: 'Adınızı girin',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen adınızı girin';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Form doğrulaması yap
                  setState(() {
                    _isNameEntered = _formKey.currentState!.validate();
                  });
                },
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms, delay: 700.ms)
            .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
            
            const SizedBox(height: AppDimens.paddingL),
            
            // Gizlilik ve kullanım şartları (opsiyonel)
            const Text(
              'Devam ederek Gizlilik Politikamızı ve Kullanım Şartlarımızı kabul etmiş olursunuz.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(duration: 800.ms, delay: 900.ms),
          ],
        ),
      ),
    );
  }
}
