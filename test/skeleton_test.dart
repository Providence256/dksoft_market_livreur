import 'package:dksoft_market_livreur/core/widgets/loading_dots.dart';
import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/widgets/delivery_list_skeleton.dart';
import 'package:dksoft_market_livreur/features/earnings/presentation/widgets/earnings_skeleton.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_skeleton.dart';
import 'package:dksoft_market_livreur/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:dksoft_market_livreur/features/reviews/presentation/reviews_skeleton.dart';
import 'package:dksoft_market_livreur/utils/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final skeletons = <String, Widget>{
    'page': const PageSkeleton(),
    'accueil': const DashboardSkeleton(),
    'demandes': const DeliveryListSkeleton(),
    'gains': const EarningsSkeleton(),
    'avis': const ReviewsSkeleton(),
    'profil': const ProfileSkeleton(),
    'carte': const MapSkeleton(),
  };

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    for (final MapEntry(:key, :value) in skeletons.entries) {
      testWidgets('squelette $key (${theme.brightness.name})', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(body: value),
          ),
        );
        // Quelques images du reflet : aucune exception ni débordement.
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(tester.takeException(), isNull);
        expect(find.byType(SkeletonBox), findsWidgets);
      });
    }
  }

  testWidgets('les points de chargement tournent sans erreur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: LoadingDots(color: Colors.blue)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
