class GameConfig {
  static const int rows = 5;
  static const int cols = 8;

  static const double invaderWidth = 24;
  static const double invaderHeight = 16;
  static const double invaderSpacing = 12;
  static const double arenaMargin = 16;
  static const double stepDown = 14;

  static const double baseInvaderSpeed = 40;
  static const double maxInvaderSpeed = 220;

  static const double playerWidth = 36;
  static const double playerHeight = 16;
  static const double playerBottomMargin = 40;
  static const double playerFireInterval = 0.35;

  static const double playerBulletSpeed = 480;
  static const double invaderBulletSpeed = 220;
  static const double bulletWidth = 3;
  static const double bulletHeight = 10;

  static const double invaderFireMinInterval = 0.4;
  static const double invaderFireMaxInterval = 1.6;

  static const int initialLives = 3;
  static const double maxDt = 0.05;
}
