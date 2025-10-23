# Comprehensive Prompt for Building Pathome Diagnostics Aggregator

I need you to build a **production-ready, secure, full-stack web application** for Pathome Diagnostics Aggregator based on the following requirements. This should be a complete, locally hostable MVP with all core functionalities working end-to-end.

---

## PROJECT OVERVIEW

**Product:** Pathome Diagnostics Aggregator - A marketplace connecting patients with NABL-accredited diagnostic labs for home sample collection, real-time tracking, and secure digital report delivery.

**Technology Stack Requirements:**
- **Frontend:** Next.js 14+ (App Router) with TypeScript, Tailwind CSS, shadcn/ui components
- **Backend:** Node.js with NestJS framework (TypeScript)
- **Database:** PostgreSQL 15+
- **Cache/Queue:** Redis
- **Storage:** Local file system (simulating S3 for MVP, with clear migration path to AWS S3)
- **Authentication:** JWT-based with OTP (simulation mode for local testing)
- **API:** RESTful with proper OpenAPI/Swagger documentation

---

## CRITICAL SECURITY REQUIREMENTS

1. **Authentication & Authorization:**
   - Implement OTP-based authentication (mock OTP in dev: always accept "123456")
   - JWT tokens with 24h expiry, refresh token mechanism
   - Role-Based Access Control (RBAC): patient, lab_admin, phlebotomist, admin
   - Row-level security checks on all database queries

2. **Data Protection:**
   - All passwords/secrets hashed with bcrypt (min 12 rounds)
   - PII/PHI data encrypted at rest (use node crypto for sensitive fields)
   - HTTPS enforcement (provide SSL setup instructions for local)
   - SQL injection prevention (use parameterized queries/ORMs)
   - XSS protection (sanitize all user inputs, CSP headers)
   - CSRF protection with tokens

3. **Report Security:**
   - Generate tokenized URLs for report downloads with 48h expiry
   - Device fingerprinting for report access (track first access)
   - Watermark PDFs with patient name, date, booking ID
   - Rate limiting on sensitive endpoints (5 req/min per user)

4. **Audit & Compliance:**
   - Comprehensive audit logs for all admin/phleb actions
   - GDPR-ready data deletion capability
   - Structured logging with correlation IDs
   - Input validation on all endpoints (use class-validator)

---

## DATABASE SCHEMA

Implement these PostgreSQL tables with proper constraints, indexes, and relationships:

