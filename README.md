# WaxChromatics

A vinyl record collection and trading platform built with Rails. Import your Discogs collection, discover music connections between artists, and trade records with other collectors.

## Tech Stack

- **Backend:** Ruby 3.3.5 / Rails 8.1 / PostgreSQL
- **Frontend:** Stimulus JS, Turbo, Tailwind CSS
- **Jobs:** Solid Queue (with dedicated `music_brainz` queue for rate-limited API calls)
- **Caching:** Solid Cache
- **Real-time:** ActionCable (trade messages, shipment updates)
- **Audit:** Paper Trail (collection and trade history)

## Key Features

### Record Ingestion

Search Discogs via an external Wax API microservice. Importing an artist kicks off a multi-step job pipeline:

1. **IngestArtistJob** — fetches and upserts the artist profile
2. **IngestArtistDiscographyJob** — paginates through master releases, creates `ReleaseGroup` records
3. **IngestMasterReleasesJob** — fetches vinyl-only releases for each master
4. **IngestReleaseJob** — full release ingestion (tracks, formats, labels, identifiers, genres, styles, contributors)
5. **FetchReleaseCoverArtJob / FetchReleaseGroupCoverArtJob** — queries MusicBrainz + Cover Art Archive for artwork

All jobs retry with exponential backoff (30s, 60s, 120s, 240s). MusicBrainz calls are rate-limited to 1 request per 1.2 seconds.

### Collection Management

- Add releases to your collection with condition grading (M through P)
- Track purchase price, date, sale info, and notes per item
- Mark items as available for trade via your trade list
- Maintain a wantlist of releases you're looking for
- All changes are audited via Paper Trail

### CSV Import

Upload a Discogs collection export CSV. The system:
1. Parses rows in batches of 500
2. Matches against local DB first (by discogs_id or artist+title+catalog)
3. Falls back to fetching from Discogs if not found locally
4. Polls with retry logic until ingestion completes
5. Maps Discogs condition strings to app format
6. Tracks progress with per-row status (completed/failed/retryable)

### Trading System

Full trade lifecycle between two collectors:

**States:** `draft` → `proposed` → `accepted` → `delivered` (with `declined` / `cancelled` branches)

- **Trade Finder** — recommendation engine that matches your trade list against other users' wantlists and vice versa. Scores matches as mutual (both sides benefit), they_have, or they_want
- **Messages** — real-time chat per trade via ActionCable (2000 char limit)
- **Shipments** — per-user tracking with carrier, tracking number, and status (pending → shipped → in_transit → delivered). Trade auto-transitions to delivered when both shipments arrive
- **Ratings** — post-delivery feedback covering overall quality, communication, packing (1-5), condition accuracy, and optional tags (fast_shipper, great_packing, etc.). Both parties must rate before scores are visible (or 7 days must pass)

### Artist Connections

A BFS-based path finder that discovers how two artists are connected through release collaborations. Searches up to 6 degrees of separation, returning the shortest path with release and role details.

### Browse & Discovery

- **Artists** — alphabetical browse with pagination, primary/all artist filter
- **Releases** — grid/list view with filters for label, genre, format, decade, country, and colored vinyl
- **Search** — local artist search with lazy-loaded external Discogs results and one-click import

### User Profiles

- Public profile with collection stats and charts (format breakdown, condition distribution, top artists/labels/genres, vinyl colors, decade distribution)
- Privacy settings (private profile, show/hide location)
- Theme selection (ember, slate, moss)
- Trade preferences (accept requests, require messages, auto-decline days)

### Admin

- **Job Metrics** (`/jobs/metrics`) — dashboard with processed/in-progress/queued/failed counts, per-queue line charts over configurable time ranges (1h, 24h, 7d, 30d)

## Data Model

The core domain centers on a few key relationships:

- **Artist** → has many **ReleaseGroups** (master albums) → each has many **Releases** (vinyl variants)
- **Release** → has **Tracks**, **ReleaseFormats** (color, size), **ReleaseLabels**, **ReleaseIdentifiers**, **ReleaseGenres**, **ReleaseStyles**, **ReleaseContributors**
- **User** → has **Collections** → containing **CollectionItems** (a release + condition + price)
- **User** → has **WantlistItems** and **TradeListItems** (derived from collection items)
- **Trade** → links two users with **TradeItems**, **TradeMessages**, **TradeShipments**, and **Ratings**

## External Services

| Service | Purpose |
|---------|---------|
| **Wax API** (custom microservice) | Discogs data proxy — artist search, discography, release details |
| **MusicBrainz** | MBID lookup from Discogs URLs, release search fallback |
| **Cover Art Archive** | Album artwork (1200px thumbnails) |

## Setup

```sh
bin/setup
bin/dev
```

Requires the Wax API microservice running (defaults to `localhost:3030`, configurable via `WAX_API_BASE_URL`).

## Database

PostgreSQL with separate databases for the primary app, Solid Cache, Solid Queue, and ActionCable. Run migrations with:

```sh
bin/rails db:prepare
```
