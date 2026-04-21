import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/services/feedback_sound_service.dart';

void main() {
  test('preload failures are swallowed', () async {
    final service = FeedbackSoundService(
      preloader: (_) async => throw StateError('Missing assets.'),
      executor: (_, _, _) async {},
    );

    await service.preload();
  });

  test('play failures are swallowed', () async {
    final service = FeedbackSoundService(
      preloader: (_) async {},
      executor: (_, _, _) async => throw StateError('Platform audio failed.'),
    );

    service.play(FeedbackSound.buttonTap);
    await Future<void>.delayed(Duration.zero);
  });

  test('sound ids resolve to bundled file names and volumes', () async {
    final played = <String>[];
    final service = FeedbackSoundService(
      preloader: (_) async {},
      executor: (sound, fileName, volume) async {
        played.add('${sound.name}:$fileName:${volume > 0}');
      },
    );

    service.play(FeedbackSound.taskComplete);
    await Future<void>.delayed(Duration.zero);

    expect(played, ['taskComplete:task_complete.wav:true']);
  });
}
