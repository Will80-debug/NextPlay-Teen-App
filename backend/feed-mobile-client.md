# NextPlay "For You" Feed - Mobile Client Implementation

## Overview
This document defines the mobile client behavior for NextPlay's vertical scrolling "For You" feed, optimized for smooth playback, aggressive caching, and minimal latency.

**Target Performance:**
- **Scroll Smoothness**: 60 FPS (16.67ms per frame)
- **Video Start Time**: < 200ms from scroll stop
- **Cache Hit Rate**: > 85% for prefetched content
- **Memory Footprint**: < 150MB for video cache
- **Network Efficiency**: < 10MB/min average bandwidth

---

## 1. Rolling Window Management

### 1.1 Window Configuration
```javascript
const FEED_WINDOW_CONFIG = {
  prefetchAhead: 5,      // Items ahead of current position
  keepBehind: 2,         // Items behind current position
  totalWindow: 8,        // 2 behind + 1 current + 5 ahead
  preloadThreshold: 2,   // Start loading when 2 items from edge
  cleanupInterval: 5000  // Clean up every 5 seconds
};
```

### 1.2 Window State Machine
```
Current Index: i

Evict Zone    |  Cache Window  |  Prefetch Zone
    ...       | i-2, i-1, [i], i+1, i+2, i+3, i+4, i+5 | i+6, i+7...
              |<------- Active Window (8 items) ------->|

Actions:
- When scrolling UP (i → i-1):
  - Evict: i+5
  - Prefetch: i-3 (if not cached)
  
- When scrolling DOWN (i → i+1):
  - Evict: i-2
  - Prefetch: i+6
```

### 1.3 Scroll Direction Detection
```javascript
class ScrollDirectionDetector {
  constructor() {
    this.lastIndex = 0;
    this.direction = 'IDLE'; // 'UP' | 'DOWN' | 'IDLE'
    this.velocity = 0;
  }

  update(currentIndex) {
    const delta = currentIndex - this.lastIndex;
    
    if (delta > 0) {
      this.direction = 'DOWN';
      this.velocity = delta;
    } else if (delta < 0) {
      this.direction = 'UP';
      this.velocity = Math.abs(delta);
    } else {
      this.direction = 'IDLE';
      this.velocity = 0;
    }
    
    this.lastIndex = currentIndex;
    return { direction: this.direction, velocity: this.velocity };
  }
}
```

---

## 2. Prefetch Strategy

### 2.1 Three-Phase Prefetch Pipeline

```
Phase 1: METADATA     → Phase 2: THUMBNAIL    → Phase 3: VIDEO
(Immediate)             (Within 500ms)          (Within 1s)

Feed Item
└─ video_id
└─ creator info
└─ caption
└─ thumbnail_url  ──────►  Prefetch Image
└─ playback_urls ──────────────────────►  Prebuffer Video
```

### 2.2 Prefetch Algorithm (React/JavaScript)

