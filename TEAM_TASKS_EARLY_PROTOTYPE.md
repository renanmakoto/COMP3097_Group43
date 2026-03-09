# ShopSense Early Prototype Playbook (COMP3097)

Last updated: March 1, 2026

## 1. Project Context

- Course: `COMP3097 - Mobile App Development II`
- Team members:
  - `Renan Yoshida Avelan` (`101536279`)
  - `Lucas Tavares Criscuolo` (`101500671`)
  - `Gustavo Miranda` (`101488574`)
- Current milestone: `Early Prototype` (due March 15)
- Required progress target now:
  - Around `30%` of screens should be functional
  - Must use `real data` (not mock data) for implemented screens
  - Submit/present a short `2-5 minute` progress video with all members participating

## 2. Copy to Mac and Run (Complete Setup)

## 2.1 Prerequisites on Mac

- macOS with Xcode installed (recommended: latest stable Xcode)
- Apple command line tools (installed with Xcode)
- Git installed

## 2.2 Copy Project to Mac

1. Copy folder `COMP3097_Group43` to your Mac.
2. Open Terminal on Mac.
3. Go to the project directory:

```bash
cd "/path/to/COMP3097_Group43"
```

4. Open Xcode project:

```bash
open ShopSense.xcodeproj
```

## 2.3 Xcode Run Configuration

1. In Xcode, select scheme `ShopSense`.
2. Select simulator/device target:
  - Recommended target device for this project: `iPhone 15 Pro` (portrait).
3. Build settings:
  - Signing may require selecting your Apple Team in `Signing & Capabilities` if testing on physical device.
4. Run:
  - Press `Cmd + R`.

## 2.4 If Build Fails

1. Product -> `Clean Build Folder` (`Shift + Cmd + K`).
2. Delete Derived Data:
  - Xcode -> Settings -> Locations -> click Derived Data arrow -> delete ShopSense folder.
3. Reopen project and run again.

## 2.5 Data Notes

- The app uses `Core Data` local persistence (`ShopSense.xcdatamodeld`).
- Persisted data is simulator-specific. If you reset simulator or reinstall app, data resets.

## 3. Current Codebase Snapshot (Important Before Splitting Work)

1. A custom `LaunchScreenView` exists, but app currently starts directly in `MainView`.
2. Shopping list CRUD is mostly implemented, but list edit entry from main list needs completion/cleanup.
3. Taxability is currently hardcoded in some places using category names instead of reading `ProductCategory.isTaxable`.
4. Default category creation logic is duplicated in two views.
5. Settings has placeholder export logic.

## 4. Team Work Split (Detailed)

## 4.1 Renan - App Shell + Integration Owner

### Branch

- `feature/renan-shell-integration`

### Main Ownership Files

- `ShopSense/ShopSenseApp.swift`
- `ShopSense/Views/MainView.swift`
- `ShopSense/Views/LaunchScreenView.swift`
- Integration-level updates in `ShopSense/Views/SettingsView.swift` (team metadata consistency only)

### Goals

1. Implement startup flow:
  - Show launch/splash screen first
  - Transition to main tab app after short delay (~1-2 seconds)
2. Keep navigation stable in `TabView` (`Lists`, `Categories`, `Calculator`, `Settings`).
3. Keep team information consistent across launch/about/settings sections.
4. Integrate teammates' branches safely and resolve conflicts.
5. Produce demo-ready integrated build for prototype video.

### Implementation Checklist

1. Create root state in `ShopSenseApp`:
  - `@State private var showLaunch = true`
  - Render `LaunchScreenView` when `showLaunch == true`, else `MainView`
2. Add timed transition:
  - Use `DispatchQueue.main.asyncAfter` in `.task` or `.onAppear`.
  - Animate transition for cleaner UX.
3. Verify `MainView` tabs open correctly and preserve environment context.
4. Review team names and IDs shown in app text sections; align formatting and spelling.
5. Merge `feature/gustavo-list-crud` and `feature/lucas-tax-categories`.
6. Resolve any merge conflicts and retest startup + all tabs.

### Out of Scope

- Do not change tax formulas or category tax rules.
- Do not rewrite shopping list CRUD behavior unless needed only for merge conflict resolution.

### Done Criteria

