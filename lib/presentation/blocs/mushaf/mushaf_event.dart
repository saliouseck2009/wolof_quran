import 'package:equatable/equatable.dart';

sealed class MushafEvent extends Equatable {
  const MushafEvent();

  @override
  List<Object?> get props => [];
}

class MushafLoaded extends MushafEvent {
  const MushafLoaded();
}

class MushafPageChanged extends MushafEvent {
  final int page;

  const MushafPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class MushafNavigateToSurah extends MushafEvent {
  final int surahNumber;

  const MushafNavigateToSurah(this.surahNumber);

  @override
  List<Object?> get props => [surahNumber];
}

class MushafNavigateToPage extends MushafEvent {
  final int page;

  const MushafNavigateToPage(this.page);

  @override
  List<Object?> get props => [page];
}

class MushafThemeChanged extends MushafEvent {
  final int themeIndex;

  const MushafThemeChanged(this.themeIndex);

  @override
  List<Object?> get props => [themeIndex];
}