```javascript
class FeedPrefetcher {
  constructor(feedItems, currentIndex) {
    this.feedItems = feedItems;
    this.currentIndex = currentIndex;
    this.metadataCache = new Map();
    this.thumbnailCache = new Map();
    this.videoCache = new Map();
  }

  /**
   * Step 1: Determine prefetch range based on current position
   */
  getPrefetchRange(direction = 'DOWN') {
    const { prefetchAhead, keepBehind } = FEED_WINDOW_CONFIG;
    
    const start = Math.max(0, this.currentIndex - keepBehind);
    const end = Math.min(
      this.feedItems.length - 1,
      this.currentIndex + prefetchAhead
    );
    
    return { start, end };
  }

  /**
   * Step 2: Prefetch metadata (already in feed response)
   */
  prefetchMetadata(index) {
    const item = this.feedItems[index];
    if (!item || this.metadataCache.has(index)) return;
    
    // Metadata is already loaded from feed API
    this.metadataCache.set(index, {
      video_id: item.video_id,
      creator: item.creator,
      title: item.title,
      caption: item.caption,
      counts: item.counts,
      timestamp: Date.now()
    });
  }

  /**
   * Step 3: Prefetch thumbnail (Image preload)
   */
  async prefetchThumbnail(index) {
    const item = this.feedItems[index];
    if (!item || this.thumbnailCache.has(index)) return;
    
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        this.thumbnailCache.set(index, {
          url: item.thumbnail_url,
          blob: null, // Browser handles image cache
          timestamp: Date.now()
        });
        resolve();
      };
      img.onerror = reject;
      img.src = item.thumbnail_url;
    });
  }

  /**
   * Step 4: Prebuffer video (Priority based on distance)
   */
  async prebufferVideo(index, priority = 'normal') {
    const item = this.feedItems[index];
    if (!item || this.videoCache.has(index)) return;

    const quality = this.selectQuality(); // 720p, 480p, 360p
    const videoUrl = item.playback[quality];

    try {
      // Method A: Use <video> element preload
      const video = document.createElement('video');
      video.preload = priority === 'high' ? 'auto' : 'metadata';
      video.src = videoUrl;
      video.load();

      // Store in cache
      this.videoCache.set(index, {
        video_id: item.video_id,
        quality: quality,
        element: video,
        url: videoUrl,
        buffered: false,
        timestamp: Date.now()
      });

      // Wait for sufficient buffering
      await this.waitForBuffer(video, priority);
      
      this.videoCache.get(index).buffered = true;

    } catch (error) {
      console.error(`Failed to prebuffer video ${index}:`, error);
    }
  }

  /**
   * Wait for video to buffer enough data
   */
  waitForBuffer(video, priority) {
    return new Promise((resolve) => {
      const targetBuffer = priority === 'high' ? 3 : 1; // seconds
      
      const checkBuffer = () => {
        if (video.buffered.length > 0) {
          const buffered = video.buffered.end(0) - video.buffered.start(0);
          if (buffered >= targetBuffer) {
            resolve();
            return;
          }
        }
        setTimeout(checkBuffer, 100);
      };
      
      video.addEventListener('canplay', resolve, { once: true });
      checkBuffer();
    });
  }

  /**
   * Step 5: Execute full prefetch cycle
   */
  async executePrefetch(currentIndex, direction) {
    this.currentIndex = currentIndex;
    const { start, end } = this.getPrefetchRange(direction);

    // Priority queue: current +1, +2 (high), +3, +4, +5 (normal)
    const highPriority = [currentIndex + 1, currentIndex + 2];
    const normalPriority = [];

    for (let i = start; i <= end; i++) {
      if (i === currentIndex) continue; // Already playing
      
      // Phase 1: Metadata (instant)
      this.prefetchMetadata(i);
      
      // Phase 2: Thumbnail (parallel)
      this.prefetchThumbnail(i).catch(err => 
        console.warn(`Thumbnail prefetch failed for ${i}:`, err)
      );
      
      // Phase 3: Video (prioritized)
      if (highPriority.includes(i)) {
        this.prebufferVideo(i, 'high');
      } else {
        normalPriority.push(i);
      }
    }

    // Prefetch normal priority videos sequentially
    for (const idx of normalPriority) {
      await this.prebufferVideo(idx, 'normal');
    }
  }

  /**
   * Step 6: Cleanup items outside window
   */
  cleanup() {
    const { start, end } = this.getPrefetchRange();

    // Evict thumbnails
    for (const [index] of this.thumbnailCache) {
      if (index < start || index > end) {
        this.thumbnailCache.delete(index);
      }
    }

    // Evict videos (more aggressive)
    for (const [index, cache] of this.videoCache) {
      if (index < start || index > end) {
        if (cache.element) {
          cache.element.src = ''; // Release video memory
          cache.element.load();
        }
        this.videoCache.delete(index);
      }
    }
  }

  /**
   * Select video quality based on network and device
   */
  selectQuality() {
    // Check network connection
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
    
    if (connection) {
      const effectiveType = connection.effectiveType;
      
      if (effectiveType === '4g' || effectiveType === 'wifi') {
        return '720p';
      } else if (effectiveType === '3g') {
        return '480p';
      } else {
        return '360p';
      }
    }

    // Default to 720p
    return '720p';
  }
}
```

### 2.3 Adaptive Quality Selection