```sql
-- Core tables with all required fields, foreign keys, and indexes

users (
  id UUID PRIMARY KEY,
  role VARCHAR(20) CHECK (role IN ('patient', 'lab_admin', 'phlebotomist', 'admin')),
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(15) UNIQUE NOT NULL,
  email VARCHAR(255),
  password_hash VARCHAR(255),
  otp_secret VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_phone (phone)
)

labs (
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  nabl_id VARCHAR(50) UNIQUE,
  address TEXT,
  city VARCHAR(100),
  pincodes JSONB, -- array of serviceable pincodes
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  rating_avg DECIMAL(3, 2) DEFAULT 0,
  total_ratings INT DEFAULT 0,
  contact_phone VARCHAR(15),
  contact_email VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
)

tests (
  id UUID PRIMARY KEY,
  lab_id UUID REFERENCES labs(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  test_code VARCHAR(50),
  price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
  tat_hours INT NOT NULL CHECK (tat_hours > 0),
  description TEXT,
  sample_type VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_lab_name (lab_id, name),
  INDEX idx_search (name gin_trgm_ops) -- for fuzzy search
)

catalog_synonyms (
  id UUID PRIMARY KEY,
  test_id UUID REFERENCES tests(id) ON DELETE CASCADE,
  synonym VARCHAR(255) NOT NULL,
  INDEX idx_synonym (synonym gin_trgm_ops)
)

bookings (
  id UUID PRIMARY KEY,
  booking_number VARCHAR(20) UNIQUE NOT NULL,
  user_id UUID REFERENCES users(id),
  lab_id UUID REFERENCES labs(id),
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'assigned', 'en_route', 'collected', 'in_lab', 'processing', 'report_ready', 'completed', 'cancelled')),
  slot_start TIMESTAMP NOT NULL,
  slot_end TIMESTAMP NOT NULL,
  address_json JSONB NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  pincode VARCHAR(10),
  price_total DECIMAL(10, 2) NOT NULL,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  final_amount DECIMAL(10, 2) NOT NULL,
  coupon_id UUID REFERENCES coupons(id),
  payment_status VARCHAR(50) DEFAULT 'pending',
  payment_method VARCHAR(50),
  special_instructions TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_user_status (user_id, status),
  INDEX idx_lab_slot (lab_id, slot_start),
  INDEX idx_status_slot (status, slot_start)
)

booking_items (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
  test_id UUID REFERENCES tests(id),
  test_name VARCHAR(255),
  price DECIMAL(10, 2),
  quantity INT DEFAULT 1
)

phlebotomists (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) UNIQUE,
  home_latitude DECIMAL(10, 8),
  home_longitude DECIMAL(11, 8),
  serviceable_pincodes JSONB,
  max_bookings_per_day INT DEFAULT 10,
  rating_avg DECIMAL(3, 2) DEFAULT 0,
  total_ratings INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
)

assignments (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id) UNIQUE,
  phlebotomist_id UUID REFERENCES phlebotomists(id),
  status VARCHAR(50) DEFAULT 'assigned',
  assigned_at TIMESTAMP DEFAULT NOW(),
  eta TIMESTAMP,
  arrived_at TIMESTAMP,
  collected_at TIMESTAMP,
  otp_code VARCHAR(6),
  otp_verified_at TIMESTAMP,
  collection_notes TEXT,
  collection_photo_path VARCHAR(500),
  INDEX idx_phleb_status (phlebotomist_id, status)
)

reports (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id) UNIQUE,
  file_name VARCHAR(255),
  file_path VARCHAR(500),
  file_size_kb INT,
  mime_type VARCHAR(100),
  uploaded_by UUID REFERENCES users(id),
  uploaded_at TIMESTAMP DEFAULT NOW(),
  access_token VARCHAR(255) UNIQUE,
  token_expires_at TIMESTAMP,
  access_count INT DEFAULT 0,
  first_accessed_at TIMESTAMP,
  first_access_device_fingerprint VARCHAR(255)
)

notifications (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  user_id UUID REFERENCES users(id),
  channel VARCHAR(50) CHECK (channel IN ('sms', 'whatsapp', 'email')),
  template_name VARCHAR(100),
  recipient VARCHAR(255),
  message TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  retry_count INT DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
)

coupons (
  id UUID PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  discount_type VARCHAR(20) CHECK (discount_type IN ('flat', 'percentage')),
  discount_value DECIMAL(10, 2) NOT NULL,
  min_order_amount DECIMAL(10, 2) DEFAULT 0,
  max_discount DECIMAL(10, 2),
  valid_from TIMESTAMP NOT NULL,
  valid_until TIMESTAMP NOT NULL,
  max_uses INT,
  current_uses INT DEFAULT 0,
  per_user_cap INT DEFAULT 1,
  applicable_lab_ids JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
)

ratings (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  user_id UUID REFERENCES users(id),
  entity_type VARCHAR(20) CHECK (entity_type IN ('lab', 'phlebotomist')),
  entity_id UUID NOT NULL,
  stars INT CHECK (stars BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(booking_id, entity_type)
)

audit_logs (
  id UUID PRIMARY KEY,
  actor_user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50),
  entity_id UUID,
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_actor_action (actor_user_id, action, created_at)
)
```

---

## API ENDPOINTS (RESTful)

Implement all these endpoints with proper validation, error handling, and documentation:

### Authentication
- `POST /api/auth/otp/request` - Request OTP (input: phone)
- `POST /api/auth/otp/verify` - Verify OTP and get JWT (input: phone, otp)
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - Invalidate token

### Catalog & Search
- `GET /api/tests` - Search tests (query params: q, lab_id, pincode, price_min, price_max, tat_max, sort)
- `GET /api/tests/:id` - Get test details
- `GET /api/labs` - List labs (query params: pincode, city)
- `GET /api/labs/:id` - Get lab details with ratings

### Bookings (Patient)
- `POST /api/bookings` - Create booking
- `GET /api/bookings` - List user's bookings
- `GET /api/bookings/:id` - Get booking details with timeline
- `POST /api/bookings/:id/cancel` - Cancel booking (within allowed window)
- `GET /api/bookings/:id/timeline` - Get status timeline
- `POST /api/bookings/validate-slot` - Check slot availability

