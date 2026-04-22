import Testing
import Foundation
@testable import Shared

@Suite("SearchReplace")
struct SearchReplaceTests {

    @Test("Replace single occurrence returns updated content and count 1")
    func replaceSingle() {
        let result = SearchReplace.replaceInContent(
            "Hello world",
            query: "world",
            replacement: "Cicero"
        )
        #expect(result.updatedContent == "Hello Cicero")
        #expect(result.replacements == 1)
    }

    @Test("Replace multiple occurrences returns correct count")
    func replaceMultiple() {
        let result = SearchReplace.replaceInContent(
            "foo bar foo baz foo",
            query: "foo",
            replacement: "qux"
        )
        #expect(result.updatedContent == "qux bar qux baz qux")
        #expect(result.replacements == 3)
    }

    @Test("Replace with no matches returns original content and 0 count")
    func replaceNoMatch() {
        let result = SearchReplace.replaceInContent(
            "Hello world",
            query: "missing",
            replacement: "anything"
        )
        #expect(result.updatedContent == "Hello world")
        #expect(result.replacements == 0)
    }

    @Test("Empty query is a no-op")
    func replaceEmptyQuery() {
        let result = SearchReplace.replaceInContent(
            "Hello world",
            query: "",
            replacement: "XYZ"
        )
        #expect(result.updatedContent == "Hello world")
        #expect(result.replacements == 0)
    }

    @Test("Replace is case-sensitive")
    func replaceCaseSensitive() {
        let result = SearchReplace.replaceInContent(
            "Hello hello HELLO",
            query: "hello",
            replacement: "hi"
        )
        #expect(result.updatedContent == "Hello hi HELLO")
        #expect(result.replacements == 1)
    }

    @Test("Replace with empty string deletes matches")
    func replaceWithEmpty() {
        let result = SearchReplace.replaceInContent(
            "foo-bar-foo",
            query: "foo",
            replacement: ""
        )
        #expect(result.updatedContent == "-bar-")
        #expect(result.replacements == 2)
    }

    @Test("Replace across newlines works on multi-line content")
    func replaceMultiline() {
        let content = """
        # Title
        Some body with TOKEN inside.
        Another TOKEN here.
        """
        let result = SearchReplace.replaceInContent(
            content,
            query: "TOKEN",
            replacement: "value"
        )
        #expect(result.replacements == 2)
        #expect(result.updatedContent.contains("Some body with value inside."))
        #expect(result.updatedContent.contains("Another value here."))
        #expect(!result.updatedContent.contains("TOKEN"))
    }

    @Test("Replacing with the same string still counts matches")
    func replaceIdentity() {
        let result = SearchReplace.replaceInContent(
            "abc abc",
            query: "abc",
            replacement: "abc"
        )
        #expect(result.updatedContent == "abc abc")
        #expect(result.replacements == 2)
    }
}

@Suite("Replace API Models")
struct ReplaceAPIModelTests {

    @Test("ReplaceRequest encodes and decodes query and replacement")
    func replaceRequestRoundTrip() throws {
        let req = ReplaceRequest(query: "foo", replacement: "bar")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(ReplaceRequest.self, from: data)
        #expect(decoded.query == "foo")
        #expect(decoded.replacement == "bar")
    }

    @Test("ReplaceMatch encodes index, title and replacements")
    func replaceMatchRoundTrip() throws {
        let match = ReplaceMatch(index: 2, title: "My Slide", replacements: 3)
        let data = try JSONEncoder().encode(match)
        let decoded = try JSONDecoder().decode(ReplaceMatch.self, from: data)
        #expect(decoded.index == 2)
        #expect(decoded.title == "My Slide")
        #expect(decoded.replacements == 3)
    }

    @Test("ReplaceMatch supports nil title")
    func replaceMatchNilTitle() throws {
        let match = ReplaceMatch(index: 0, title: nil, replacements: 1)
        let data = try JSONEncoder().encode(match)
        let decoded = try JSONDecoder().decode(ReplaceMatch.self, from: data)
        #expect(decoded.title == nil)
        #expect(decoded.replacements == 1)
    }

    @Test("ReplaceResponse aggregates matches and total replacements")
    func replaceResponseRoundTrip() throws {
        let resp = ReplaceResponse(
            query: "foo",
            replacement: "bar",
            totalReplacements: 4,
            matches: [
                ReplaceMatch(index: 0, title: "A", replacements: 1),
                ReplaceMatch(index: 2, title: nil, replacements: 3),
            ]
        )
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(ReplaceResponse.self, from: data)
        #expect(decoded.query == "foo")
        #expect(decoded.replacement == "bar")
        #expect(decoded.totalReplacements == 4)
        #expect(decoded.matches.count == 2)
        #expect(decoded.matches[0].index == 0)
        #expect(decoded.matches[1].replacements == 3)
    }
}
