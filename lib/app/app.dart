import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart';
import 'theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/services/theme_service.dart';

class SmashUpIndiaApp extends StatelessWidget {
  const SmashUpIndiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: (fontSize, instance) => fontSize.toDouble(),
      builder: (context, child) {
        return Obx(
          () => GetMaterialApp(
            title: 'SMASH UP INDIA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode.value,
            initialBinding: InitialBinding(),
            initialRoute: AppPages.initial,
            getPages: AppPages.routes,
            builder: (context, widget) {
              final mediaQuery = MediaQuery.of(context);
              final rawScale = mediaQuery.textScaler.scale(1.0);
              final clampedScale =
                  rawScale.clamp(0.85, AppConstants.maxTextScaleFactor);

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(clampedScale),
                ),
                child: widget ?? const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }
}
