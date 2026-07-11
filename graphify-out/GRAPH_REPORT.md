# Graph Report - .  (2026-06-27)

## Corpus Check
- 142 files · ~107,329 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1417 nodes · 1893 edges · 94 communities (88 shown, 6 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 59 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Animation & UI Controllers|Animation & UI Controllers]]
- [[_COMMUNITY_Spartan AI Chat Screen|Spartan AI Chat Screen]]
- [[_COMMUNITY_Settings Service|Settings Service]]
- [[_COMMUNITY_Workout Plan Models|Workout Plan Models]]
- [[_COMMUNITY_App Navigation Shell|App Navigation Shell]]
- [[_COMMUNITY_Package Dependencies|Package Dependencies]]
- [[_COMMUNITY_Workout Session Screen|Workout Session Screen]]
- [[_COMMUNITY_Region & PAX Data Models|Region & PAX Data Models]]
- [[_COMMUNITY_Q Builder Service|Q Builder Service]]
- [[_COMMUNITY_Workout History & Backblast|Workout History & Backblast]]
- [[_COMMUNITY_Brotherhood Screen|Brotherhood Screen]]
- [[_COMMUNITY_iOS URL Launcher Plugin|iOS URL Launcher Plugin]]
- [[_COMMUNITY_User Profile & App Roles|User Profile & App Roles]]
- [[_COMMUNITY_Workout History Model|Workout History Model]]
- [[_COMMUNITY_Theme & Color System|Theme & Color System]]
- [[_COMMUNITY_iOS Share Plugin|iOS Share Plugin]]
- [[_COMMUNITY_Auth & Welcome Screen|Auth & Welcome Screen]]
- [[_COMMUNITY_iOS Package Info Plugin|iOS Package Info Plugin]]
- [[_COMMUNITY_App Entry & Main|App Entry & Main]]
- [[_COMMUNITY_iOS Wakelock Plugin|iOS Wakelock Plugin]]
- [[_COMMUNITY_Exercise Model|Exercise Model]]
- [[_COMMUNITY_Timer State Model|Timer State Model]]
- [[_COMMUNITY_Auth Models|Auth Models]]
- [[_COMMUNITY_Home Screen|Home Screen]]
- [[_COMMUNITY_Q Source Guide Data|Q Source Guide Data]]
- [[_COMMUNITY_iOS Native Bridge|iOS Native Bridge]]
- [[_COMMUNITY_iOS Plugin Stub Headers|iOS Plugin Stub Headers]]
- [[_COMMUNITY_iOS Notifications Plugin|iOS Notifications Plugin]]
- [[_COMMUNITY_iOS TTS Plugin|iOS TTS Plugin]]
- [[_COMMUNITY_Region Service|Region Service]]
- [[_COMMUNITY_Workout Generator|Workout Generator]]
- [[_COMMUNITY_Q Source Screen|Q Source Screen]]
- [[_COMMUNITY_Current Workout Service|Current Workout Service]]
- [[_COMMUNITY_Timer Screen Components|Timer Screen Components]]
- [[_COMMUNITY_Settings Screen|Settings Screen]]
- [[_COMMUNITY_App Version Model|App Version Model]]
- [[_COMMUNITY_iOS App Icons|iOS App Icons]]
- [[_COMMUNITY_Auth Service|Auth Service]]
- [[_COMMUNITY_Heatmap Screen|Heatmap Screen]]
- [[_COMMUNITY_Custom Exercise Screen|Custom Exercise Screen]]
- [[_COMMUNITY_Q Builder Screen|Q Builder Screen]]
- [[_COMMUNITY_Local Login Screen|Local Login Screen]]
- [[_COMMUNITY_AI Model Integration|AI Model Integration]]
- [[_COMMUNITY_Exercise UI Widgets|Exercise UI Widgets]]
- [[_COMMUNITY_App Package Imports (History)|App Package Imports (History)]]
- [[_COMMUNITY_App Package Imports (Workout)|App Package Imports (Workout)]]
- [[_COMMUNITY_History Service|History Service]]
- [[_COMMUNITY_Screen State Classes|Screen State Classes]]
- [[_COMMUNITY_Exercise Service|Exercise Service]]
- [[_COMMUNITY_Notification Service|Notification Service]]
- [[_COMMUNITY_Exercise Library Screen|Exercise Library Screen]]
- [[_COMMUNITY_Custom Exercise State|Custom Exercise State]]
- [[_COMMUNITY_Package Imports (Models)|Package Imports (Models)]]
- [[_COMMUNITY_Exicon CSV Converter|Exicon CSV Converter]]
- [[_COMMUNITY_Achievement Service|Achievement Service]]
- [[_COMMUNITY_App Service Imports|App Service Imports]]
- [[_COMMUNITY_Backblast Formatter|Backblast Formatter]]
- [[_COMMUNITY_Flutter Material Imports|Flutter Material Imports]]
- [[_COMMUNITY_Screen Navigation|Screen Navigation]]
- [[_COMMUNITY_Q Builder RequestResult|Q Builder Request/Result]]
- [[_COMMUNITY_Service ChangeNotifiers|Service ChangeNotifiers]]
- [[_COMMUNITY_Achievements Screen|Achievements Screen]]
- [[_COMMUNITY_iOS Build Scripts|iOS Build Scripts]]
- [[_COMMUNITY_Android App Icons|Android App Icons]]
- [[_COMMUNITY_Intensity Badge Widget|Intensity Badge Widget]]
- [[_COMMUNITY_Category Chip Widget|Category Chip Widget]]
- [[_COMMUNITY_LLDB Debug Helpers|LLDB Debug Helpers]]
- [[_COMMUNITY_Android Plugin Registrant|Android Plugin Registrant]]
- [[_COMMUNITY_App Lock Service|App Lock Service]]
- [[_COMMUNITY_Core Package Imports|Core Package Imports]]
- [[_COMMUNITY_Sherpa Wizard Screen|Sherpa Wizard Screen]]
- [[_COMMUNITY_iOS Plugin Registrant|iOS Plugin Registrant]]
- [[_COMMUNITY_Auth Service Tests|Auth Service Tests]]
- [[_COMMUNITY_Android Main Activity|Android Main Activity]]
- [[_COMMUNITY_iOS Launch Images|iOS Launch Images]]
- [[_COMMUNITY_Flutter Export Environment|Flutter Export Environment]]
- [[_COMMUNITY_DevTools Config|DevTools Config]]
- [[_COMMUNITY_Misc Type Node|Misc Type Node]]
- [[_COMMUNITY_Launch Image README|Launch Image README]]
- [[_COMMUNITY_Screens Layer Doc|Screens Layer Doc]]

