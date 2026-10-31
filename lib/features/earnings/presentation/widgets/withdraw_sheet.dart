import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/earnings/domain/payout_request.dart';
import 'package:dksoft_market_livreur/features/earnings/presentation/payout_controller.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le formulaire de retrait. Renvoie true si une demande est partie.
Future<bool> showWithdrawSheet(
  BuildContext context, {
  required double balance,
  required String phone,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WithdrawSheet(balance: balance, phone: phone),
  );
  return sent ?? false;
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.balance, required this.phone});

  final double balance;

  /// Numéro du motard, proposé par défaut pour le mobile money.
  final String phone;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController();
  late final _phone = TextEditingController(
    text: widget.phone.replaceFirst('+243', '').trim(),
  );
  String _method = kPayoutMethods.first;

  bool get _needsPhone => _method != 'Espèces';

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    super.dispose();
  }

  double? get _parsedAmount =>
      double.tryParse(_amount.text.replaceAll(',', '.').trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(payoutControllerProvider.notifier)
        .request(
          amount: _parsedAmount!,
          method: _method,
          phone: _needsPhone ? normalizeCongoPhone(_phone.text) : null,
        );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(payoutControllerProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Sizes.screenPadding,
            0,
            Sizes.screenPadding,
            Sizes.p20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Retirer mes gains', style: theme.textTheme.titleLarge),
                gapH4,
                Text(
                  'Solde disponible : '
                  '${CurrencyFormatter.formatUsd(widget.balance)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                gapH24,
                AppTextField(
                  label: 'Montant (USD)',
                  controller: _amount,
                  hintText: 'Minimum ${kMinPayout.toStringAsFixed(0)} USD',
                  prefixIcon: AppIcons.coins,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  suffix: TextButton(
                    onPressed: () => setState(
                      () => _amount.text = widget.balance.toStringAsFixed(2),
                    ),
                    child: const Text('Tout'),
                  ),
                  validator: (_) {
                    final amount = _parsedAmount;
                    if (amount == null || amount <= 0) {
                      return 'Indiquez un montant';
                    }
                    if (amount < kMinPayout) {
                      return 'Minimum ${kMinPayout.toStringAsFixed(0)} USD';
                    }
                    if (amount > widget.balance) {
                      return 'Supérieur à votre solde';
                    }
                    return null;
                  },
                ),
                gapH20,
                Text('Recevoir par', style: theme.textTheme.titleSmall),
                gapH8,
                Wrap(
                  spacing: Sizes.p8,
                  runSpacing: Sizes.p8,
                  children: [
                    for (final method in kPayoutMethods)
                      _MethodChip(
                        label: method,
                        selected: method == _method,
                        onTap: () => setState(() => _method = method),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: Motion.fast,
                  child: _needsPhone
                      ? Padding(
                          padding: const EdgeInsets.only(top: Sizes.p20),
                          child: AppTextField(
                            label: 'Numéro $_method',
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            prefix: const PhonePrefix(),
                            validator: (value) =>
                                normalizeCongoPhone(value ?? '') == null
                                ? 'Numéro invalide'
                                : null,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                gapH20,
                Container(
                  padding: const EdgeInsets.all(Sizes.p12),
                  decoration: BoxDecoration(
                    color: context.palette.infoSoft,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppIcon(
                        AppIcons.info,
                        size: 18,
                        color: AppColors.info,
                      ),
                      gapW8,
                      Expanded(
                        child: Text(
                          "Le montant est réservé tout de suite. L'administration "
                          'vérifie la demande puis vous paie ; en cas de refus, '
                          'il revient sur votre solde.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.hasError) ...[
                  gapH12,
                  Text(
                    '${state.error}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                gapH20,
                AppButton(
                  label: 'Demander le retrait',
                  icon: AppIcons.wallet,
                  loading: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? context.palette.primarySoft
              : context.palette.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: selected ? context.palette.primary : context.palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected
                ? context.palette.primary
                : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