### Phlebotomist
- `GET /api/phlebotomist/jobs` - Get assigned jobs (query: date, status)
- `GET /api/phlebotomist/jobs/:id` - Get job details with navigation
- `POST /api/phlebotomist/jobs/:id/verify-otp` - Verify OTP at collection
- `PATCH /api/phlebotomist/jobs/:id/status` - Update job status
- `POST /api/phlebotomist/jobs/:id/upload-photo` - Upload collection proof

### Lab Portal
- `GET /api/lab/bookings` - List lab's bookings (filters: status, date range)
- `PATCH /api/lab/bookings/:id/status` - Update booking status
- `POST /api/lab/reports/upload` - Upload report PDF
- `GET /api/lab/tests` - List lab's test catalog
- `POST /api/lab/tests` - Add new test
- `PUT /api/lab/tests/:id` - Update test
- `DELETE /api/lab/tests/:id` - Deactivate test
- `POST /api/lab/tests/bulk-upload` - CSV upload for catalog

### Reports
- `GET /api/reports/:token/download` - Download report (tokenized)
- `GET /api/reports/:token/view` - View report metadata
- `POST /api/reports/:id/share` - Generate shareable link

### Admin/Ops
- `POST /api/admin/assignments` - Manual phlebotomist assignment
- `GET /api/admin/dashboard` - SLA metrics and alerts
- `GET /api/admin/bookings` - All bookings with filters
- `PATCH /api/admin/bookings/:id` - Override booking details
- `GET /api/admin/coupons` - List coupons
- `POST /api/admin/coupons` - Create coupon
- `PUT /api/admin/coupons/:id` - Update coupon
- `GET /api/admin/audit-logs` - Query audit logs

### Ratings
- `POST /api/ratings` - Submit rating (input: booking_id, entity_type, entity_id, stars, comment)
- `GET /api/ratings` - Get ratings (query: entity_type, entity_id)

---

## FRONTEND REQUIREMENTS

Create a responsive, accessible web application with these pages and components:

### Pages
1. **Home/Search** (`/`) - Test search with filters, lab comparison cards
2. **Test Details** (`/tests/:id`) - Test information, lab comparison, add to cart
3. **Cart** (`/cart`) - Review items, apply coupon, proceed to booking
4. **Booking Form** (`/booking/new`) - Address, slot selection, confirmation
5. **Booking Details** (`/bookings/:id`) - Live status timeline, contact options, report download
6. **My Bookings** (`/bookings`) - List view with filters
7. **Lab Portal** (`/lab/*`) - Booking management, catalog CRUD, report upload
8. **Phlebotomist App** (`/phleb/*`) - Job list, navigation, OTP verification, status updates
9. **Admin Dashboard** (`/admin/*`) - SLA monitoring, assignment management, coupon management
10. **Reports View** (`/reports/:token`) - Secure report viewer with watermark

### Key Components
- Search bar with autocomplete
- Filter panel (price, TAT, lab, rating, distance)
- Test/Lab cards with ratings, NABL badge
- Cart widget with item count
- Address autocomplete with pincode validation
- Slot picker (calendar + time grid)
- Status timeline component (stepper UI)
- OTP input component
- File upload with drag-drop (PDF only, 10MB max)
- Rating component (stars + comment)
- Notification toast system
- Loading skeletons for all async content

### UI/UX Requirements
- Mobile-first responsive design
- Accessibility: WCAG 2.1 AA compliance, keyboard navigation, screen reader support
- Color contrast ratio ≥ 4.5:1
- Loading states for all async operations
- Error boundaries with friendly messages
- Offline detection with graceful degradation
- Progressive Web App (PWA) with manifest and service worker

---

## BACKEND FUNCTIONALITY

### Core Services to Implement

1. **AuthService**
   - OTP generation and verification (mock mode for dev)
   - JWT token generation/validation
   - Role-based access control middleware

2. **SearchService**
   - Full-text search with PostgreSQL pg_trgm extension
   - Filter and sort logic
   - Redis caching for hot queries (TTL: 5 min)

3. **BookingService**
   - Slot availability validation
   - Booking creation with transaction safety
   - Status transition validation (state machine)
   - Timeline event generation

4. **AssignmentService**
   - Auto-assignment algorithm (nearest available phlebotomist)
   - Distance calculation (Haversine formula)
   - Capacity checking (max bookings per phleb)
   - Manual override support

5. **NotificationService**
   - Template-based message generation
   - Multi-channel delivery (mock SMS/WhatsApp for dev)
   - Retry logic with exponential backoff
   - Dead letter queue for failed notifications