## God Nodes (most connected - your core abstractions)
1. `CurrentWorkoutService` - 19 edges
2. `f3_nation_app Package` - 16 edges
3. `App Icon 1024x1024 @1x` - 15 edges
4. `Flutter Logo Branding (Light Blue / Dark Blue, geometric chevron)` - 15 edges
5. `Digital Weinke App` - 13 edges
6. `_WorkoutScreenState` - 7 edges
7. `convert()` - 7 edges
8. `_TimerScreenState` - 6 edges
9. `App Launcher Icon (hdpi)` - 6 edges
10. `App Launcher Icon (mdpi)` - 6 edges

## Surprising Connections (you probably didn't know these)
- `Digital Weinke App` --references--> `f3_nation_app Package`  [INFERRED]
  README.md → pubspec.yaml
- `Workout Generator` --conceptually_related_to--> `uuid (Unique IDs)`  [INFERRED]
  README.md → pubspec.yaml
- `Live Phase Timer` --conceptually_related_to--> `wakelock_plus (Keep Screen On)`  [INFERRED]
  README.md → pubspec.yaml
- `Exicon Library` --conceptually_related_to--> `url_launcher (Open Exicon Links)`  [INFERRED]
  README.md → pubspec.yaml
- `Workout History` --conceptually_related_to--> `shared_preferences (Local Storage)`  [INFERRED]
  README.md → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Offline / Local Storage Stack** — readme_offline_first, pubspec_shared_preferences, pubspec_uuid, readme_workout_history, readme_exercises_json [INFERRED 0.85]
