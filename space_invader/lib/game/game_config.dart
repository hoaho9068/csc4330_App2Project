class GameConfig {
  static const int rows = 5;
  static const int cols = 4;

  static const double invaderWidth = 24;
  static const double invaderHeight = 16;
  static const double invaderSpacing = 12;
  static const double arenaMargin = 16;
  static const double stepDown = 8;

  // The main invader formation trickles in over time rather than appearing
  // all at once; each new invader spawns after a random delay in this range.
  static const double gridSpawnMinInterval = 0.15;
  static const double gridSpawnMaxInterval = 0.45;

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

  // --- Diving invaders ---
  // These are bonus invaders that periodically spawn at the top of the
  // arena and fall straight down, disappearing once they pass the bottom
  // edge of the screen (whether or not the player shoots them first).
  static const double divingInvaderSpeed = 90;
  static const double divingInvaderMinInterval = 2.5;
  static const double divingInvaderMaxInterval = 5.5;
  static const int divingInvaderPoints = 50;

  // --- Wave progression ---
  // Waves are capped, not endless — clearing maxWave ends the game with the
  // existing "You Win!" screen instead of starting another wave.
  static const int maxWave = 5;

  static const double waveSpeedIncrement = 15.0;
  static const double invaderSpeedCap = 320.0;

  static const double waveFireIntervalScale = 0.88;
  static const double minInvaderFireInterval = 0.18;

  static const double waveDivingIntervalScale = 0.88;
  static const double minDivingInterval = 1.0;
  static const double waveDivingSpeedIncrement = 12.0;
  static const double divingInvaderSpeedCap = 180.0;
}
