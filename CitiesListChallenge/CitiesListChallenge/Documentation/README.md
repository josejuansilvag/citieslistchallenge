# Cities List Challenge - iOS App

## Overview

This iOS application demonstrates a production-level implementation for displaying and searching through a large dataset of cities (~200k entries). The app features efficient search capabilities, responsive UI, and follows modern iOS development practices using SwiftUI and SwiftData.

## Requirements Compliance

### ✅ Core Requirements Met

- **Data Download**: Downloads city data from the specified gist URL
- **Search Functionality**: Implements prefix-based search with case-insensitive matching
- **Performance**: Optimized for fast searches with debounced input
- **UI Responsiveness**: Updates list with every character change
- **Alphabetical Ordering**: Cities displayed as "City, Country" in alphabetical order
- **Favorites Filter**: Toggle to show only favorite cities
- **City Details**: Each cell shows city name, country, coordinates, and favorite toggle
- **Navigation**: Tap to navigate to map view with city coordinates
- **Information Screen**: Detailed city information screen
- **Dynamic UI**: Portrait (separate screens) vs Landscape (single screen) layouts
- **Persistence**: Favorites remembered between app launches
- **Testing**: Comprehensive unit tests for search algorithm and UI components

### ✅ Technical Requirements Met

- **SwiftUI**: All views built with SwiftUI
- **Latest iOS**: Compatible with latest iOS version
- **SwiftData**: Uses SwiftData for persistence
- **No 3rd Party Libraries**: Pure iOS implementation
- **Swift Version**: Compatible with latest Swift

## Architecture Overview

The app follows a **Clean Architecture** approach with **MVVM** pattern, implementing **SOLID principles** and **Dependency Injection**.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
├─────────────────────────────────────────────────────────────┤
│  Views (SwiftUI)          │  ViewModels (MVVM)              │
│  ├─ CityListView         │  ├─ CityListViewModel           │
│  ├─ CityDetailView       │  ├─ CityDetailViewModel         │
│  ├─ LandscapeView        │  └─ Coordinator                 │
│  └─ MapView              │                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                    │
├─────────────────────────────────────────────────────────────┤
│  DataStore (Use Cases)    │  Services                      │
│  ├─ Search Cities         │  ├─ NetworkService             │
│  ├─ Toggle Favorites      │  └─ Repository                 │
│  └─ Data Preparation      │                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
├─────────────────────────────────────────────────────────────┤
│  Repository               │  Data Sources                   │
│  ├─ CityRepository        │  ├─ SwiftData (Local)          │
│  └─ Protocols             │  └─ Network (Remote)           │
└─────────────────────────────────────────────────────────────┘
```

### Component Interaction Flow

1. **User Input** → View → ViewModel → DataStore → Repository → SwiftData
2. **Data Changes** → SwiftData → Repository → DataStore → ViewModel → View
3. **Navigation** → Coordinator → View Creation → Navigation Stack

## Key Architectural Decisions

### 1. Dependency Injection Container

The app uses a centralized `DIContainer` that manages all dependencies:

```swift
@MainActor
final class DIContainer: DIContainerProtocol {
    private let modelContainer: ModelContainer
    private let useMockData: Bool
    
    // Services are lazily initialized
    private lazy var networkService: NetworkServiceProtocol = { ... }()
    private lazy var cityRepository: CityRepositoryProtocol = { ... }()
    private lazy var dataStore: DataStoreProtocol = { ... }()
}
```

**Benefits:**
- **Testability**: Easy to inject mocks for testing
- **Single Responsibility**: Each service has a clear purpose
- **Loose Coupling**: Components depend on protocols, not concrete implementations

### 2. Repository Pattern

The `CityRepository` abstracts data access:

```swift
@MainActor
final class CityRepository: CityRepositoryProtocol {
    private let modelContext: ModelContext
    