- **Logic-UI Separation Architecture** — readme_logic_ui_separation, readme_models_layer, readme_services_layer, readme_screens_layer [EXTRACTED 1.00]
- **Beatdown Session Lifecycle Flow** — readme_q_workflow, readme_workout_generator, readme_live_phase_timer, readme_workout_history, readme_backblast_draft [EXTRACTED 1.00]

## Communities (94 total, 6 thin omitted)

### Community 0 - "Animation & UI Controllers"
Cohesion: 0.03
Nodes (76): Animation, AnimationController, ConfettiController, FlutterTts, int?, package:confetti/confetti.dart, package:flutter_tts/flutter_tts.dart, PageController? (+68 more)

### Community 1 - "Spartan AI Chat Screen"
Cohesion: 0.05
Nodes (39): build, createState, dispose, _initializeGreeting, _isLoading, _messages, _sendMessage, _spartan (+31 more)

### Community 2 - "Settings Service"
Cohesion: 0.05
Nodes (40): AppRole, _blacklist, _favorites, _geminiApiKey, isBlacklisted, isFavorited, _keyAppRole, _keyBlacklist (+32 more)

### Community 3 - "Workout Plan Models"
Cohesion: 0.05
Nodes (38): circuit,
  amrap,
  tabata,
  dora,, DateTime, exercise.dart, allExercises, blocks, category, copyWithExercises, durationMinutes (+30 more)

### Community 4 - "App Navigation Shell"
Cohesion: 0.05
Nodes (36): brotherhood_screen.dart, dart:async, home_screen.dart, library_screen.dart, ../models/timer_state.dart, TimerState, package:wakelock_plus/wakelock_plus.dart, build (+28 more)

### Community 5 - "Package Dependencies"
Cohesion: 0.07
Nodes (37): Flutter Lints Configuration, confetti (Session Completion Burst), f3_nation_app Package, flutter_lints (Dev Dependency), flutter_local_notifications (Push Notifications), flutter_tts (Voice Callouts), google_generative_ai (Spartan AI Assistant), http (HTTP Client for Slack) (+29 more)

### Community 6 - "Workout Session Screen"
Cohesion: 0.07
Nodes (32): _auditPlan, block, body, _BottomActions, color, createState, duration, _EmptyState (+24 more)

### Community 7 - "Region & PAX Data Models"
Cohesion: 0.06
Nodes (31): aoId, aoName, aos, AreaOfOperations, attendance, AttendanceRecord, birthday, date (+23 more)

### Community 8 - "Q Builder Service"
Cohesion: 0.06
Nodes (31): buildBeatdown, _couponModeFrom, difficultyScore, _duplicateExerciseNames, durationMinutes, equipment, focus, format (+23 more)

### Community 9 - "Workout History & Backblast"
Cohesion: 0.07
Nodes (30): HistoryService, package:share_plus/share_plus.dart, active, activeColor, _backblast, _confirmClear, _copied, _copy (+22 more)

### Community 10 - "Brotherhood Screen"
Cohesion: 0.08
Nodes (28): RegionService, action, BrotherhoodScreen, build, children, color, controller, _EmptyPanel (+20 more)

### Community 11 - "iOS URL Launcher Plugin"
Cohesion: 0.07
Nodes (27): authors, Flutter Dev Team, dependencies, Flutter, description, documentation_url, homepage, license (+19 more)