```javascript
class AdaptiveQualityManager {
  constructor() {
    this.currentQuality = '720p';
    this.stallCount = 0;
    this.lastAdjustment = Date.now();
  }

  /**
   * Downgrade quality on stall
   */
  onVideoStall() {
    this.stallCount++;
    
    if (this.stallCount >= 2 && Date.now() - this.lastAdjustment > 10000) {
      if (this.currentQuality === '720p') {
        this.currentQuality = '480p';
      } else if (this.currentQuality === '480p') {
        this.currentQuality = '360p';
      }
      
      this.lastAdjustment = Date.now();
      this.stallCount = 0;
      
      console.log(`Quality downgraded to ${this.currentQuality}`);
    }
  }

  /**
   * Upgrade quality on smooth playback
   */
  onSmoothPlayback() {
    this.stallCount = 0;
    
    // Attempt upgrade after 30s of smooth playback
    if (Date.now() - this.lastAdjustment > 30000) {
      if (this.currentQuality === '360p') {
        this.currentQuality = '480p';
      } else if (this.currentQuality === '480p') {
        this.currentQuality = '720p';
      }
      
      this.lastAdjustment = Date.now();
      console.log(`Quality upgraded to ${this.currentQuality}`);
    }
  }

  getQuality() {
    return this.currentQuality;
  }
}
```

---

## 3. Disk & Memory Caching

### 3.1 Cache Architecture

```
┌─────────────────────────────────────┐
│  Memory Cache (LRU)                  │  Hot: ~50MB
│  - Current video                     │  Evict after 5 min
│  - Next 2 videos                     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Disk Cache (IndexedDB)              │  Warm: ~500MB
│  - Last 20 viewed videos             │  Evict after 24h
│  - Prefetched videos (window)        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  CDN Cache                           │  Cold: ∞
│  - All published videos              │  CDN TTL: 7 days
└─────────────────────────────────────┘
```

### 3.2 IndexedDB Schema

```javascript
// Database: nextplay-video-cache
// Version: 1

const dbSchema = {
  stores: {
    videos: {
      keyPath: 'video_id',
      indexes: [
        { name: 'timestamp', keyPath: 'timestamp' },
        { name: 'quality', keyPath: 'quality' }
      ]
    },
    thumbnails: {
      keyPath: 'video_id',
      indexes: [
        { name: 'timestamp', keyPath: 'timestamp' }
      ]
    }
  }
};

// Video Cache Entry
interface VideoCacheEntry {
  video_id: string;
  quality: '720p' | '480p' | '360p';
  blob: Blob;              // Video file blob
  url: string;             // Original URL
  size: number;            // Bytes
  timestamp: number;       // Unix timestamp
  duration: number;        // Video duration (ms)
  access_count: number;    // Number of times accessed
  last_accessed: number;   // Last access timestamp
}

// Thumbnail Cache Entry
interface ThumbnailCacheEntry {
  video_id: string;
  blob: Blob;
  url: string;
  size: number;
  timestamp: number;
}
```

### 3.3 Cache Manager Implementation

