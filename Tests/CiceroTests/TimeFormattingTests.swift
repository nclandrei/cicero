import Testing
@testable import Shared
import Foundation

@Suite("TimeFormatting")
struct TimeFormattingTests {

    // MARK: - Elapsed Time

    @Test("Zero seconds formats as 0:00")
    func elapsedZero() {
        #expect(TimeFormatting.elapsedTime(seconds: 0) == "0:00")
    }

    @Test("Single digit seconds are zero-padded")
    func elapsedSingleDigitSeconds() {
        #expect(TimeFormatting.elapsedTime(seconds: 5) == "0:05")
    }

    @Test("90 seconds formats as 1:30")
    func elapsedNinetySeconds() {
        #expect(TimeFormatting.elapsedTime(seconds: 90) == "1:30")
    }

    @Test("605 seconds formats as 10:05")
    func elapsedTenMinutesFiveSeconds() {
        #expect(TimeFormatting.elapsedTime(seconds: 605) == "10:05")
    }

    @Test("59 seconds formats as 0:59")
    func elapsedFiftyNineSeconds() {
        #expect(TimeFormatting.elapsedTime(seconds: 59) == "0:59")
    }

    @Test("60 seconds formats as 1:00")
    func elapsedOneMinute() {
        #expect(TimeFormatting.elapsedTime(seconds: 60) == "1:00")
    }

    @Test("3661 seconds formats as 61:01")
    func elapsedOverOneHour() {
        #expect(TimeFormatting.elapsedTime(seconds: 3661) == "61:01")
    }

    // MARK: - Wall Clock

    @Test("Wall clock formats date correctly")
    func wallClockFormatting() {
        // Create a known date: 14:05
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let components = DateComponents(hour: 14, minute: 5)
        let date = cal.date(from: components)!
        let result = TimeFormatting.wallClock(from: date)
        #expect(result == "14:05")
    }

    @Test("Wall clock midnight formats as 0:00")
    func wallClockMidnight() {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let components = DateComponents(hour: 0, minute: 0)
        let date = cal.date(from: components)!
        let result = TimeFormatting.wallClock(from: date)
        #expect(result == "0:00")
    }

    @Test("Wall clock 9:08 formats correctly")
    func wallClockSingleDigitHour() {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let components = DateComponents(hour: 9, minute: 8)
        let date = cal.date(from: components)!
        let result = TimeFormatting.wallClock(from: date)
        #expect(result == "9:08")
    }

    // MARK: - TimerResponse

    @Test("TimerResponse model")
    func timerResponseModel() {
        let resp = TimerResponse(running: true, elapsedSeconds: 125, wallClock: "2:30 PM")
        #expect(resp.running == true)
        #expect(resp.elapsedSeconds == 125)
        #expect(resp.wallClock == "2:30 PM")
    }

    @Test("TimerResponse encoding round-trip")
    func timerResponseEncoding() throws {
        let resp = TimerResponse(running: false, elapsedSeconds: 0, wallClock: "10:00 AM")
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(TimerResponse.self, from: data)
        #expect(decoded.running == false)
        #expect(decoded.elapsedSeconds == 0)
        #expect(decoded.wallClock == "10:00 AM")
    }

    @Test("TimerResponse stopped state")
    func timerResponseStopped() {
        let resp = TimerResponse(running: false, elapsedSeconds: 0, wallClock: "12:00 PM")
        #expect(!resp.running)
        #expect(resp.elapsedSeconds == 0)
    }

    @Test("TimerResponse running with elapsed time")
    func timerResponseRunning() {
        let resp = TimerResponse(running: true, elapsedSeconds: 3661, wallClock: "3:15 PM")
        #expect(resp.running)
        #expect(resp.elapsedSeconds == 3661)
        // 3661s = 1h 1m 1s
        let hours = resp.elapsedSeconds / 3600
        let minutes = (resp.elapsedSeconds % 3600) / 60
        let seconds = resp.elapsedSeconds % 60
        #expect(hours == 1)
        #expect(minutes == 1)
        #expect(seconds == 1)
    }
}