### Community 12 - "User Profile & App Roles"
Cohesion: 0.07
Nodes (26): AppRole get, pax,
  q,, _appLockEnabled, AppRole, _authUserId, completeWelcome, _displayName, _homeAo (+18 more)

### Community 13 - "Workout History Model"
Cohesion: 0.07
Nodes (26): ao, blocks, category, completed, copyWith, date, durationMinutes, exerciseNames (+18 more)

### Community 14 - "Theme & Color System"
Cohesion: 0.07
Nodes (26): static const Color, accent, accentDim, AppTheme, background, card, catBodyweight, catCoupon (+18 more)

### Community 15 - "iOS Share Plugin"
Cohesion: 0.08
Nodes (25): authors, Flutter Community Team, dependencies, Flutter, description, documentation_url, homepage, ios (+17 more)

### Community 16 - "Auth & Welcome Screen"
Cohesion: 0.09
Nodes (23): AppRole, AuthService, _appLockEnabled, build, _continue, createState, dispose, _homeAoCtrl (+15 more)

### Community 17 - "iOS Package Info Plugin"
Cohesion: 0.08
Nodes (23): authors, Flutter Community Team, dependencies, Flutter, description, documentation_url, homepage, license (+15 more)

### Community 18 - "App Entry & Main"
Cohesion: 0.09
Nodes (22): _AppEntry, _AppEntryState, appProfileService, authService, build, createState, DigitalWeinke, _entered (+14 more)

### Community 19 - "iOS Wakelock Plugin"
Cohesion: 0.09
Nodes (22): authors, Flutter Team, dependencies, Flutter, description, homepage, license, file (+14 more)

### Community 20 - "Exercise Model"
Cohesion: 0.09
Nodes (21): beginner,
  intermediate,, advanced, aliases, category, coupon, description, displayName, Equipment (+13 more)

### Community 21 - "Timer State Model"
Cohesion: 0.09
Nodes (21): disclaimer,
  warmup,
  thang,
  mary,, double get, BootcampPhase, copyWith, cot, currentPhase, durationSeconds, _fmt (+13 more)

### Community 22 - "Auth Models"
Cohesion: 0.09
Nodes (21): Exception, guest,
  slack,
  email,
  google,, apple, AppUser, AuthProvider, AuthUnavailableException, displayName, email (+13 more)

### Community 23 - "Home Screen"
Cohesion: 0.09
Nodes (21): history_screen.dart, Map, color, _CoreValues, counts, desc, _F, _formatDate (+13 more)

### Community 24 - "Q Source Guide Data"
Cohesion: 0.09
Nodes (21): allSections, backblastTemplate, cadenceAssistant, cotChecklist, detail, disclaimer, entries, label (+13 more)

### Community 25 - "iOS Native Bridge"
Cohesion: 0.10
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 26 - "iOS Plugin Stub Headers"
Cohesion: 0.10
Nodes (11): PodsDummy_flutter_local_notifications, PodsDummy_flutter_tts, PodsDummy_local_auth_darwin, NSObject, PodsDummy_package_info_plus, PodsDummy_Pods_Runner, PodsDummy_Pods_RunnerTests, PodsDummy_share_plus (+3 more)

### Community 27 - "iOS Notifications Plugin"
Cohesion: 0.10
Nodes (20): authors, Michael Bui, dependencies, Flutter, description, homepage, license, file (+12 more)

### Community 28 - "iOS TTS Plugin"
Cohesion: 0.10
Nodes (20): authors, eyedeadevelopment, dependencies, Flutter, description, homepage, license, file (+12 more)

### Community 29 - "Region Service"
Cohesion: 0.10
Nodes (19): addHardCommit, _aos, _attendance, _cleanNames, fngCount, _hardCommits, _key, load (+11 more)