1. App shows launch/team screen at startup then transitions to tab app.
2. All tabs open without crash.
3. Team details are consistent where displayed.
4. Integration branch is stable and demo-ready.

### Manual Test Script

1. Fresh app launch -> confirm launch screen appears.
2. Confirm transition to main tabs within ~1-2 seconds.
3. Open each tab and interact minimally (no crash).
4. Open Settings and verify team details.
5. Close app and relaunch -> startup flow still works.

### Suggested Commit Messages

- `feat(app): add startup launch flow before main view`
- `refactor(nav): keep tab shell stable after launch transition`
- `chore(meta): align team info across app screens`
- `merge: integrate gustavo list-crud branch`
- `merge: integrate lucas tax-categories branch`

## 4.2 Gustavo - Shopping Lists + Core CRUD Owner

### Branch

- `feature/gustavo-list-crud`

### Main Ownership Files

- `ShopSense/Views/ShoppingListsView.swift`
- CRUD sections in `ShopSense/Views/ShoppingListDetailView.swift`
- Optional helper updates in `ShopSense/Services/PersistenceController.swift` if required for save behavior

### Goals

1. Finalize shopping list CRUD:
  - Create list
  - Edit list
  - Delete list
2. Finalize shopping item CRUD inside list detail:
  - Create/edit/delete item
  - Toggle purchased status
3. Keep budget/progress/summary values reactive and correct after all updates.
4. Improve form validation (non-empty names, sensible numeric values).
5. Verify all changes persist after app relaunch (real Core Data data).

### Implementation Checklist

1. Main list screen:
  - Add explicit list edit entry (tap or swipe action).
  - Remove unused/dead state variables if no longer needed.
2. List form:
  - Ensure editing preloads list values.
  - Ensure save updates existing list instead of duplicate creation.
3. Detail screen:
  - Verify item add/edit sheets pass correct item/list.
  - Verify swipe actions update purchased state and delete reliably.
4. Validation:
  - Block empty list names.
  - Block empty item names.
  - Guard against invalid quantity/negative values if needed.
5. Persistence:
  - Create data, kill app, relaunch, confirm data remains.

### Out of Scope

- Do not modify province tax rates.
- Do not redesign category tax logic (Lucas owns that).

### Done Criteria

1. User can add/edit/delete lists from list screen.
2. User can add/edit/delete/toggle purchased for items.
3. Budget + progress + totals update correctly after each action.
4. Data survives app restart.

### Manual Test Script

1. Create list `Weekly` with budget `100`.
2. Edit list name to `Weekly Groceries`.
3. Add 3 items with different price/qty.
4. Mark one as purchased; verify progress changes.
5. Edit one item quantity; verify totals update.
6. Delete one item; verify totals update.
7. Relaunch app; verify remaining data persists.
8. Delete list; verify it disappears.

### Suggested Commit Messages

- `feat(lists): add list edit flow from main lists screen`
- `feat(items): improve item CRUD behavior in detail view`
- `fix(validation): enforce list and item required fields`
- `fix(totals): keep budget/progress reactive after mutations`
- `test(manual): verify persistence across relaunch`

## 4.3 Lucas - Categories + Tax Logic Owner

### Branch

- `feature/lucas-tax-categories`

### Main Ownership Files

- `ShopSense/Views/CategoriesView.swift`
- `ShopSense/Models/TaxCalculator.swift`
- `ShopSense/Views/TaxCalculatorView.swift`
- Tax/category sections in:
  - `ShopSense/Views/AddEditItemView.swift`
  - `ShopSense/Views/ShoppingListDetailView.swift`

### Goals

1. Replace hardcoded category-name tax rules with real `ProductCategory.isTaxable`.
2. Keep tax indicator in item form based on actual category record.
3. Keep province tax calculations correct and synchronized via `selectedProvince`.
4. Remove duplicated default category seeding by centralizing into one reusable helper.
5. Ensure category CRUD affects tax behavior immediately.

### Implementation Checklist

1. Create centralized defaults source (single place), e.g. in model/service helper:
  - Array of default category records (`name`, `icon`, `colorHex`, `isTaxable`)
  - Reuse this source from all places that seed defaults
2. Update taxability resolution:
  - In list detail tax computation, map item category name -> `ProductCategory` record -> `isTaxable`
  - Fallback behavior if category missing: taxable `true` (or agreed fallback)
