/// Represents a game supported on the TourneyZone platform.
class SupportedGame {
  final String id;
  final String name;
  final String category;
  final String uidLabel;
  final String placeholderUid;

  const SupportedGame({
    required this.id,
    required this.name,
    required this.category,
    this.uidLabel = 'In-Game UID / Character ID',
    this.placeholderUid = 'e.g. 5123456789',
  });
}

/// Centralized repository of supported games.
/// Can be extended or loaded dynamically from Firestore in future phases.
class SupportedGamesConfig {
  SupportedGamesConfig._();

  static const List<SupportedGame> games = [
    SupportedGame(
      id: 'bgmi',
      name: 'Battlegrounds Mobile India (BGMI)',
      category: 'Battle Royale',
      uidLabel: 'Character ID (10-11 digits)',
      placeholderUid: 'e.g. 5123456789',
    ),
    SupportedGame(
      id: 'freefire',
      name: 'Free Fire MAX',
      category: 'Battle Royale',
      uidLabel: 'Player UID (8-10 digits)',
      placeholderUid: 'e.g. 192837465',
    ),
    SupportedGame(
      id: 'codm',
      name: 'Call of Duty: Mobile (CODM)',
      category: 'Shooter / BR',
      uidLabel: 'Player UID / OpenID',
      placeholderUid: 'e.g. 6748392019485',
    ),
    SupportedGame(
      id: 'valorant',
      name: 'Valorant',
      category: 'Tactical FPS',
      uidLabel: 'Riot ID & Tag',
      placeholderUid: 'e.g. Player#IND',
    ),
    SupportedGame(
      id: 'pokemon_unite',
      name: 'Pokémon UNITE',
      category: 'MOBA',
      uidLabel: 'Trainer ID',
      placeholderUid: 'e.g. 7X9K2PL',
    ),
    SupportedGame(
      id: 'cs2',
      name: 'Counter-Strike 2',
      category: 'Tactical FPS',
      uidLabel: 'SteamID64',
      placeholderUid: 'e.g. 76561198000000000',
    ),
  ];

  static SupportedGame? findById(String id) {
    try {
      return games.firstWhere((game) => game.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<String> get gameNames => games.map((g) => g.name).toList();
}