### Community 30 - "Workout Generator"
Cohesion: 0.11
Nodes (18): dart:math, exercise_service.dart, WorkoutBlock, ../models/workout_settings.dart, Random, _buildBlock, _buildMurphThang, _filteredPool (+10 more)

### Community 31 - "Q Source Screen"
Cohesion: 0.11
Nodes (18): ../models/qsource_data.dart, QEntryStyle, QGuideEntry, QGuideSection, build, createState, entry, _EntryRow (+10 more)

### Community 32 - "Current Workout Service"
Cohesion: 0.11
Nodes (17): int get, WorkoutPlan, acceptDraftAsLive, clearDraft, clearLive, _currentExerciseIndex, _draftPlan, hasDraftPlan (+9 more)

### Community 33 - "Timer Screen Components"
Cohesion: 0.11
Nodes (18): _EmptyState, _ControlBar, _ControlButton, _COTCard, _DisclaimerCard, _EmptyState, _ExerciseDots, _IntervalPanel (+10 more)

### Community 34 - "Settings Screen"
Cohesion: 0.12
Nodes (16): IconData, build, icon, _InfoTile, label, options, _SectionHeader, _SegmentedRow (+8 more)

### Community 35 - "App Version Model"
Cohesion: 0.12
Nodes (16): List, AppRelease, AppVersion, bugFixes, buildNumber, current, displayName, enhancements (+8 more)

### Community 36 - "iOS App Icons"
Cohesion: 0.24
Nodes (16): Flutter Logo Branding (Light Blue / Dark Blue, geometric chevron), App Icon 1024x1024 @1x, App Icon 20x20 @1x, App Icon 20x20 @2x, App Icon 20x20 @3x, App Icon 29x29 @1x, App Icon 29x29 @2x, App Icon 29x29 @3x (+8 more)

### Community 37 - "Auth Service"
Cohesion: 0.12
Nodes (15): AppUser? get, ../models/auth_models.dart, package:uuid/uuid.dart, continueAsGuest, currentUser, isSignedIn, _keyCurrentUser, load (+7 more)

### Community 38 - "Heatmap Screen"
Cohesion: 0.12
Nodes (15): Color, build, color, _fullDate, _heatColor, HeatmapScreen, _HeatmapView, history (+7 more)

### Community 39 - "Custom Exercise Screen"
Cohesion: 0.12
Nodes (15): Equipment, FormState, _aliasesCtrl, _category, createState, _descCtrl, dispose, _equipment (+7 more)

### Community 40 - "Q Builder Screen"
Cohesion: 0.13
Nodes (15): package:url_launcher/url_launcher.dart, _buildDropdown, _buildSectionLabel, createState, _duration, _equipment, _focus, _format (+7 more)

### Community 41 - "Local Login Screen"
Cohesion: 0.16
Nodes (14): AppProfileService, build, _checking, createState, initState, LocalLoginScreen, _LocalLoginScreenState, _lock (+6 more)

### Community 42 - "AI Model Integration"
Cohesion: 0.13
Nodes (14): bool get, GenerativeModel?, ../models/workout_plan.dart, package:google_generative_ai/google_generative_ai.dart, askSpartan, auditBeatdown, _chatSession, generateBackblast (+6 more)

### Community 43 - "Exercise UI Widgets"
Cohesion: 0.14
Nodes (14): category_chip.dart, Exercise, intensity_badge.dart, ../services/settings_service.dart, build, createState, exercise, ExerciseCard (+6 more)

### Community 44 - "App Package Imports (History)"
Cohesion: 0.16
Nodes (11): package:f3_nation_app/models/workout_history.dart, package:f3_nation_app/services/app_profile_service.dart, package:f3_nation_app/services/backblast_formatter.dart, package:f3_nation_app/services/history_service.dart, package:f3_nation_app/services/local_backup_service.dart, package:f3_nation_app/services/region_service.dart, package:shared_preferences/shared_preferences.dart, main (+3 more)

