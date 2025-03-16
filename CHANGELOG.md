# Changelog

## [1.1.0] - 2025-03-16

### Added

- Thread safety with concurrent dispatch queue to prevent race conditions
- Persistent event queue system for reliable event tracking
- Automatic retry mechanism with exponential backoff for failed network requests
- App lifecycle integration to process queued events when app becomes active
- Public utility methods for queue management and debugging
- Added `retryQueuedEvents()` method to manually retry sending any queued events
- Added `getQueuedEventCount()` method to get the number of events currently in the queue
- Added `clearEventQueue()` method to clear all queued events (use with caution)

### Changed

- Improved attribution data persistence and initialization
- Enhanced StoreKit integration with better error handling
- More consistent use of configuration constants

### Fixed

- Fixed potential memory leaks in completion handlers
- Resolved issues with attribution data not being properly initialized
- Improved error handling and reporting

## [1.0.6] - 2024-XX-XX

### Changed

- Simplified SDK to use direct StoreKit integration
- Added web-based subscription tracking
- Improved deep linking with App Store ID
- Streamlined network service with app ID support
- Removed unused tracking features

### Fixed

- Improved attribution tracking
- Better error handling
- Cleaner initialization process