3. Update item form tax indicator:
  - When category selected, resolve from fetched `ProductCategory`.
4. Keep `TaxCalculator` focused on rates/math only.
5. Retest province picker effects from Settings and Tax Calculator.

### Out of Scope

- Do not change app startup flow (Renan owns).
- Do not rewrite list CRUD UX (Gustavo owns).

### Done Criteria

1. Editing category taxable toggle changes shopping tax totals for relevant items.
2. Item form tax hint matches actual stored category setting.
3. Default category data is not duplicated across multiple seed implementations.
4. Province-based tax rates still calculate correctly.

### Manual Test Script

1. Create new category `Snacks` as tax-exempt.
2. Add item with `Snacks` category -> verify no tax on that item contribution.
3. Edit `Snacks` to taxable -> verify tax now applies.
4. Change province in Settings -> verify calculator and list tax reflect new rate.
5. Reset data and verify default categories reseed correctly without duplicates.

### Suggested Commit Messages

- `refactor(categories): centralize default category seed definitions`
- `feat(tax): derive item taxability from ProductCategory records`
- `feat(items): align category tax indicator with persisted category data`
- `refactor(detail): remove hardcoded exempt-category name checks`
- `test(manual): verify province and category tax behavior`

## 5. Shared Git Workflow and Contribution Requirements

1. Use one branch per member.
2. Each member makes `5-8` meaningful commits.
3. Use PRs into `develop` with:
  - What changed
  - Screens touched
  - Manual tests run
  - 1 short clip or screenshots
4. No one force-pushes shared branches.
5. Renan (integration owner) merges and prepares final early-prototype branch.

## 6. Merge/Integration Order

1. Gustavo PR to `develop`.
2. Lucas rebases/updates from latest `develop`, then PR.
3. Renan merges both to integration branch and resolves conflicts.
4. Final smoke test on integrated branch.

## 7. Early Prototype Video Plan (2-5 minutes)

1. Intro (Renan, 20-30s):
  - App idea and current milestone
2. App shell demo (Renan, 30-45s):
  - Launch flow + tabs
3. CRUD demo (Gustavo, 60-90s):
  - List/item create-edit-delete + persistence proof after relaunch
4. Tax/categories demo (Lucas, 60-90s):
  - Category taxable toggle + province change impact
5. Closing (Renan, 20-30s):
  - What is complete now (~30%) and next steps

## 8. Definition of Done for This Early Prototype

The team can claim early prototype complete when all are true:

1. At least one end-to-end flow is fully functional with real data:
  - Create list -> add items -> category assignment -> tax + totals -> persistence after relaunch
2. Core screens are clickable and partially functional:
  - Lists, List Detail, Categories, Tax Calculator, Settings, Launch
3. Team contributions are visible in Git history.
4. Video includes all members and shows implemented (real) behavior.

## 9. Quick Status Checklist (Use Before Demo)

- [ ] App opens with launch/team branding
- [ ] Main tabs are stable
- [ ] List CRUD works
- [ ] Item CRUD works
- [ ] Category CRUD works
- [ ] Tax reflects province and category taxability
- [ ] Data persists after relaunch
- [ ] Team member contributions visible in commit history
- [ ] 2-5 minute progress video recorded with all members

## 10. Codex Prompt Templates (Optional)

Use these exact prompts if each teammate runs Codex separately.

### Renan Prompt

```text
Work on branch feature/renan-shell-integration in ShopSense.
Scope: ShopSenseApp.swift, MainView.swift, LaunchScreenView.swift, and integration-safe metadata in SettingsView.swift.
Implement startup launch flow (LaunchScreenView -> MainView after short delay), keep tabs stable, and align team metadata text.
Do not modify tax algorithms or list/category CRUD internals.
Provide changed files, tests run, and remaining risks.
```

### Gustavo Prompt

```text
Work on branch feature/gustavo-list-crud in ShopSense.
Scope: ShoppingListsView.swift and list/item CRUD logic in ShoppingListDetailView.swift.
Complete list add/edit/delete flow, ensure item CRUD/purchased toggle reliability, improve validation, and verify persistence after relaunch.
Do not change tax formulas or category tax logic.
Provide changed files, tests run, and remaining risks.
```

### Lucas Prompt