### Community 45 - "App Package Imports (Workout)"
Cohesion: 0.15
Nodes (13): package:f3_nation_app/models/workout_settings.dart, package:f3_nation_app/services/exercise_service.dart, package:f3_nation_app/services/q_builder_service.dart, package:f3_nation_app/services/workout_generator.dart, return, _buildSyntheticService, counter, exercises (+5 more)

### Community 46 - "History Service"
Cohesion: 0.13
Nodes (14): package:flutter/foundation.dart, add, all, clear, delete, _items, _key, load (+6 more)

### Community 47 - "Screen State Classes"
Cohesion: 0.19
Nodes (15): CustomExerciseScreen, _CustomExerciseScreenState, BackblastScreen, _BackblastScreenState, LibraryScreen, _LibraryScreenState, _ExerciseDemo, _ExerciseDemoState (+7 more)

### Community 48 - "Exercise Service"
Cohesion: 0.13
Nodes (14): addCustomExercise, all, _assetPath, byCategory, _customExercises, _customKey, deleteCustomExercise, _exercises (+6 more)

### Community 49 - "Notification Service"
Cohesion: 0.14
Nodes (13): package:flutter_local_notifications/flutter_local_notifications.dart, package:timezone/data/latest_all.dart, package:timezone/timezone.dart, cancelReminder, init, _instance, _nextWeekday, NotificationService (+5 more)

### Community 50 - "Exercise Library Screen"
Cohesion: 0.14
Nodes (13): createState, dispose, _ExerciseList, exercises, _filteredExercises, initState, _intensityFilter, _query (+5 more)

### Community 51 - "Custom Exercise State"
Cohesion: 0.19
Nodes (13): ExerciseService, build, _CustomExerciseTile, _save, build, build, _swapExercise, build (+5 more)

### Community 52 - "Package Imports (Models)"
Cohesion: 0.15
Nodes (9): package:f3_nation_app/models/app_version.dart, package:f3_nation_app/models/qsource_data.dart, package:f3_nation_app/models/timer_state.dart, package:f3_nation_app/services/timer_service.dart, package:flutter_test/flutter_test.dart, main, main, main (+1 more)

### Community 53 - "Exicon CSV Converter"
Cohesion: 0.26
Nodes (11): Path, categorize(), convert(), html_to_text(), infer_intensity(), main(), parse_aliases(), Strip HTML tags and collapse whitespace to a single space. (+3 more)

### Community 54 - "Achievement Service"
Cohesion: 0.17
Nodes (11): Achievement, AchievementService, AchievementTier, compute, description, emoji, id, tier (+3 more)

### Community 55 - "App Service Imports"
Cohesion: 0.20
Nodes (9): app_profile_service.dart, history_service.dart, ../models/region_models.dart, region_service.dart, currentVersion, exportJson, importJson, LocalBackupService (+1 more)

### Community 56 - "Backblast Formatter"
Cohesion: 0.20
Nodes (8): dart:convert, ../models/workout_history.dart, package:http/http.dart, BackblastFormatter, _exList, format, postBackblast, SlackService

### Community 57 - "Flutter Material Imports"
Cohesion: 0.20
Nodes (8): ../models/app_version.dart, package:flutter/material.dart, package:flutter/services.dart, q_builder_screen.dart, build, build, _showReleaseLog, VersionFooter

### Community 58 - "Screen Navigation"
Cohesion: 0.22
Nodes (9): MaterialPageRoute, build, _postToSlack, build, HomeScreen, build, _speak, _generate (+1 more)

### Community 59 - "Q Builder Request/Result"
Cohesion: 0.22
Nodes (8): q_builder_service.dart, QBuilderRequest, QBuilderResult, QBuilderReview, SpartanRequest, SpartanResult, SpartanReview, typedef

### Community 60 - "Service ChangeNotifiers"
Cohesion: 0.25
Nodes (8): ChangeNotifier, AppProfileService, AuthService, ExerciseService, HistoryService, RegionService, SettingsService, TimerService

