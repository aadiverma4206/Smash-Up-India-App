# Implementation Plan - Match History & Real-World Match Control Rules

Implement robust backend business logic and frontend UI for manager match history (`ManagerHistoryView`), pagination (20 items limit with infinite scroll load more), completion threshold (end time + 15 minutes), score locking (manager can add score once; subsequent edits restricted to Admin only), removal of start/edit actions for completed/history matches, CCTV video playback integration, and proper roster player list with payment/amount details.

## User Review Required

> [!IMPORTANT]
> - **Pagination & Infinite Scroll**: History matches endpoint will support pagination (`limit = 20`, `offset`), loading next batch when scrolling near the end (e.g. 20 -> 40).
> - **Completion Threshold**: Matches transition to `COMPLETED` status only after their scheduled end time + 15 minutes.
> - **Score Locking Rule**: Managers can submit match scores once; after submission, only Admins (`role_id = 1`) can modify scores.
> - **Completed Match Restrictions**: Managers cannot start or edit completed/history matches in details view.
> - **CCTV & Roster Details**: Match details will display CCTV camera recordings/playback and a comprehensive roster player list with payment/amount statuses and total amount collected.
> - **Backend-First Architecture**: All complex filtering, pagination logic, score-locking rules, and calculations will be executed in backend TypeScript services (`manager.service.ts` / `manager.repository.ts`).

## Proposed Changes

### Backend (`all_stars_arena_backend/`)

#### [MODIFY] [manager.repository.ts](file:///C:/Users/PCv/StudioProjects/all_stars_arena/all_stars_arena_backend/src/modules/manager/manager.repository.ts)
- Add pagination support (`LIMIT $x OFFSET $y`) for club history matches (`COMPLETED` or `CANCELLED`).
- Fetch complete player roster (`game_players` with user details, positions, payment statuses, and amounts) and CCTV recordings.

#### [MODIFY] [manager.service.ts](file:///C:/Users/PCv/StudioProjects/all_stars_arena/all_stars_arena_backend/src/modules/manager/manager.service.ts)
- Enforce business rules for match completion time (End Time + 15 mins).
- Enforce score submission and locking rules (Manager can add score once; only Admin can edit submitted scores).
- Prevent managers from starting or editing completed matches.

### Frontend (`lib/`)

#### [MODIFY] [manager_courts_view.dart](file:///C:/Users/PCv/StudioProjects/all_stars_arena/lib/modules/manager/views/manager_courts_view.dart)
- Ensure completed matches (`COMPLETED`) are filtered out of the active court matches view.

#### [MODIFY] [manager_history_view.dart](file:///C:/Users/PCv/StudioProjects/all_stars_arena/lib/modules/manager/views/manager_history_view.dart)
- Implement UI matching `ManagerCourtsView` (compact cards, date filters, search bar, scrollbar, theme-aware).
- Implement infinite scroll pagination (loads 20 items at a time, loading more on scroll end).

#### [MODIFY] [manager_game_details_view.dart](file:///C:/Users/PCv/StudioProjects/all_stars_arena/lib/modules/manager/views/manager_game_details_view.dart)
- Restrict "Start Match" and "Edit" buttons for completed/history matches.
- Implement score submission form for managers (locked once added unless user is Admin).
- Display CCTV camera recording videos section below cameras.
- Show detailed player roster list with payment statuses and total amount collected.

## Verification Plan

### Automated Tests
- Run `flutter test` and backend tests to verify scope and rule enforcement.

### Manual Verification
- Verify that completed matches do not appear in `ManagerCourtsView` and appear in `ManagerHistoryView`.
- Verify pagination and infinite scroll in history view.
- Verify history match controls, score locking, CCTV video playback, and player roster payment details.