```javascript
class VideoCacheManager {
  constructor() {
    this.db = null;
    this.memoryCache = new LRUCache(50 * 1024 * 1024); // 50MB
    this.maxDiskSize = 500 * 1024 * 1024; // 500MB
    this.initDB();
  }

  /**
   * Initialize IndexedDB
   */
  async initDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('nextplay-video-cache', 1);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };
      
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        
        // Create videos store
        const videoStore = db.createObjectStore('videos', { keyPath: 'video_id' });
        videoStore.createIndex('timestamp', 'timestamp', { unique: false });
        videoStore.createIndex('quality', 'quality', { unique: false });
        
        // Create thumbnails store
        const thumbStore = db.createObjectStore('thumbnails', { keyPath: 'video_id' });
        thumbStore.createIndex('timestamp', 'timestamp', { unique: false });
      };
    });
  }

  /**
   * Save video to disk cache
   */
  async saveVideo(video_id, quality, blob, url) {
    const entry = {
      video_id,
      quality,
      blob,
      url,
      size: blob.size,
      timestamp: Date.now(),
      duration: 30000, // Assume 30s max
      access_count: 0,
      last_accessed: Date.now()
    };

    // Check disk quota
    await this.enforceQuota(blob.size);

    // Save to IndexedDB
    const transaction = this.db.transaction(['videos'], 'readwrite');
    const store = transaction.objectStore('videos');
    await store.put(entry);

    console.log(`Cached video ${video_id} (${quality}) - ${(blob.size / 1024 / 1024).toFixed(2)}MB`);
  }

  /**
   * Retrieve video from disk cache
   */
  async getVideo(video_id, quality) {
    // Check memory cache first
    const memKey = `${video_id}:${quality}`;
    const memCached = this.memoryCache.get(memKey);
    if (memCached) {
      console.log(`Memory cache HIT: ${video_id}`);
      return memCached;
    }

    // Check disk cache
    const transaction = this.db.transaction(['videos'], 'readwrite');
    const store = transaction.objectStore('videos');
    const request = store.get(video_id);

    return new Promise((resolve, reject) => {
      request.onsuccess = () => {
        const entry = request.result;
        if (entry && entry.quality === quality) {
          // Update access stats
          entry.access_count++;
          entry.last_accessed = Date.now();
          store.put(entry);

          // Promote to memory cache
          this.memoryCache.set(memKey, entry.blob);

          console.log(`Disk cache HIT: ${video_id}`);
          resolve(entry.blob);
        } else {
          console.log(`Cache MISS: ${video_id}`);
          resolve(null);
        }
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Enforce disk quota by evicting old entries
   */
  async enforceQuota(newSize) {
    const currentSize = await this.getTotalCacheSize();
    
    if (currentSize + newSize > this.maxDiskSize) {
      console.log(`Quota exceeded: ${(currentSize / 1024 / 1024).toFixed(2)}MB, evicting...`);
      
      // Get all videos sorted by last_accessed (oldest first)
      const videos = await this.getAllVideos();
      videos.sort((a, b) => a.last_accessed - b.last_accessed);

      let freedSpace = 0;
      const toDelete = [];

      for (const video of videos) {
        toDelete.push(video.video_id);
        freedSpace += video.size;
        
        if (currentSize - freedSpace + newSize <= this.maxDiskSize) {
          break;
        }
      }

      // Delete old entries
      for (const video_id of toDelete) {
        await this.deleteVideo(video_id);
      }

      console.log(`Evicted ${toDelete.length} videos, freed ${(freedSpace / 1024 / 1024).toFixed(2)}MB`);
    }
  }

  /**
   * Get total cache size
   */
  async getTotalCacheSize() {
    const videos = await this.getAllVideos();
    return videos.reduce((sum, v) => sum + v.size, 0);
  }

  /**
   * Get all cached videos
   */
  async getAllVideos() {
    const transaction = this.db.transaction(['videos'], 'readonly');
    const store = transaction.objectStore('videos');
    const request = store.getAll();

    return new Promise((resolve, reject) => {
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Delete video from cache
   */
  async deleteVideo(video_id) {
    const transaction = this.db.transaction(['videos'], 'readwrite');
    const store = transaction.objectStore('videos');
    await store.delete(video_id);
  }

  /**
   * Clear entire cache (for debugging)
   */
  async clearCache() {
    const transaction = this.db.transaction(['videos', 'thumbnails'], 'readwrite');
    await transaction.objectStore('videos').clear();
    await transaction.objectStore('thumbnails').clear();
    this.memoryCache.clear();
    console.log('Cache cleared');
  }
}

/**
 * Simple LRU Cache for memory
 */
class LRUCache {
  constructor(maxSize) {
    this.maxSize = maxSize;
    this.cache = new Map();
    this.currentSize = 0;
  }

  set(key, value) {
    // Estimate size (rough)
    const size = value.size || value.byteLength || 0;
    
    if (size > this.maxSize) {
      console.warn('Item too large for memory cache');
      return;
    }

    // Evict if necessary
    while (this.currentSize + size > this.maxSize && this.cache.size > 0) {
      const firstKey = this.cache.keys().next().value;
      const firstValue = this.cache.get(firstKey);
      this.currentSize -= (firstValue.size || firstValue.byteLength || 0);
      this.cache.delete(firstKey);
    }

    this.cache.set(key, value);
    this.currentSize += size;
  }

  get(key) {
    if (!this.cache.has(key)) return null;
    
    // Move to end (most recently used)
    const value = this.cache.get(key);
    this.cache.delete(key);
    this.cache.set(key, value);
    
    return value;
  }

  clear() {
    this.cache.clear();
    this.currentSize = 0;
  }
}
```

