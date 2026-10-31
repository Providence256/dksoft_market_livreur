import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/earnings/domain/payout_request.dart';
import 'package:dksoft_market_livreur/features/earnings/presentation/widgets/withdraw_sheet.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/formatters/date_formatter_fr.dart';
import 'package:flutter/material.dart';

/// Solde retirable et bouton de retrait.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.livreur});

  final LivreurModel livreur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = livreur.soldeDisponible;
    final canWithdraw =
        livreur.status == LivreurStatus.valide && balance >= kMinPayout;

    return AppCard(
      padding: const EdgeInsets.all(Sizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: AppIcons.coins, color: AppColors.success),
              gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solde disponible', style: theme.textTheme.bodySmall),
                    Text(
                      CurrencyFormatter.formatUsd(balance),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          gapH8,
          Text(
            'Total gagné depuis le début : '
            '${CurrencyFormatter.formatUsd(livreur.gains)}',
            style: theme.textTheme.bodySmall,
          ),
          gapH16,
          AppButton(
            label: canWithdraw
                ? 'Retirer mes gains'
                : 'Retrait possible dès '
                      '${kMinPayout.toStringAsFixed(0)} USD',
            icon: AppIcons.wallet,
            onPressed: canWithdraw
                ? () async {
                    final sent = await showWithdrawSheet(
                      context,
                      balance: balance,
                      phone: livreur.phone,
                    );
                    if (sent && context.mounted) {
                      Toast.success(context, 'Demande de retrait envoyée.');
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// Une demande de retrait de l'historique.
class PayoutTile extends StatelessWidget {
  const PayoutTile({super.key, required this.request});

  final PayoutRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = request.createdAt;
    final tone = switch (request.status) {
      PayoutStatus.enAttente => PillTone.warning,
      PayoutStatus.validee => PillTone.success,
      PayoutStatus.refusee => PillTone.error,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.p16,
        vertical: Sizes.p12,
      ),
      child: Row(
        children: [
          IconTile(icon: AppIcons.wallet, color: context.palette.primary),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.formatUsd(request.amount),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  [
                    request.method,
                    if (date != null) DateFormatterFr.dayLabel(date),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Pill(label: request.status.label, tone: tone),
        ],
      ),
    );
  }
}
