import 'package:equatable/equatable.dart';

import '../../../core/mushaf/mushaf_theme.dart';
import '../../../core/mushaf/quran_page_data.dart';

class MushafState extends Equatable {
  final int currentPage;
  final PageInfo? pageInfo;
  final bool isLoading;
  final bool isTajweedEnabled;
  final MushafThemeData theme;
  final int? navigateToPage;

  MushafState({
    this.currentPage = 1,
    this.pageInfo,
    this.isLoading = true,
    this.isTajweedEnabled = false,
    this.navigateToPage,
    MushafThemeData? theme,
  }) : theme =
           theme ??
           MushafThemeData.fromIndex(MushafThemeData.defaultThemeIndex);

  MushafState copyWith({
    int? currentPage,
    PageInfo? pageInfo,
    bool? isLoading,
    bool? isTajweedEnabled,
    MushafThemeData? theme,
    int? Function()? navigateToPage,
  }) {
    return MushafState(
      currentPage: currentPage ?? this.currentPage,
      pageInfo: pageInfo ?? this.pageInfo,
      isLoading: isLoading ?? this.isLoading,
      isTajweedEnabled: isTajweedEnabled ?? this.isTajweedEnabled,
      theme: theme ?? this.theme,
      navigateToPage: navigateToPage != null
          ? navigateToPage()
          : this.navigateToPage,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    pageInfo,
    isLoading,
    isTajweedEnabled,
    theme,
    navigateToPage,
  ];
}