```text
Work on branch feature/lucas-tax-categories in ShopSense.
Scope: CategoriesView.swift, TaxCalculator.swift, TaxCalculatorView.swift, and tax-related portions of AddEditItemView.swift and ShoppingListDetailView.swift.
Replace hardcoded tax-exempt category logic with ProductCategory.isTaxable from Core Data, centralize default category seed logic, and keep province tax behavior correct.
Do not modify app startup shell or unrelated list CRUD UX.
Provide changed files, tests run, and remaining risks.
```

## 11. Deep Project Description (What This App Is)

`ShopSense` is an iOS SwiftUI shopping list app with built-in Canadian tax calculation and category management.

Core concept:

1. User creates one or more shopping lists.
2. User adds items with quantity, price, and optional category.
3. App tracks purchased status and budget progress.
4. App calculates tax and totals based on selected province and taxable/non-taxable categories.
5. All data persists locally via Core Data.

Core architecture:

1. UI layer: SwiftUI views in `ShopSense/Views`.
2. Domain/helper layer: `TaxCalculator` in `ShopSense/Models/TaxCalculator.swift`.
3. Persistence layer: Core Data stack in `ShopSense/Services/PersistenceController.swift`.
4. Data model: `ShopSense/Resources/ShopSense.xcdatamodeld`.

Core entities:

1. `ShoppingList`
  - `id`, `name`, `createdAt`, `budget`
  - one-to-many relationship to `ShoppingItem`
2. `ShoppingItem`
  - `id`, `name`, `price`, `quantity`, `isPurchased`, `categoryName`, `notes`
  - many-to-one relationship to `ShoppingList`
3. `ProductCategory`
  - `id`, `name`, `iconName`, `colorHex`, `isTaxable`

## 12. Current Implementation Status (As of March 1, 2026)

Legend:

- `Complete`: Functional with real data and usable
- `Partial`: Mostly implemented but has important gaps
- `Missing`: Not implemented for prototype standards

### 12.1 App Entry and Navigation

1. `ShopSenseApp.swift`: `Partial`
  - Core Data context injection is done.
  - App currently starts directly at `MainView`.
  - `LaunchScreenView` is not actually used in runtime flow yet.
2. `MainView.swift`: `Complete`
  - Tab navigation exists for `Lists`, `Categories`, `Calculator`, `Settings`.
  - UI shell is stable and clean for early prototype.

### 12.2 Launch and Team Branding

1. `LaunchScreenView.swift`: `Complete (Standalone), Partial (Integration)`
  - Screen design and team names are present.
  - It must be integrated into app startup sequence to count fully.

### 12.3 Shopping Lists Screen

1. `ShoppingListsView.swift`: `Partial-Complete`
  - Reads real lists from Core Data via `@FetchRequest`.
  - Add list flow exists.
  - Delete list flow exists.
  - Missing clear edit-entry UX for existing lists from this screen.
  - There is an unused `selectedList` state that should be cleaned or used.

### 12.4 List Detail Screen

1. `ShoppingListDetailView.swift`: `Partial-Complete`
  - Shows list items with grouped sections by category.
  - Supports add, edit (tap item), delete, and purchased toggle.
  - Shows subtotal, tax, total, progress, and budget remaining.
  - Current taxability check uses hardcoded category names (needs real category lookup).

### 12.5 Add/Edit Item Screen

1. `AddEditItemView.swift`: `Partial-Complete`
  - Form includes item name, price, quantity, category, notes.
  - Uses real categories from Core Data picker.
  - Validation for name exists.
  - Tax indicator currently depends on hardcoded category name list.
  - Contains duplicated default category seeding logic.

### 12.6 Categories Screen

1. `CategoriesView.swift`: `Complete (Feature), Partial (Architecture)`
  - Category CRUD exists with color/icon/taxable flag.
  - Categories loaded from Core Data.
  - Creates defaults when empty.
  - Also duplicates default seeding logic (same as AddEditItemView).

### 12.7 Tax Calculator Screen

1. `TaxCalculatorView.swift`: `Complete`
  - Province picker and tax calculations work.
  - Quick amount buttons and result display implemented.
  - Uses shared selected province via `@AppStorage`.

### 12.8 Settings Screen

1. `SettingsView.swift`: `Partial`
  - Province selection exists and is connected.
  - Reset all data exists and executes batch delete.
  - About section and team information exist.
  - Export is placeholder only.
  - Some settings (`showPurchasedItems`, `defaultBudget`) are not fully applied in other screens.