    func fetchCities(matching prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> SearchResult
    func toggleFavorite(forCityID cityID: Int) async
    func saveCitiesFromJSON(_ cityJSONs: [CityJSON]) async
}
```

**Benefits:**
- **Data Abstraction**: UI doesn't know about SwiftData implementation
- **Testability**: Can easily mock repository for testing
- **Flexibility**: Can change data source without affecting UI

### 3. Coordinator Pattern

The `MainCoordinator` handles navigation logic:

```swift
@MainActor
final class MainCoordinator: ObservableCoordinatorProtocol, ViewModelFactory {
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: FullScreenRoute?
}
```

**Benefits:**
- **Separation of Concerns**: Views don't handle navigation logic
- **Reusability**: Same coordinator can be used across different views
- **Testability**: Navigation can be tested independently

## Search Implementation

### Why This Approach?

The search implementation uses **database-level prefix matching** with SwiftData, which provides several advantages over in-memory filtering:

#### 1. **Performance Benefits**
- **Database Indexing**: Uses SwiftData's built-in indexing on `displayName_lowercased`
- **Efficient Queries**: Leverages SQLite's B-tree indexing for O(log n) search complexity
- **Memory Efficiency**: Only loads matching results, not entire dataset

#### 2. **Implementation Details**

```swift
// Indexed field for efficient prefix searches
@Index([
    \City.displayName_lowercased,
    \City.isFavorite
])
@Attribute(.unique) var id: Int
var displayName_lowercased: String  // Pre-computed for performance
```

#### 3. **Search Algorithm**

```swift
let trimmedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
let lowerBound = trimmedPrefix
let upperBound = trimmedPrefix + "\u{FFFF}"

let predicate = #Predicate<City> {
    $0.displayName_lowercased >= lowerBound &&
    $0.displayName_lowercased < upperBound
}
```

**How it works:**
- Uses **range queries** with Unicode boundaries
- `\u{FFFF}` ensures we get all strings starting with the prefix
- Case-insensitive by using pre-lowercased field

#### 4. **Performance Comparison**

| Approach              | Memory Usage | Search Time | Scalability |
|-----------------------|--------------|-------------|-------------|
| **Database Indexing** | Low          | O(log n)    | Excellent   |
| In-Memory Filtering   | High         | O(n)        | Poor        |
| Linear Search         | Low          | O(n)        | Poor        |

### 5. **Debouncing for UI Responsiveness**

```swift
private func debounceSearch() {
    searchTask?.cancel()
    searchTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        if !Task.isCancelled {
            await MainActor.run {
                resetAndLoadFirstPage()
            }
        }
    }
}
```

**Benefits:**
- **Reduces Database Calls**: Only searches after user stops typing
- **Smooth UI**: Prevents excessive updates while typing
- **Battery Efficient**: Reduces unnecessary processing

## Data Management

### Download and Storage Strategy

#### 1. **Chunked Processing**

```swift
private let chunkSize = 2000
let chunks = cityJSONs.chunked(into: chunkSize)
for (index, chunk) in chunks.enumerated() {
    await self.repository.saveCitiesFromJSON(chunk)
}
```

**Why chunked processing?**
- **Memory Efficiency**: Prevents memory spikes with large datasets
- **Progress Tracking**: Can show progress for large downloads
- **Error Recovery**: If one chunk fails, others can still succeed

#### 2. **Persistence Strategy**

- **SwiftData**: Uses Apple's modern persistence framework
- **Indexed Fields**: Optimized for search performance
- **Lazy Loading**: Only loads visible data with pagination

#### 3. **Data Flow**

```
Network → JSON → CityJSON → City Model → SwiftData → UI
```

### Pagination Implementation

```swift
private let pageSize = 50
private var currentPage = 0

