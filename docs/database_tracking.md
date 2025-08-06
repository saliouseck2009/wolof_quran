# SQLite Database Download Tracking

This implementation provides persistent tracking of downloaded Quran surahs using SQLite database.

## Components

### 1. Database Layer

#### `DownloadedSurah` Model (`/data/models/downloaded_surah.dart`)
- Represents a downloaded surah record
- Fields: id, reciterId, surahNumber, filePath, isComplete

#### `DatabaseHelper` (`/data/datasources/database_helper.dart`)
- Manages SQLite database operations
- Creates tables, handles CRUD operations
- Provides download statistics

#### `DownloadRepository` (`/domain/repositories/download_repository.dart`)
- Abstract interface for download operations
- Defines contract for tracking downloads

#### `DownloadRepositoryImpl` (`/data/repositories/download_repository_impl.dart`)
- Concrete implementation of DownloadRepository
- Uses DatabaseHelper for actual database operations

### 2. Use Cases (`/domain/usecases/download_management_usecases.dart`)
- `CheckSurahDownloadStatusUseCase`: Check if surah is downloaded
- `MarkSurahDownloadedUseCase`: Mark surah as downloaded
- `RemoveSurahDownloadUseCase`: Remove download record

### 3. Integration

#### `AudioManagementCubit` Updates
- Now uses DownloadRepository for checking download status
- Automatically marks downloads in database
- Removes records on download failure

#### UI Components
- `DownloadStatusIndicator`: Reusable widget for showing download status
- `DownloadStatusIcon`: Simple icon indicator for downloaded surahs

## Usage

### Check Download Status
```dart
final isDownloaded = await locator<DownloadRepository>()
    .isSurahDownloaded(reciterId, surahNumber);
```

### Mark as Downloaded
```dart
await locator<DownloadRepository>()
    .markSurahAsDownloaded(reciterId, surahNumber, filePath);
```

### Using UI Components
```dart
DownloadStatusIndicator(
  reciterId: reciter.id,
  surahNumber: surahNumber,
  builder: (isDownloaded) => Icon(
    isDownloaded ? Icons.check : Icons.download,
  ),
)
```

## Benefits

1. **Persistent Storage**: Download status survives app restarts
2. **Reliability**: SQLite provides ACID transactions
3. **Performance**: Fast local queries
4. **Scalability**: Can handle large datasets efficiently
5. **Consistency**: Single source of truth for download status

## Database Schema

```sql
CREATE TABLE downloaded_surahs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reciter_id TEXT NOT NULL,
  surah_number INTEGER NOT NULL,
  file_path TEXT NOT NULL,
  is_complete INTEGER NOT NULL DEFAULT 0,
  downloaded_at INTEGER NOT NULL,
  UNIQUE(reciter_id, surah_number)
);
```

## Future Enhancements

- Add download size tracking
- Implement download history
- Add last played timestamp
- Support for partial downloads
- Batch operations for multiple surahs
