# 🏏 SMASH UP INDIA - Backend API

Production-grade Node.js + Express + PostgreSQL backend for **SMASH UP INDIA**, a comprehensive mobile platform for sports pitch bookings, pickup game scheduling, player wallet transactions, real-time match score streaming, and CCTV camera recording management.

---

## 🌟 Key Features

* **Authentication & RBAC**:
  * Public registration creates `PLAYER` (Role ID 3) accounts exclusively with OTP verification.
  * Login with Email OR Phone + Password.
  * Role-Based Access Control: `ADMIN` (Super/Ops/Finance), `MANAGER` (Club Scope), `PLAYER`.
* **Wallet & Razorpay Payments**:
  * 6-digit Wallet PIN security.
  * Maximum wallet balance capped at ₹2,00,000; single top-up maximum ₹50,000.
  * HMAC SHA256 signature verification server-side.
  * Auto-settlement and refund safety routines.
* **Pickle Pitch Booking & Game Scheduling**:
  * Formats: 1v1, 2v2, 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 11v11.
  * Positions: GK, CB, LB, RB, LWB, RWB, DEF, CDM, CM, CAM, LM, RM, MID, ST, CF, LW, RW, FWD, WING.
  * Automatic team balancing (`TEAM_A` vs `TEAM_B`) and roster management.
* **Manager CCTV Dashboard & Recording Worker**:
  * AES-256-GCM encrypted RTSP credentials.
  * Stream connection testing.
  * Match recording auto-start, auto-stop at scheduled match end + 15 minutes post-match window, manual stop, and extension deadline logic.
  * S3-compatible private video storage with short-lived pre-signed playback URLs.
* **Real-Time Data Streaming (`Socket.IO`)**:
  * Real-time live score updates broadcast to `game:<gameId>` rooms.
  * Real-time wallet balance and notification updates.

---

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Configure Environment:**
   Copy `.env.example` to `.env` and adjust database credentials (`DATABASE_URL=postgresql://postgres:system@localhost:5432/smash_up_india`).

3. **Run Unit & Integration Tests:**
   ```bash
   npm test
   ```

4. **Start Development Server (with hot reload):**
   ```bash
   npm run dev
   ```

5. **Start Production Server:**
   ```bash
   npm start
   ```

---

## 📖 API Documentation & Health Check

* **Health Endpoint:** `GET http://localhost:5000/api/v1/health`
* **Swagger OpenAPI Docs:** `http://localhost:5000/api-docs`
