import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Données d'une icône Hugeicons (tracés SVG).
typedef AppIconData = List<List<dynamic>>;

/// Icône Hugeicons, utilisée comme un [Icon] : taille et couleur viennent
/// de l'[IconTheme] ambiant si elles ne sont pas données (ex. dans un
/// bouton).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
  });

  final AppIconData icon;
  final double? size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return HugeIcon(
      icon: icon,
      size: size ?? theme.size ?? 24,
      color: color ?? theme.color,
      strokeWidth: strokeWidth,
    );
  }
}

/// Catalogue des icônes de l'application : un nom métier par icône, pour
/// garder le même dessin partout.
abstract final class AppIcons {
  // ---- Navigation ----
  static const home = HugeIcons.strokeRoundedHome05;
  static const map = HugeIcons.strokeRoundedMaps;
  static const requests = HugeIcons.strokeRoundedMotorbike02;
  static const wallet = HugeIcons.strokeRoundedWallet03;
  static const profile = HugeIcons.strokeRoundedUserCircle;

  // ---- Métier ----
  static const moto = HugeIcons.strokeRoundedMotorbike02;
  static const store = HugeIcons.strokeRoundedStore04;
  static const flag = HugeIcons.strokeRoundedFlag02;
  static const package = HugeIcons.strokeRoundedPackage;
  static const delivered = HugeIcons.strokeRoundedPackageDelivered;
  static const route = HugeIcons.strokeRoundedRoute03;
  static const clock = HugeIcons.strokeRoundedClock01;
  static const timer = HugeIcons.strokeRoundedTimer02;
  static const flash = HugeIcons.strokeRoundedFlash;
  static const star = HugeIcons.strokeRoundedStar;
  static const coins = HugeIcons.strokeRoundedCoins01;
  static const invoice = HugeIcons.strokeRoundedInvoice01;
  static const radar = HugeIcons.strokeRoundedRadar02;
  static const pause = HugeIcons.strokeRoundedPauseCircle;
  static const bell = HugeIcons.strokeRoundedNotification03;
  static const trendUp = HugeIcons.strokeRoundedChartIncrease;
  static const trendDown = HugeIcons.strokeRoundedChartDecrease;
  static const verified = HugeIcons.strokeRoundedCheckmarkBadge01;
  static const hourglass = HugeIcons.strokeRoundedHourglass;
  static const idCard = HugeIcons.strokeRoundedIdentityCard;
  static const hash = HugeIcons.strokeRoundedHash;
  static const plate = HugeIcons.strokeRoundedPinLocation03;
  static const palette = HugeIcons.strokeRoundedPaintBoard;
  static const calendar = HugeIcons.strokeRoundedCalendar03;
  static const phone = HugeIcons.strokeRoundedSmartPhone01;
  static const call = HugeIcons.strokeRoundedCall02;
  static const camera = HugeIcons.strokeRoundedCamera01;
  static const gallery = HugeIcons.strokeRoundedImage02;
  static const cartRemove = HugeIcons.strokeRoundedShoppingCartRemove01;
  static const test = HugeIcons.strokeRoundedTestTube01;

  // ---- Carte ----
  static const navigation = HugeIcons.strokeRoundedNavigation03;
  static const nearMe = HugeIcons.strokeRoundedNavigator01;
  static const myLocation = HugeIcons.strokeRoundedGps01;
  static const layers = HugeIcons.strokeRoundedLayers01;
  static const fitAll = HugeIcons.strokeRoundedZoomOutArea;
  static const locationOff = HugeIcons.strokeRoundedLocationOffline02;
  static const turnLeft = HugeIcons.strokeRoundedDirectionLeft01;
  static const turnRight = HugeIcons.strokeRoundedDirectionRight01;
  static const slightLeft = HugeIcons.strokeRoundedCurvyLeftDirection;
  static const slightRight = HugeIcons.strokeRoundedCurvyRightDirection;
  static const uTurn = HugeIcons.strokeRoundedArrowTurnBackward;
  static const roundabout = HugeIcons.strokeRoundedArrowAllDirection;
  static const straight = HugeIcons.strokeRoundedArrowUp01;
  static const play = HugeIcons.strokeRoundedPlay;
  static const stop = HugeIcons.strokeRoundedStop;

  // ---- Actions et états ----
  static const check = HugeIcons.strokeRoundedTick02;
  static const checkCircle = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const decline = HugeIcons.strokeRoundedCancelCircle;
  static const back = HugeIcons.strokeRoundedArrowLeft01;
  static const forward = HugeIcons.strokeRoundedArrowRight02;
  static const chevronDown = HugeIcons.strokeRoundedArrowDown01;
  static const arrowUpRight = HugeIcons.strokeRoundedArrowMoveUpRight;
  static const refresh = HugeIcons.strokeRoundedRefresh;
  static const add = HugeIcons.strokeRoundedAddCircle;
  static const lock = HugeIcons.strokeRoundedSquareLock02;
  static const eye = HugeIcons.strokeRoundedView;
  static const eyeOff = HugeIcons.strokeRoundedViewOffSlash;
  static const logout = HugeIcons.strokeRoundedLogout03;
  static const info = HugeIcons.strokeRoundedInformationCircle;
  static const alert = HugeIcons.strokeRoundedAlert02;
  static const settings = HugeIcons.strokeRoundedSettings02;
  static const help = HugeIcons.strokeRoundedHelpCircle;
  static const block = HugeIcons.strokeRoundedUserBlock01;
  static const userOff = HugeIcons.strokeRoundedUserBlock01;
  static const offline = HugeIcons.strokeRoundedWifiDisconnected02;
  static const searchOff = HugeIcons.strokeRoundedSearchRemove;
}