---

## 4. Feed Integration (React Component)

```jsx
// FeedScreen.jsx
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { FeedPrefetcher } from '../services/feedPrefetcher';
import { VideoCacheManager } from '../services/videoCacheManager';
import { AdaptiveQualityManager } from '../services/adaptiveQualityManager';

const FeedScreen = () => {
  const [feedItems, setFeedItems] = useState([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [loading, setLoading] = useState(false);
  const [cursor, setCursor] = useState(null);
  
  const prefetcherRef = useRef(null);
  const cacheManagerRef = useRef(null);
  const qualityManagerRef = useRef(null);

  useEffect(() => {
    // Initialize managers
    cacheManagerRef.current = new VideoCacheManager();
    qualityManagerRef.current = new AdaptiveQualityManager();
    
    // Load initial feed
    loadFeed();
  }, []);

  useEffect(() => {
    if (feedItems.length > 0 && !prefetcherRef.current) {
      prefetcherRef.current = new FeedPrefetcher(feedItems, currentIndex);
    }
  }, [feedItems]);

  /**
   * Load feed from API
   */
  const loadFeed = async (nextCursor = null) => {
    if (loading) return;
    
    setLoading(true);
    try {
      const params = new URLSearchParams({
        limit: 20,
        ...(nextCursor && { cursor: nextCursor })
      });

      const response = await fetch(`/v1/feed?${params}`, {
        headers: {
          'Authorization': `Bearer ${getAuthToken()}`
        }
      });

      const data = await response.json();
      
      setFeedItems(prev => [...prev, ...data.items]);
      setCursor(data.pagination.next_cursor);
      
      // Update prefetcher with new items
      if (prefetcherRef.current) {
        prefetcherRef.current.feedItems = [...feedItems, ...data.items];
      }

    } catch (error) {
      console.error('Failed to load feed:', error);
    } finally {
      setLoading(false);
    }
  };

  /**
   * Handle scroll to next video
   */
  const handleScroll = useCallback((newIndex) => {
    setCurrentIndex(newIndex);
    
    // Prefetch ahead
    if (prefetcherRef.current) {
      prefetcherRef.current.executePrefetch(newIndex, newIndex > currentIndex ? 'DOWN' : 'UP');
    }

    // Load more when approaching end
    if (newIndex >= feedItems.length - 5 && cursor && !loading) {
      loadFeed(cursor);
    }

    // Cleanup old items
    if (newIndex % 10 === 0) {
      prefetcherRef.current?.cleanup();
    }
  }, [currentIndex, feedItems.length, cursor, loading]);

  /**
   * Handle video stall
   */
  const handleVideoStall = useCallback(() => {
    qualityManagerRef.current?.onVideoStall();
  }, []);

  /**
   * Handle smooth playback
   */
  const handleSmoothPlayback = useCallback(() => {
    qualityManagerRef.current?.onSmoothPlayback();
  }, []);

  return (
    <div className="feed-container">
      <VerticalVideoScroller
        items={feedItems}
        currentIndex={currentIndex}
        onIndexChange={handleScroll}
        onVideoStall={handleVideoStall}
        onSmoothPlayback={handleSmoothPlayback}
        cacheManager={cacheManagerRef.current}
      />
    </div>
  );
};

export default FeedScreen;
```

---

## 5. Performance Monitoring

### 5.1 Key Metrics

