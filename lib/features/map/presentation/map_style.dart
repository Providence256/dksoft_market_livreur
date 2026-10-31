/// Style de carte de l'app : fond gris-bleu très doux, rues blanches, grands
/// axes teintés d'orange (la couleur de la marque), eau bleu clair, parcs
/// verts. Noms de rues, quartiers et communes gardés ; commerces,
/// pictogrammes et transports masqués pour ne pas surcharger.
const kKinshasaMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f2f4f8"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#5b6474"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"},{"weight":4}]},

  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#c9d3e2"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#103166"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#3a4a66"}]},

  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#eceff5"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#edf3ec"}]},

  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#d4ecd6"}]},
  {"featureType":"poi.park","elementType":"labels.text","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#4c8a63"}]},

  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#dfe4ec"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#7a8494"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#5b6474"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#ffe2cf"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#f6c5a3"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#a24a12"}]},

  {"featureType":"transit","stylers":[{"visibility":"off"}]},

  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#b6dbf5"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4f86b0"}]}
]
''';

/// Version sombre : fond bleu nuit, rues gris ardoise, grands axes teintés
/// d'orange, noms en gris clair.
const kKinshasaMapStyleDark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#151c2a"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9aa5b8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0c111c"},{"weight":4}]},

  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#2b3548"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#dbe4f3"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#b4c0d4"}]},

  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#192131"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#172320"}]},

  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#1b3326"}]},
  {"featureType":"poi.park","elementType":"labels.text","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6fae86"}]},

  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2a3346"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1d2535"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8d98ab"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#323d53"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#5a3a26"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#3d2718"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f0b48a"}]},

  {"featureType":"transit","stylers":[{"visibility":"off"}]},

  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e2a40"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5c8db3"}]}
]
''';

/// Style de carte adapté au thème actif.
String mapStyleFor(bool dark) =>
    dark ? kKinshasaMapStyleDark : kKinshasaMapStyle;
