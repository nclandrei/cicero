import Testing
@testable import Shared

@Suite("CiceroConstants")
struct ConstantsTests {

    // The loopback address must be 127.0.0.1. Cicero's HTTP IPC server is intended
    // for local-only communication between the Cicero app and CiceroMCP. Binding to
    // 0.0.0.0 (or any LAN address) would expose presentation control to other
    // hosts on the same network segment. This test guards against accidental
    // regression of CiceroConstants.httpLoopbackAddress.
    @Test("HTTP server binds to IPv4 loopback only")
    func httpLoopbackAddressIsLocalOnly() {
        #expect(CiceroConstants.httpLoopbackAddress == "127.0.0.1")
    }

    @Test("HTTP base URL points at loopback host")
    func httpBaseURLIsLoopback() {
        #expect(CiceroConstants.httpBaseURL.contains("localhost"))
        #expect(CiceroConstants.httpBaseURL.contains("\(CiceroConstants.httpPort)"))
    }
}