### 12.9 Persistence and Data Model

1. `PersistenceController.swift`: `Complete`
  - Shared singleton stack setup is done.
  - Save helper exists.
  - Preview in-memory stack exists.
2. Core Data model file: `Complete`
  - Entities and relationships for early prototype exist.

## 13. What Is Already Done (High-Confidence Summary)

1. Core app shell and screen structure exists with at least 3+ screens plus launch view file.
2. Real persistence is already in use (`Core Data`) for lists/items/categories.
3. Basic CRUD is implemented for:
  - Lists (create/delete, edit form exists)
  - Items (create/edit/delete/toggle purchased)
  - Categories (create/edit/delete)
4. Tax calculator works by province and displays tax breakdown.
5. Budget and progress visualization already exists in list/list-detail views.
6. Team and course metadata are already present in app UI comments/sections.

## 14. What Still Needs To Be Done (Detailed)

Priority labels:

- `P0`: Must complete for early prototype quality
- `P1`: Should complete for stronger demo
- `P2`: Nice to have if time remains

### 14.1 P0 Items

1. Integrate launch flow at runtime (`LaunchScreenView -> MainView`) in app startup.
2. Replace hardcoded taxability rules with category-based taxability (`ProductCategory.isTaxable`).
3. Remove duplicate default category seed implementations and centralize them.
4. Finalize list edit entry from list screen UX.
5. Verify real-data persistence via relaunch demo script.
6. Record 2-5 minute team video where every member demonstrates their own contribution.

### 14.2 P1 Items

1. Connect `defaultBudget` from settings to new-list creation defaults.
2. Connect `showPurchasedItems` to hide/show purchased items in list detail.
3. Improve validation for numeric fields (e.g., prevent negative price).
4. Add better error feedback for save/reset operations.

### 14.3 P2 Items

1. Implement actual export behavior in Settings.
2. Add lightweight test coverage (unit tests for `TaxCalculator` at minimum).
3. Improve architecture by using category relationship on item instead of only category name string.

## 15. Ownership and Responsibilities (Who Does What)

## 15.1 Renan (Owner: App Shell + Integration)

Owns:

1. Startup flow, root composition, and global navigation stability.
2. Final integration branch and merge coordination.
3. Final demo build readiness and final video stitching/ordering.

Files:

1. `ShopSense/ShopSenseApp.swift`
2. `ShopSense/Views/MainView.swift`
3. `ShopSense/Views/LaunchScreenView.swift`
4. Team-metadata consistency in `ShopSense/Views/SettingsView.swift`

Must deliver:

1. Launch view appears during startup and transitions cleanly.
2. App remains stable after integrating Lucas and Gustavo branches.
3. Final branch is smoke-tested and ready to demo.

## 15.2 Gustavo (Owner: Shopping Lists and Items CRUD)

Owns:

1. Reliable list and item CRUD user flow.
2. Form validation and list-detail consistency.
3. Persistence behavior checks for CRUD operations.

Files:

1. `ShopSense/Views/ShoppingListsView.swift`
2. List and item CRUD sections in `ShopSense/Views/ShoppingListDetailView.swift`

Must deliver:

1. Clear edit path for shopping lists from list screen.
2. Item operations are reliable and update totals/progress immediately.
3. Relauch persistence proof for created/edited data.

## 15.3 Lucas (Owner: Categories and Tax Behavior)

Owns:

1. Category-driven taxability logic.
2. Tax calculator consistency across screens.
3. Centralized default category seed definitions.

Files:

1. `ShopSense/Views/CategoriesView.swift`
2. `ShopSense/Models/TaxCalculator.swift`
3. `ShopSense/Views/TaxCalculatorView.swift`
4. Tax-related sections of:
  - `ShopSense/Views/AddEditItemView.swift`
  - `ShopSense/Views/ShoppingListDetailView.swift`

Must deliver:

1. Tax behavior changes when category tax flag changes.
2. Item form indicator matches real category `isTaxable`.
3. No duplicate default seed logic across views.

## 16. Detailed File-by-File Task Matrix

1. `ShopSense/ShopSenseApp.swift`
  - Owner: Renan
  - Status: Partial
  - Next: launch state + timed transition logic
