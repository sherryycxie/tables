# Tables

A mobile app designed as a **backlog for IRL conversations** — helping friends save and organize meaningful discussion topics to talk about when they're together.

## Overview

Tables solves a common problem: you think of something interesting to discuss with a friend, but when you finally meet up, you've forgotten what it was. Tables lets you:

- **Save topics** you want to discuss with specific friends
- **Organize ideas** with context and supporting cards
- **Share tables** with friends before you meet
- **Get reminders** so you never forget important conversations

## Features

### Core Functionality
- **Tables** — Create discussion topic collections for specific friends
- **Cards** — Add individual discussion points within tables
- **Comments** — Have threaded discussions on cards
- **Sharing** — Invite friends via email to collaborate on tables

### Organization
- **Friend-centric view** — Filter and group tables by friend
- **Status tracking** — Mark topics as active, archived, or discussed
- **Search** — Find tables across your entire collection

### Notifications
- **Scheduled reminders** — Set date/time reminders for tables
- **Custom messages** — Add context to your reminders
- **Deep linking** — Tap notifications to jump directly to tables

### Real-time Sync
- **Live updates** — See changes from friends instantly
- **Multi-device** — Your tables sync across devices
- **Collaborative** — Multiple friends can add cards and comments

## Tech Stack

| Category | Technology |
|----------|------------|
| **Language** | Swift 5 |
| **UI Framework** | SwiftUI |
| **Local Storage** | SwiftData |
| **Backend** | Supabase (PostgreSQL + Auth) |
| **Real-time** | Supabase Realtime (WebSocket) |
| **Notifications** | UserNotifications framework |

### Platform Support
- iOS 26.2+
- macOS 26.1+
- visionOS (experimental)

## Project Structure

```
tables/
├── tablesApp.swift          # App entry point
├── AppDelegate.swift         # iOS lifecycle management
├── NotificationManager.swift # Push notification handling
├── Models/                   # SwiftData models
│   ├── TableModel.swift
│   ├── CardModel.swift
│   ├── CommentModel.swift
│   └── NudgeModel.swift
├── Views/                    # SwiftUI views
│   ├── SupabaseHomeView.swift
│   ├── SupabaseTableDetailView.swift
│   ├── SupabaseCardDetailView.swift
│   ├── SupabaseCreateTableView.swift
│   ├── SupabaseShareView.swift
│   └── AuthView.swift
├── Components/               # Reusable UI components
│   ├── PrimaryButton.swift
│   ├── TableRowView.swift
│   ├── CardCellView.swift
│   └── FriendAvatarView.swift
├── Supabase/                 # Backend integration
│   ├── SupabaseManager.swift # Main orchestrator
│   ├── SupabaseModels.swift  # Data DTOs
│   └── Supabase+Config.swift # Configuration
└── DesignSystem/             # Shared styling
    └── DesignSystem.swift
```

## Getting Started

### Prerequisites
- Xcode 16+
- iOS 26.2+ device or simulator
- Supabase account (for backend)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/tables.git
   cd tables
   ```

2. **Configure Supabase**

   Create a Supabase project and update `tables/Supabase/Supabase+Config.swift`:
   ```swift
   static let projectURL = URL(string: "YOUR_SUPABASE_URL")!
   static let anonKey = "YOUR_ANON_KEY"
   ```

3. **Run database migrations**

   Execute the SQL files in order:
   - `database/setup/01_rls_policies.sql` — Row-level security
   - `database/setup/02_functions.sql` — Database functions
   - `database/realtime/enable_tables.sql` — Realtime subscriptions

4. **Open in Xcode**
   ```bash
   open tables.xcodeproj
   ```

5. **Build and run**

   Select your target device and press `Cmd + R`

## Architecture

### Design Patterns
- **MVVM** — SupabaseManager serves as the ViewModel
- **Singleton** — NotificationManager and SupabaseManager
- **Repository** — SupabaseManager abstracts database operations
- **Async/Await** — Modern Swift concurrency throughout

### State Management
- `@State` for local view state
- `@EnvironmentObject` for global SupabaseManager
- `@Published` properties for reactive updates

### Security
- Row-Level Security (RLS) policies
- JWT-based authentication
- Automatic token refresh

## Database Schema

| Table | Description |
|-------|-------------|
| `tables` | Discussion topic containers |
| `cards` | Individual discussion points |
| `comments` | Card discussion threads |
| `nudges` | Reminders |
| `table_shares` | Sharing permissions |
| `profiles` | User profiles |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Acknowledgments

- Built with [Supabase](https://supabase.com) for backend services
- UI designed with SwiftUI and custom 3D effects