```javascript
class FeedPerformanceMonitor {
  constructor() {
    this.metrics = {
      scrollFPS: [],
      videoStartTime: [],
      cacheHitRate: { hits: 0, misses: 0 },
      networkBandwidth: [],
      memoryUsage: []
    };
  }

  /**
   * Track scroll FPS
   */
  trackScrollFPS(fps) {
    this.metrics.scrollFPS.push({ fps, timestamp: Date.now() });
    
    if (fps < 50) {
      console.warn(`Low FPS detected: ${fps.toFixed(2)}`);
    }
  }

  /**
   * Track video start time (time to first frame)
   */
  trackVideoStartTime(duration) {
    this.metrics.videoStartTime.push({ duration, timestamp: Date.now() });
    
    const avg = this.metrics.videoStartTime
      .slice(-10)
      .reduce((sum, m) => sum + m.duration, 0) / 10;
    
    console.log(`Avg video start time (last 10): ${avg.toFixed(0)}ms`);
  }

  /**
   * Track cache hit/miss
   */
  trackCacheHit(hit) {
    if (hit) {
      this.metrics.cacheHitRate.hits++;
    } else {
      this.metrics.cacheHitRate.misses++;
    }
    
    const total = this.metrics.cacheHitRate.hits + this.metrics.cacheHitRate.misses;
    const rate = (this.metrics.cacheHitRate.hits / total) * 100;
    
    console.log(`Cache hit rate: ${rate.toFixed(1)}% (${this.metrics.cacheHitRate.hits}/${total})`);
  }

  /**
   * Get performance report
   */
  getReport() {
    const avgFPS = this.metrics.scrollFPS.length > 0
      ? this.metrics.scrollFPS.reduce((sum, m) => sum + m.fps, 0) / this.metrics.scrollFPS.length
      : 0;

    const avgStartTime = this.metrics.videoStartTime.length > 0
      ? this.metrics.videoStartTime.reduce((sum, m) => sum + m.duration, 0) / this.metrics.videoStartTime.length
      : 0;

    const total = this.metrics.cacheHitRate.hits + this.metrics.cacheHitRate.misses;
    const cacheHitRate = total > 0
      ? (this.metrics.cacheHitRate.hits / total) * 100
      : 0;

    return {
      avgScrollFPS: avgFPS.toFixed(2),
      avgVideoStartTime: avgStartTime.toFixed(0) + 'ms',
      cacheHitRate: cacheHitRate.toFixed(1) + '%',
      totalCacheRequests: total
    };
  }
}
```

---

## 6. Summary

### Mobile Client Responsibilities

1. **Rolling Window Management**
   - Maintain 8-item window (2 behind, 1 current, 5 ahead)
   - Evict items outside window every 5s
   - Detect scroll direction and velocity

2. **Three-Phase Prefetch**
   - Phase 1: Metadata (instant, from feed API)
   - Phase 2: Thumbnails (within 500ms, Image preload)
   - Phase 3: Videos (within 1s, prioritized by distance)

3. **Adaptive Quality**
   - Start with 720p on 4G/WiFi
   - Downgrade to 480p/360p on stalls (after 2 stalls)
   - Upgrade after 30s of smooth playback

4. **Multi-Layer Caching**
   - Memory: LRU cache, 50MB, current + next 2 videos
   - Disk: IndexedDB, 500MB, last 20 videos + window
   - Network: CDN, signed URLs, 7-day TTL

5. **Performance Targets**
   - 60 FPS scroll (16.67ms/frame)
   - < 200ms video start time
   - > 85% cache hit rate
   - < 150MB memory footprint

### Example Flow

```
User scrolls from video[10] → video[11]

1. Detect scroll direction: DOWN, velocity: 1
2. Update window: [9, 10, [11], 12, 13, 14, 15, 16]
3. Evict video[8] from cache
4. Prefetch video[17]:
   - Metadata: already loaded
   - Thumbnail: fetch via Image()
   - Video (480p): prebuffer via <video preload>
5. Play video[11] from cache (hit rate: 92%)
6. Monitor playback: smooth → track FPS (58.2), start time (145ms)
```

---

## Next Steps
1. **Implement React components** (FeedScreen, VerticalVideoScroller)
2. **Test on real devices** (iOS Safari, Android Chrome)
3. **Tune prefetch thresholds** based on metrics
4. **Add error recovery** (network failures, disk quota)
5. **Integrate with backend** (feed API, CDN signed URLs)

**Status**: ✅ Mobile Client Specification Complete
