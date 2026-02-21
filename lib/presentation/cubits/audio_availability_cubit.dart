import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/audio_availability_snapshot.dart';
import '../../domain/usecases/get_cached_audio_availability_usecase.dart';
import '../../domain/usecases/mark_audio_updates_seen_usecase.dart';
import '../../domain/usecases/refresh_audio_availability_usecase.dart';

class AudioAvailabilityState extends Equatable {
  final Map<String, AudioAvailabilitySnapshot> snapshots;
  final Set<String> loadingReciters;
  final Map<String, String> errors;

  const AudioAvailabilityState({
    this.snapshots = const {},
    this.loadingReciters = const {},
    this.errors = const {},
  });

  AudioAvailabilityState copyWith({
    Map<String, AudioAvailabilitySnapshot>? snapshots,
    Set<String>? loadingReciters,
    Map<String, String>? errors,
  }) {
    return AudioAvailabilityState(
      snapshots: snapshots ?? this.snapshots,
      loadingReciters: loadingReciters ?? this.loadingReciters,
      errors: errors ?? this.errors,
    );
  }

  AudioAvailabilitySnapshot? snapshotForReciter(String reciterId) {
    return snapshots[reciterId];
  }

  int unreadCountForReciter(String reciterId) {
    return snapshots[reciterId]?.unreadNewSurahs.length ?? 0;
  }

  bool isSurahAvailable(String reciterId, int surahNumber) {
    final snapshot = snapshots[reciterId];
    if (snapshot == null) {
      // Do not block user action when availability has never been synced.
      return true;
    }
    return snapshot.availableSurahs.contains(surahNumber);
  }

  @override
  List<Object?> get props => [snapshots, loadingReciters, errors];
}

class AudioAvailabilityCubit extends Cubit<AudioAvailabilityState> {
  final RefreshAudioAvailabilityUseCase refreshAudioAvailabilityUseCase;
  final GetCachedAudioAvailabilityUseCase getCachedAudioAvailabilityUseCase;
  final MarkAudioUpdatesSeenUseCase markAudioUpdatesSeenUseCase;

  AudioAvailabilityCubit({
    required this.refreshAudioAvailabilityUseCase,
    required this.getCachedAudioAvailabilityUseCase,
    required this.markAudioUpdatesSeenUseCase,
  }) : super(const AudioAvailabilityState());

  Future<void> refreshReciter(
    String reciterId, {
    bool force = false,
    Duration ttl = const Duration(hours: 6),
  }) async {
    await _mergeCachedSnapshot(reciterId);

    final loadingReciters = Set<String>.from(state.loadingReciters)
      ..add(reciterId);
    final updatedErrors = Map<String, String>.from(state.errors)
      ..remove(reciterId);
    emit(
      state.copyWith(loadingReciters: loadingReciters, errors: updatedErrors),
    );

    try {
      final snapshot = await refreshAudioAvailabilityUseCase(
        params: RefreshAudioAvailabilityParams(
          reciterId: reciterId,
          force: force,
          ttl: ttl,
        ),
      );

      final snapshots = Map<String, AudioAvailabilitySnapshot>.from(
        state.snapshots,
      )..[reciterId] = snapshot;
      emit(state.copyWith(snapshots: snapshots));
    } catch (e) {
      final errors = Map<String, String>.from(state.errors)
        ..[reciterId] = e.toString();
      emit(state.copyWith(errors: errors));
    } finally {
      final reciters = Set<String>.from(state.loadingReciters)
        ..remove(reciterId);
      emit(state.copyWith(loadingReciters: reciters));
    }
  }

  Future<void> refreshReciters(
    List<String> reciterIds, {
    bool force = false,
    Duration ttl = const Duration(hours: 6),
  }) async {
    for (final reciterId in reciterIds.toSet()) {
      await refreshReciter(reciterId, force: force, ttl: ttl);
    }
  }

  Future<void> markAsSeen(String reciterId) async {
    try {
      final updatedSnapshot = await markAudioUpdatesSeenUseCase(
        params: reciterId,
      );
      if (updatedSnapshot == null) {
        return;
      }

      final snapshots = Map<String, AudioAvailabilitySnapshot>.from(
        state.snapshots,
      )..[reciterId] = updatedSnapshot;
      emit(state.copyWith(snapshots: snapshots));
    } catch (e) {
      final errors = Map<String, String>.from(state.errors)
        ..[reciterId] = e.toString();
      emit(state.copyWith(errors: errors));
    }
  }

  Future<void> _mergeCachedSnapshot(String reciterId) async {
    final cachedSnapshot = await getCachedAudioAvailabilityUseCase(
      params: reciterId,
    );
    if (cachedSnapshot == null) {
      return;
    }

    final snapshots = Map<String, AudioAvailabilitySnapshot>.from(
      state.snapshots,
    )..[reciterId] = cachedSnapshot;
    emit(state.copyWith(snapshots: snapshots));
  }
}