6. **ReportService**
   - PDF upload with virus scan simulation
   - Token generation with expiry
   - Watermarking (use pdf-lib library)
   - Access tracking

7. **PaymentService**
   - Coupon validation and application
   - Price calculation with discounts
   - Payment status tracking (mock payments for dev)

8. **RatingService**
   - Rating submission with validation
   - Average rating calculation
   - Rating aggregation for labs/phlebs

### Background Jobs (Redis Queue)
- Auto-assignment worker (runs every 30 sec)
- Notification delivery worker
- SLA monitoring worker (checks for breaches)
- Report processing worker

---

## TESTING REQUIREMENTS

Include comprehensive tests:

1. **Unit Tests** (Jest/Vitest)
   - All services with >80% coverage
   - Utility functions
   - Validation logic

2. **Integration Tests**
   - API endpoints with supertest
   - Database operations with test DB
   - Authentication flows

3. **E2E Tests** (Playwright)
   - Patient booking flow
   - Phlebotomist job completion
   - Lab report upload
   - Admin assignment override

4. **Security Tests**
   - Authentication bypass attempts
   - IDOR (Insecure Direct Object Reference) checks
   - SQL injection attempts
   - XSS attempts

---

## DEPLOYMENT & LOCAL SETUP

Provide complete setup with:

1. **Docker Compose** configuration for:
   - PostgreSQL with initialization scripts
   - Redis
   - Backend API
   - Frontend (Next.js)
   - Nginx reverse proxy

2. **Environment Variables** template (`.env.example`)
   ```
   DATABASE_URL=postgresql://...
   REDIS_URL=redis://...
   JWT_SECRET=...
   JWT_EXPIRY=24h
   OTP_MOCK_MODE=true
   FILE_UPLOAD_PATH=./uploads
   CORS_ORIGINS=http://localhost:3000
   ```

3. **Setup Scripts**
   - Database migration script
   - Seed data script (sample labs, tests, users)
   - Development server startup

4. **Documentation**
   - README with setup instructions
   - API documentation (Swagger/OpenAPI)
   - Architecture diagram
   - Database ERD

---

## OBSERVABILITY

Implement:
- Structured JSON logging (Winston/Pino)
- Request correlation IDs
- Performance metrics (response times, error rates)
- Health check endpoints (`/health`, `/ready`)
- Error tracking setup (console logs for MVP, Sentry-ready structure)

---

## FEATURE FLAGS

Implement configuration for:
- `PAYMENTS_ENABLED` (default: false)
- `RATINGS_ENABLED` (default: true)
- `MULTI_LAB_BOOKING` (default: false)
- `WATERMARK_REPORTS` (default: true)
- `AUTO_ASSIGNMENT` (default: true)

---

## ACCEPTANCE CRITERIA

The delivered code must:
1. ✅ Run locally with `docker-compose up` and be fully functional
2. ✅ Complete patient flow: search → book → assign → collect → upload report → download
3. ✅ All API endpoints working with proper validation and error handling
4. ✅ Authentication working with OTP (mock mode)
5. ✅ Real-time status updates visible in UI
6. ✅ Report upload and secure download working
7. ✅ Phlebotomist auto-assignment working
8. ✅ Admin dashboard showing SLA metrics
9. ✅ All security requirements implemented
10. ✅ Responsive design working on mobile/desktop
11. ✅ Pass all test suites
12. ✅ Comprehensive documentation included

---

## CODE QUALITY STANDARDS

- TypeScript strict mode enabled
- ESLint + Prettier configured
- Meaningful variable/function names
- Comprehensive error handling (no unhandled promise rejections)
- Input validation on all endpoints
- SQL queries using ORM (TypeORM/Prisma) or parameterized queries
- No hardcoded credentials or secrets
- Comments explaining complex business logic
- Modular, maintainable code structure

---

## DELIVERABLES

Provide a complete, working codebase with:
1. Full-stack application (Frontend + Backend)
2. Docker Compose setup
3. Database migrations and seed data
4. All API endpoints implemented
5. All frontend pages and components
6. Test suites (unit + integration + E2E)
7. README with setup and run instructions
8. API documentation
9. Architecture and database diagrams
10. Sample .env file

**Build this as production-ready code that can be deployed to AWS with minimal changes.** Focus on security, scalability, and maintainability.