func loadNextPage() async {
    let result = await dataStore.searchCities(
        prefix: searchText,
        onlyFavorites: showOnlyFavorites,
        page: currentPage,
        pageSize: pageSize
    )
}
```

**Benefits:**
- **Memory Efficient**: Only loads visible data
- **Smooth Scrolling**: No performance issues with large lists
- **Incremental Loading**: Loads more data as user scrolls

## SOLID Principles Implementation

### 1. **Single Responsibility Principle (SRP)**
- `CityRepository`: Only handles data access
- `NetworkService`: Only handles network requests
- `DataStore`: Only handles business logic
- `CityListViewModel`: Only handles UI state

### 2. **Open/Closed Principle (OCP)**
- All services use protocols, allowing extension without modification
- New features can be added by implementing new protocols

### 3. **Liskov Substitution Principle (LSP)**
- Mock implementations can substitute real implementations
- All protocol implementations are interchangeable

### 4. **Interface Segregation Principle (ISP)**
- Protocols are specific to their use cases
- `DataStoreProtocol` only exposes necessary methods
- `NetworkServiceProtocol` only exposes network methods

### 5. **Dependency Inversion Principle (DIP)**
- High-level modules depend on abstractions (protocols)
- Low-level modules implement these abstractions
- DIContainer manages all dependencies

## Scalability and Extensibility

### Current Architecture Benefits

1. **Feature Addition**: New features can be added by:
   - Creating new protocols
   - Implementing new services
   - Adding to DIContainer
   - Creating new ViewModels and Views

2. **Data Source Changes**: Can easily switch from SwiftData to Core Data or other storage

3. **UI Framework Changes**: Can adapt to different UI frameworks by changing only the presentation layer

### Example: Adding Weather Information

```swift
// 1. Add new protocol
protocol WeatherServiceProtocol {
    func getWeather(for city: City) async throws -> Weather
}

// 2. Implement service
final class WeatherService: WeatherServiceProtocol {
    func getWeather(for city: City) async throws -> Weather {
        // Implementation
    }
}

// 3. Add to DIContainer
private lazy var weatherService: WeatherServiceProtocol = {
    return WeatherService()
}()

// 4. Create ViewModel
final class WeatherViewModel: ObservableObject {
    private let weatherService: WeatherServiceProtocol
    // Implementation
}

// 5. Create View
struct WeatherView: View {
    @StateObject var viewModel: WeatherViewModel
    // Implementation
}
```

## Testing Strategy

### Unit Tests Coverage

1. **Search Logic Tests**: Comprehensive testing of prefix matching
2. **Repository Tests**: Data access layer testing
3. **ViewModel Tests**: Business logic testing
4. **UI Tests**: User interaction testing

### Test Examples

```swift
func testRepositoryFetchWithPrefix() async {
    // When: Searching cities starting with "A"
    let result = await repository.fetchCities(matching: "A", onlyFavorites: false, page: 0, pageSize: 10)
    
    // Then: Should return only cities with prefix "A"
    XCTAssertEqual(result.cities.count, 4)
    XCTAssertTrue(result.cities.allSatisfy { $0.name.hasPrefix("A") })
}
```

## Performance Optimizations

### 1. **Database Indexing**
- Indexed fields for fast searches
- Composite indexes for complex queries

### 2. **Lazy Loading**
- Pagination reduces memory usage
- Only loads visible data

### 3. **Debouncing**
- Reduces unnecessary API calls
- Improves UI responsiveness

### 4. **Chunked Processing**
- Prevents memory spikes
- Enables progress tracking

## Conclusion

This implementation demonstrates a production-ready iOS application that:

- ✅ **Meets all requirements** specified in the challenge
- ✅ **Follows clean architecture** principles
- ✅ **Implements SOLID principles** for maintainability
- ✅ **Uses dependency injection** for testability
- ✅ **Optimizes search performance** with database-level indexing
- ✅ **Provides responsive UI** with debouncing and pagination
- ✅ **Includes comprehensive testing** for reliability
- ✅ **Offers excellent scalability** for future enhancements

The architecture is designed to be maintainable, testable, and scalable, making it suitable for production environments while providing an excellent user experience.
