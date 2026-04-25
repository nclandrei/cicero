import Testing
import Foundation
@testable import Shared

@Suite("Find & replace")
struct FindReplaceTests {

    @Test("Case-sensitive replace counts and replaces matches")
    func caseSensitiveReplace() {
        let result = FindReplace.replace(in: "Foo and foo and FOO", query: "foo", replacement: "bar", caseSensitive: true)
        #expect(result.count == 1)
        #expect(result.newContent == "Foo and bar and FOO")
    }

    @Test("Case-insensitive replace catches all variants")
    func caseInsensitiveReplace() {
        let result = FindReplace.replace(in: "Foo and foo and FOO", query: "foo", replacement: "bar", caseSensitive: false)
        #expect(result.count == 3)
        #expect(result.newContent == "bar and bar and bar")
    }

    @Test("No match returns content unchanged")
    func noMatch() {
        let result = FindReplace.replace(in: "hello world", query: "xyz", replacement: "abc", caseSensitive: false)
        #expect(result.count == 0)
        #expect(result.newContent == "hello world")
    }

    @Test("Empty query returns zero replacements")
    func emptyQuery() {
        let result = FindReplace.replace(in: "anything", query: "", replacement: "x", caseSensitive: false)
        #expect(result.count == 0)
        #expect(result.newContent == "anything")
    }

    @Test("Replacement with regex metachars in query is treated literally")
    func literalQuery() {
        let result = FindReplace.replace(in: "a.b.c", query: ".", replacement: "-", caseSensitive: false)
        #expect(result.count == 2)
        #expect(result.newContent == "a-b-c")
    }

    @Test("Replacement with regex metachars in replacement is escaped")
    func literalReplacement() {
        // `$1` should be inserted literally, not interpreted as a backreference.
        let result = FindReplace.replace(in: "hello", query: "hello", replacement: "$1 world", caseSensitive: false)
        #expect(result.count == 1)
        #expect(result.newContent == "$1 world")
    }

    @Test("apply to slides — all slides when slideIndices is nil")
    func applyAllSlides() {
        let slides = [
            (index: 0, content: "Hello world"),
            (index: 1, content: "another world here"),
            (index: 2, content: "no match"),
        ]
        let result = FindReplace.apply(to: slides, query: "world", replacement: "Earth", slideIndices: nil, caseSensitive: false)
        #expect(result.totalReplacements == 2)
        #expect(result.affectedSlides == [0, 1])
        #expect(result.updates.count == 2)
        #expect(result.updates[0].content == "Hello Earth")
        #expect(result.updates[1].content == "another Earth here")
    }

    @Test("apply to slides — restricted to specific indices")
    func applyRestrictedIndices() {
        let slides = [
            (index: 0, content: "foo"),
            (index: 1, content: "foo"),
            (index: 2, content: "foo"),
        ]
        let result = FindReplace.apply(to: slides, query: "foo", replacement: "bar", slideIndices: [1], caseSensitive: false)
        #expect(result.totalReplacements == 1)
        #expect(result.affectedSlides == [1])
        #expect(result.updates.count == 1)
        #expect(result.updates[0].index == 1)
    }

    @Test("apply to slides — no matches yields empty updates")
    func applyNoMatches() {
        let slides = [(index: 0, content: "abc")]
        let result = FindReplace.apply(to: slides, query: "xyz", replacement: "q", slideIndices: nil, caseSensitive: false)
        #expect(result.totalReplacements == 0)
        #expect(result.affectedSlides.isEmpty)
        #expect(result.updates.isEmpty)
    }

    @Test("FindReplaceRequest decodes snake_case keys")
    func requestDecoding() throws {
        let json = #"{"query":"a","replacement":"b","slide_indices":[0,2],"case_sensitive":true}"#
        let req = try JSONDecoder().decode(FindReplaceRequest.self, from: Data(json.utf8))
        #expect(req.query == "a")
        #expect(req.replacement == "b")
        #expect(req.slideIndices == [0, 2])
        #expect(req.caseSensitive == true)
    }

    @Test("FindReplaceResponse encodes snake_case keys")
    func responseEncoding() throws {
        let resp = FindReplaceResponse(replacements: 3, affectedSlides: [0, 4])
        let data = try JSONEncoder().encode(resp)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"affected_slides\""))
        #expect(json.contains("\"replacements\":3"))
    }
}
