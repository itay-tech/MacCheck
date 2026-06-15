# MacCheck

Mac health diagnostics app for macOS.

## History Data Source

MacCheck stores daily health snapshots locally. The repository can load either **real user data** or **bundled mock datasets** for development.

### Setting

In `MacCheck/Repositories/HistoryRepository.swift`:

```swift
static var dataSource: HistoryDataSource = .real
```

This is the single switch that controls where history is read from.

### Options

| Value | Loads from | Use for |
|-------|------------|---------|
| `.real` | App sandbox Application Support (`MacCheck/health_snapshots.json`) | Normal app use and production |
| `.mock2Days` | `history_2_days.json` | Quick UI checks with minimal history |
| `.mock7Days` | `history_7_days.json` | Trend and comparison testing |
| `.mock30Days` | `history_30_days.json` | Charts and medium-term history |
| `.mock90Days` | `history_90_days.json` | Predictions, statistics, long-term charts |

### Default: `.real`

Release builds always use `.real`. Mock sources are available in DEBUG builds only.

Keep this value for everyday development and release builds:

```swift
static var dataSource: HistoryDataSource = .real
```

With `.real`:

- History comes only from scans run on the current Mac
- New snapshots are saved after each successful dashboard scan
- History, Charts, Predictions, and Reports all reflect actual stored data

### Mock modes (development only)

To test features without waiting for real scan history, temporarily change the line to a mock value, for example:

```swift
static var dataSource: HistoryDataSource = .mock30Days
```

In mock mode (DEBUG builds only):

- `loadSnapshots()` reads JSON from bundled `MockData` files
- `saveSnapshots()` is disabled, so mock data is never written to disk
- The app behaves as if that mock history already exists

Release builds ignore mock settings and always load/save real local history.

Switch back to `.real` when finished testing.

### What this affects

`HistoryRepository.dataSource` flows into:

- `HistoryService` → History page, comparisons, statistics, recent snapshots
- `ChartsViewModel` → all chart datasets
- `PredictionsViewModel` → forecast cards and risk analysis
- `ReportsViewModel` → report cards built from the live health scan (reports themselves use `HealthReport`, not mock history directly)

### Mock file locations

`HistoryRepository` looks for mock JSON in this order:

1. App bundle: `MockData/history_*.json`
2. Project folder: `MockData/history_*.json` (useful when running from Xcode before bundling)

Test fixtures also exist under:

```
MacCheckTests/Fixtures/MockData/
```

Those files are for unit tests, not automatic app runtime loading.

### Recommendation

- **Production / App Store builds:** `.real` only (enforced in Release)
- **Local UI experiments:** mock values in DEBUG, then revert before committing
- **Never ship** a DEBUG build with `dataSource` set to mock for TestFlight; Release builds are protected automatically


# To Build For Production