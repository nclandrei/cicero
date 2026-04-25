import Foundation

public enum CiceroConstants {
    public static let httpPort: UInt16 = 19847
    public static let httpHost = "localhost"
    /// The IPv4 address the HTTP server binds to. Loopback only — never expose
    /// the IPC channel to other hosts on the network.
    public static let httpLoopbackAddress = "127.0.0.1"
    public static let httpBaseURL = "http://localhost:19847"
    public static let appBundleIdentifier = "com.andreinicolas.Cicero"
}
