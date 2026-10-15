/// Style de carte clair et lisible : fond gris très doux, rues blanches
/// cernées de gris-bleu, eau turquoise, parcs verts. Les noms de rues,
/// quartiers et communes restent affichés (c'est le but), seuls les
/// commerces et les transports sont masqués pour ne pas surcharger.
const kKinshasaMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f4f3f6"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"},{"weight":3}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#cfd6e0"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#374151"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#4b5563"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#eceaef"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#f1f0f3"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#cdeedb"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"visibility":"on"},{"color":"#4f8a6b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d3dae4"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#f7f9fc"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#e6ebf2"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#c9d2de"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#8fd8ee"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4a8fa8"}]}
]
''';
