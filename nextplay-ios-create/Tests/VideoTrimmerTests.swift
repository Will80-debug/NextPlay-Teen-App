//
//  VideoTrimmerTests.swift
//  NextPlayTests
//
//  Unit tests for video trimming and duration enforcement
//

import XCTest
import AVFoundation
@testable import NextPlay

class VideoTrimmerTests: XCTestCase {
    
    var testVideoURL: URL!
    var testAsset: AVAsset!
    
    override func setUpWithError() throws {
        // Create a test video URL
        // In a real project, you'd have a test video file
        testVideoURL = Bundle.main.url(forResource: "test_video", withExtension: "mp4")
        XCTAssertNotNil(testVideoURL, "Test video not found")
        
        testAsset = AVAsset(url: testVideoURL)
    }
    
    override func tearDownWithError() throws {
        testVideoURL = nil
        testAsset = nil
    }
    
    // MARK: - Duration Tests
    
    func testGetDuration() async throws {
        let duration = try await VideoTrimmer.getDuration(testAsset)
        XCTAssertGreaterThan(duration, 0, "Duration should be greater than 0")
    }
    
    func testNeedsTrimming_ShortVideo() async throws {
        // Assume test video is 15 seconds
        let needsTrim = await VideoTrimmer.needsTrimming(testAsset)
        XCTAssertFalse(needsTrim, "Short video should not need trimming")
    }
    
    func testMaxDurationEnforcement() {
        XCTAssertEqual(VideoTrimmer.maxDuration, 30.0, "Max duration should be 30 seconds")
    }
    
    // MARK: - Trimming Tests
    
    func testTrimVideo_ValidRange() async throws {
        let duration = try await VideoTrimmer.getDuration(testAsset)
        let startTime = 0.0
        let endTime = min(duration, 10.0)
        
        let trimmedURL = try await VideoTrimmer.trimVideo(
            asset: testAsset,
            startTime: startTime,
            endTime: endTime
        )
        
        XCTAssertNotNil(trimmedURL, "Trimmed video URL should not be nil")
        XCTAssertTrue(FileManager.default.fileExists(atPath: trimmedURL.path), 
                     "Trimmed video file should exist")
        
        // Verify trimmed duration
        let trimmedAsset = AVAsset(url: trimmedURL)
        let trimmedDuration = try await VideoTrimmer.getDuration(trimmedAsset)
        XCTAssertEqual(trimmedDuration, endTime - startTime, accuracy: 0.1,
                      "Trimmed duration should match requested range")
    }
    
    func testTrimVideo_ExceedsMaxDuration() async {
        do {
            _ = try await VideoTrimmer.trimVideo(
                asset: testAsset,
                startTime: 0,
                endTime: 35.0  // Exceeds max
            )
            XCTFail("Should throw error for duration exceeding limit")
        } catch VideoTrimmer.TrimError.durationExceedsLimit {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTrimVideo_InvalidTimeRange() async {
        do {
            _ = try await VideoTrimmer.trimVideo(
                asset: testAsset,
                startTime: 10.0,
                endTime: 5.0  // End before start
            )
            XCTFail("Should throw error for invalid time range")
        } catch VideoTrimmer.TrimError.invalidTimeRange {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTrimVideo_NegativeStartTime() async {
        do {
            _ = try await VideoTrimmer.trimVideo(
                asset: testAsset,
                startTime: -5.0,  // Negative
                endTime: 10.0
            )
            XCTFail("Should throw error for negative start time")
        } catch VideoTrimmer.TrimError.invalidTimeRange {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Thumbnail Tests
    
    func testGenerateThumbnail() async throws {
        let thumbnail = try await VideoTrimmer.generateThumbnail(from: testAsset, at: 0)
        XCTAssertNotNil(thumbnail, "Thumbnail should not be nil")
        XCTAssertGreaterThan(thumbnail.size.width, 0, "Thumbnail width should be greater than 0")
        XCTAssertGreaterThan(thumbnail.size.height, 0, "Thumbnail height should be greater than 0")
    }
    
    func testGenerateThumbnails_MultipleFrames() async throws {
        let count = 10
        let thumbnails = try await VideoTrimmer.generateThumbnails(from: testAsset, count: count)
        
        XCTAssertEqual(thumbnails.count, count, "Should generate requested number of thumbnails")
        
        for thumbnail in thumbnails {
            XCTAssertGreaterThan(thumbnail.size.width, 0)
            XCTAssertGreaterThan(thumbnail.size.height, 0)
        }
    }
    
    // MARK: - Video Information Tests
    
    func testGetResolution() async throws {
        let resolution = try await VideoTrimmer.getResolution(testAsset)
        
        XCTAssertGreaterThan(resolution.width, 0, "Resolution width should be greater than 0")
        XCTAssertGreaterThan(resolution.height, 0, "Resolution height should be greater than 0")
    }
    
    func testGetFileSize() {
        let fileSize = VideoTrimmer.getFileSize(testVideoURL)
        XCTAssertGreaterThan(fileSize, 0, "File size should be greater than 0 MB")
    }
    
    // MARK: - Preview Generation Tests
    
    func testGeneratePreview() async throws {
        let previewURL = try await VideoTrimmer.generatePreview(from: testAsset, duration: 3.0)
        
        XCTAssertNotNil(previewURL, "Preview URL should not be nil")
        XCTAssertTrue(FileManager.default.fileExists(atPath: previewURL.path),
                     "Preview file should exist")
        
        // Verify preview duration
        let previewAsset = AVAsset(url: previewURL)
        let previewDuration = try await VideoTrimmer.getDuration(previewAsset)
        XCTAssertLessThanOrEqual(previewDuration, 3.0, "Preview should not exceed requested duration")
    }
    
    // MARK: - Performance Tests
    
    func testTrimPerformance() {
        measure {
            let expectation = self.expectation(description: "Trim video")
            
            Task {
                do {
                    _ = try await VideoTrimmer.trimVideo(
                        asset: testAsset,
                        startTime: 0,
                        endTime: 10
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Trim failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            waitForExpectations(timeout: 10)
        }
    }
    
    func testThumbnailGenerationPerformance() {
        measure {
            let expectation = self.expectation(description: "Generate thumbnails")
            
            Task {
                do {
                    _ = try await VideoTrimmer.generateThumbnails(from: testAsset, count: 10)
                    expectation.fulfill()
                } catch {
                    XCTFail("Thumbnail generation failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            waitForExpectations(timeout: 5)
        }
    }
    
    // MARK: - Edge Cases
    
    func testTrimVideo_ExactlyMaxDuration() async throws {
        let duration = try await VideoTrimmer.getDuration(testAsset)
        
        if duration >= 30.0 {
            let trimmedURL = try await VideoTrimmer.trimVideo(
                asset: testAsset,
                startTime: 0,
                endTime: 30.0  // Exactly max
            )
            
            let trimmedDuration = try await VideoTrimmer.getDuration(AVAsset(url: trimmedURL))
            XCTAssertLessThanOrEqual(trimmedDuration, 30.0, 
                                    "Trimmed duration should not exceed max")
        }
    }
    
    func testTrimVideo_VeryShortClip() async throws {
        // Test 0.1 second clip
        let trimmedURL = try await VideoTrimmer.trimVideo(
            asset: testAsset,
            startTime: 0,
            endTime: 0.1
        )
        
        XCTAssertNotNil(trimmedURL, "Should be able to trim very short clip")
    }
}
