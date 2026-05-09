import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:work_timer/bloc/timer_cubit.dart';
import 'package:work_timer/models/work_mode.dart';
import 'package:work_timer/services/local_cache_store.dart';
import 'package:work_timer/services/work_repository.dart';

import 'support/work_repository_test_doubles.dart';

void main() {
  const uid = 'timer-cubit-user';

  Future<void> markMigrationDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('migration_done_v1_$uid', true);
  }

  Future<(WorkRepository, FakeWorkRemoteStore)> makeRepo() async {
    SharedPreferences.setMockInitialValues({});
    await markMigrationDone();
    final cache = LocalCacheStore();
    final remote = FakeWorkRemoteStore();
    final online = FixedOnlineChecker(true);
    final repo = WorkRepository(
      localCache: cache,
      remoteStore: remote,
      onlineChecker: online,
    );
    return (repo, remote);
  }

  test('TimerCubit: init → idle, play → running, stop → idle i zapis wpisu', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final (repo, remote) = await makeRepo();
    await repo.initForUser(uid);

    final cubit = TimerCubit(uid: uid, repository: repo);
    await cubit.init();

    expect(cubit.state.runState, TimerRunState.idle);

    cubit.play();
    expect(cubit.state.runState, TimerRunState.running);

    await Future<void>.delayed(const Duration(milliseconds: 120));
    await cubit.stop();

    expect(cubit.state.runState, TimerRunState.idle);
    expect(cubit.state.elapsed, Duration.zero);

    expect(remote.upsertedEntries, isNotEmpty);

    await cubit.close();
  });

  test('TimerCubit: play → pause zatrzymuje running', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final (repo, _) = await makeRepo();
    await repo.initForUser(uid);

    final cubit = TimerCubit(uid: uid, repository: repo);
    await cubit.init();

    cubit.play();
    expect(cubit.state.runState, TimerRunState.running);

    cubit.pause();
    expect(cubit.state.runState, TimerRunState.paused);

    await cubit.close();
  });

  test('TimerCubit: setNextMode nie zmienia trybu podczas sesji', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final (repo, _) = await makeRepo();
    await repo.initForUser(uid);

    final cubit = TimerCubit(uid: uid, repository: repo);
    await cubit.init();

    final before = cubit.state.nextSessionMode;
    cubit.play();
    cubit.setNextMode(
      before == WorkMode.office ? WorkMode.remote : WorkMode.office,
    );
    expect(cubit.state.nextSessionMode, before);

    await cubit.close();
  });
}
