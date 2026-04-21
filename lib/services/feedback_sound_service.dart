import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum FeedbackSound {
  buttonTap,
  potionFlask,
  potionDrink,
  taskComplete,
  taskCreate,
  characterInteract,
}

abstract class FeedbackSoundPlayer {
  Future<void> preload();

  void play(FeedbackSound sound);

  void dispose();
}

typedef FeedbackSoundPreloader = Future<void> Function(List<String> files);
typedef FeedbackSoundExecutor =
    Future<void> Function(FeedbackSound sound, String fileName, double volume);

class FeedbackSoundService implements FeedbackSoundPlayer {
  FeedbackSoundService({
    FeedbackSoundPreloader? preloader,
    FeedbackSoundExecutor? executor,
  }) : _preloader = preloader,
       _executor = executor;

  static const Map<FeedbackSound, String> _files = {
    FeedbackSound.buttonTap: 'button_tap.wav',
    FeedbackSound.potionFlask: 'potion_flask.wav',
    FeedbackSound.potionDrink: 'potion_drink.wav',
    FeedbackSound.taskComplete: 'task_complete.wav',
    FeedbackSound.taskCreate: 'task_create.wav',
    FeedbackSound.characterInteract: 'character_interact.wav',
  };

  static const Map<FeedbackSound, double> _volumes = {
    FeedbackSound.buttonTap: 0.32,
    FeedbackSound.potionFlask: 0.48,
    FeedbackSound.potionDrink: 0.54,
    FeedbackSound.taskComplete: 0.42,
    FeedbackSound.taskCreate: 0.34,
    FeedbackSound.characterInteract: 0.32,
  };

  final FeedbackSoundPreloader? _preloader;
  final FeedbackSoundExecutor? _executor;
  final AudioCache _cache = AudioCache(prefix: 'assets/sounds/');
  final Map<FeedbackSound, AudioPlayer> _players = {};
  Future<void>? _preloadFuture;

  @override
  Future<void> preload() {
    return _preloadFuture ??= _guarded(() {
      final fileNames = _files.values.toList(growable: false);
      final preloader = _preloader;
      if (preloader != null) {
        return preloader(fileNames);
      }
      return _cache.loadAll(fileNames);
    });
  }

  @override
  void play(FeedbackSound sound) {
    unawaited(
      _guarded(() async {
        await preload();
        final fileName = _files[sound];
        if (fileName == null) {
          return;
        }
        final executor = _executor;
        if (executor != null) {
          await executor(sound, fileName, _volumes[sound] ?? 0.4);
          return;
        }
        await _playWithAudioPlayer(sound, fileName, _volumes[sound] ?? 0.4);
      }),
    );
  }

  Future<void> _playWithAudioPlayer(
    FeedbackSound sound,
    String fileName,
    double volume,
  ) async {
    final player = _players.putIfAbsent(
      sound,
      () => AudioPlayer(playerId: 'feedback-${sound.name}'),
    );
    await player.stop();
    await player.play(
      AssetSource('sounds/$fileName'),
      volume: volume,
      mode: PlayerMode.lowLatency,
    );
  }

  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Feedback sound failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }
}

class NoOpFeedbackSoundPlayer implements FeedbackSoundPlayer {
  const NoOpFeedbackSoundPlayer();

  @override
  Future<void> preload() async {}

  @override
  void play(FeedbackSound sound) {}

  @override
  void dispose() {}
}