### Community 61 - "Achievements Screen"
Cohesion: 0.25
Nodes (7): package:provider/provider.dart, AchievementsScreen, badge, _BadgeTile, build, ../services/achievement_service.dart, ../services/history_service.dart

### Community 62 - "iOS Build Scripts"
Cohesion: 0.43
Nodes (6): code_sign_if_enabled(), install_bcsymbolmap(), install_dsym(), install_framework(), strip_invalid_archs(), Pods-Runner-frameworks.sh script

### Community 63 - "Android App Icons"
Cohesion: 0.95
Nodes (7): Android Mipmap Density Set, Flutter Default Launcher Icon (light blue + dark navy chevron logo), App Launcher Icon (hdpi), App Launcher Icon (mdpi), App Launcher Icon (xhdpi), App Launcher Icon (xxhdpi), App Launcher Icon (xxxhdpi)

### Community 64 - "Intensity Badge Widget"
Cohesion: 0.29
Nodes (6): Intensity, ../theme/app_theme.dart, build, intensity, IntensityBadge, small

### Community 65 - "Category Chip Widget"
Cohesion: 0.29
Nodes (6): ../models/exercise.dart, ExerciseCategory, build, category, CategoryChip, small

### Community 66 - "LLDB Debug Helpers"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 67 - "Android Plugin Registrant"
Cohesion: 0.47
Nodes (4): FlutterEngine, Keep, GeneratedPluginRegistrant, String

### Community 68 - "App Lock Service"
Cohesion: 0.33
Nodes (5): LocalAuthentication, package:local_auth/local_auth.dart, _auth, authenticate, LocalAppLockService

### Community 69 - "Core Package Imports"
Cohesion: 0.33
Nodes (5): package:f3_nation_app/models/exercise.dart, package:f3_nation_app/models/workout_plan.dart, package:f3_nation_app/services/current_workout_service.dart, main, _makePlan

### Community 70 - "Sherpa Wizard Screen"
Cohesion: 0.50
Nodes (4): @Deprecated, SpartanWizardScreen, QBuilderService, SpartanLegacyService

### Community 71 - "iOS Plugin Registrant"
Cohesion: 0.50
Nodes (3): FlutterLocalNotificationsPlugin, GeneratedPluginRegistrant, +registerWithRegistry

### Community 72 - "Auth Service Tests"
Cohesion: 0.50
Nodes (3): package:f3_nation_app/models/auth_models.dart, package:f3_nation_app/services/auth_service.dart, main

### Community 74 - "iOS Launch Images"
Cohesion: 1.00
Nodes (3): LaunchImage 2x (iOS Splash Screen), LaunchImage 3x (iOS Splash Screen), LaunchImage 1x (iOS Splash Screen)

## Knowledge Gaps
- **842 isolated node(s):** `flutter_export_environment.sh script`, `name`, `version`, `summary`, `description` (+837 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WorkoutSettings` connect `Workout Plan Models` to `Q Builder Service`, `Settings Service`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `CurrentWorkoutService` connect `Custom Exercise State` to `Animation & UI Controllers`, `Current Workout Service`, `Workout Session Screen`, `Q Builder Screen`, `Screen State Classes`, `App Entry & Main`, `Screen Navigation`, `Service ChangeNotifiers`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `TimerState` connect `App Navigation Shell` to `Animation & UI Controllers`, `Timer State Model`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_export_environment.sh script`, `name` to the rest of the system?**
  _848 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Animation & UI Controllers` be split into smaller, more focused modules?**
  _Cohesion score 0.025974025974025976 - nodes in this community are weakly interconnected._
- **Should `Spartan AI Chat Screen` be split into smaller, more focused modules?**
  _Cohesion score 0.05121951219512195 - nodes in this community are weakly interconnected._
- **Should `Settings Service` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._