2. `ShopSense/Views/MainView.swift`
  - Owner: Renan
  - Status: Good
  - Next: keep stable, only minor integration cleanups
3. `ShopSense/Views/LaunchScreenView.swift`
  - Owner: Renan
  - Status: Built
  - Next: wire into startup path
4. `ShopSense/Views/ShoppingListsView.swift`
  - Owner: Gustavo
  - Status: Partial-complete
  - Next: clear edit path + cleanup dead state
5. `ShopSense/Views/ShoppingListDetailView.swift`
  - Owner: Shared boundary (Gustavo CRUD + Lucas tax portions)
  - Status: Partial-complete
  - Next: preserve CRUD while swapping taxability logic to category-backed data
6. `ShopSense/Views/AddEditItemView.swift`
  - Owner: Shared boundary (Gustavo item UX + Lucas tax/category indicator)
  - Status: Partial-complete
  - Next: category-tax indicator from real category data + seed centralization
7. `ShopSense/Views/CategoriesView.swift`
  - Owner: Lucas
  - Status: Good feature coverage
  - Next: integrate centralized seeding helper
8. `ShopSense/Views/TaxCalculatorView.swift`
  - Owner: Lucas
  - Status: Good
  - Next: regression-check only
9. `ShopSense/Views/SettingsView.swift`
  - Owner: Renan (integration), Lucas/Gustavo consume settings values
  - Status: Partial
  - Next: ensure settings-backed behavior is used where planned
10. `ShopSense/Models/TaxCalculator.swift`
  - Owner: Lucas
  - Status: Good
  - Next: keep unchanged unless bug discovered
11. `ShopSense/Services/PersistenceController.swift`
  - Owner: shared (minimal edits)
  - Status: Good
  - Next: avoid major changes unless necessary
12. `ShopSense/Resources/ShopSense.xcdatamodeld/.../contents`
  - Owner: one person at a time (prefer Renan as integrator for schema changes)
  - Status: Stable
  - Next: avoid schema changes before early prototype unless critical

## 17. Risk Register (What Could Break)

1. Merge conflicts in shared files:
  - `ShoppingListDetailView.swift`
  - `AddEditItemView.swift`
2. Category-name string design risk:
  - Items store `categoryName` string, so renaming/deleting categories can cause tax lookup mismatch.
3. Reset-all-data batch delete may require explicit UI refresh handling in some cases.
4. Launch flow integration could accidentally break environment context if root view wrapping is incorrect.
5. Placeholder export may be asked in demo; team should explicitly mention it as future work.

Mitigation:

1. Merge frequently and keep PR scope small.
2. Lucas defines fallback if category record not found (default taxable true).
3. Renan smoke-tests every tab after each merge.
4. Keep schema unchanged until after prototype milestone.

## 18. Execution Sequence for Fast Delivery

1. Gustavo implements list/item UX fixes first and opens PR.
2. Lucas rebases from updated `develop`, then implements tax/category fixes and opens PR.
3. Renan merges both, implements launch flow, finalizes integration.
4. Team runs complete manual regression script.
5. Record and submit progress video.

## 19. Full Manual Regression Script (Final Check Before Video)

1. Launch app and verify launch screen transition.
2. Create new list with budget.
3. Edit list name and verify update.
4. Add item with taxable category.
5. Add item with tax-exempt category.
6. Toggle one item as purchased and verify progress.
7. Verify subtotal, tax, and total values.
8. Change province in settings and verify tax updates.
9. Edit category taxable toggle and verify list total tax changes.
10. Delete one item and verify totals recalculate.
11. Close and relaunch app to verify persistence.
12. Use reset all data and confirm app clears records correctly.

## 20. Contribution Evidence Checklist (For Grading)

1. Each member has personal feature branch commits.
2. Each member has at least one PR with clear technical description.
3. Commit messages show meaningful technical work.
4. Video includes each member demonstrating owned feature.
5. Final integrated branch history clearly includes all three contributors.

## 21. Optional Post-Prototype Backlog (After March 15)

1. Implement export to JSON/CSV or share sheet.
2. Add unit tests for tax calculations and category mapping.
3. Improve data model:
  - Store category relationship on `ShoppingItem` instead of name string.
4. Add search/filter in list screens.
5. Add accessibility pass (dynamic type, labels, contrast checks).

