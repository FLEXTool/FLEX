//
//  Commit.swift
//  FLEXample
//
//  Created by Tanner on 3/12/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

import Foundation

infix operator ~ : ComparisonPrecedence

func ~ (a: String, b: String) -> Bool {
    return a.localizedCaseInsensitiveContains(b)
}

func ~ (a: NSString, b: String) -> Bool {
    return a.localizedCaseInsensitiveContains(b)
}

/// Used for both commit details and the outer committer
@objcMembers
public class CommitIdentity: NSObject, Codable {
    // These actually come from the "root[committer]" part
    public let login: String?
    public let id: Int?
    public let avatarUrl: String?
    public let gravatarUrl: String?
    
    // These actually come from the
    // "root[commit][author/committer]" part
    public let name: String?
    public let email: String?
    public let date: Date?
    
    public func matches(query: String) -> Bool {
        if let login = self.login {
            return login ~ query
        } else if let name = self.name, let email = self.email {
            return name ~ query || email ~ query
        }
        
        return false
    }
}

@objcMembers
public class CommitDetails: NSObject, Codable {
    public let message: String
    public let url: String
    
    public let author: CommitIdentity
    public let committer: CommitIdentity
    
    public func matches(query: String) -> Bool {
        return message ~ query ||
            author.matches(query: query) ||
            committer.matches(query: query)
    }
}

@objcMembers
public class Commit: NSObject, Codable {
    
    static var formatter: DateFormatter = {
        var f = DateFormatter()
        f.dateFormat = "dd MMM yyyy h:mm a"
        return f
    }()
    
    /// Turn some response data into a list of commits
    static func commits(from data: Data) -> [Commit] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        _ = try! decoder.decode([Commit].self, from: data)
        if let commits = try? decoder.decode([Commit].self, from: data) {
            return commits
        }
        
        return []
    }
    
    enum CodingKeys: String, CodingKey {
        case sha, htmlUrl, committer
        case details = "commit"
    }
    
    public private(set) var sha: String = ""
    public private(set) var htmlUrl: String = ""
    /// Details does not contain avi URLs for users
    public private(set) var details: CommitDetails
    /// This does have the (g)avatar URL
    public private(set) var committer: CommitIdentity
    
    public func matches(query: String) -> Bool {
        return sha ~ query ||
            details.matches(query: query) ||
            committer.matches(query: query)
    }
    
    // You're crazy if you think I'm going to slice strings with Swift.String
    public lazy var shortHash: String = NSString(string: self.sha).substring(to: 8)
    
    public lazy var date: String = {
        if let date = details.committer.date ?? details.author.date {
            return Commit.formatter.string(from: date)
        }
        
        return "no date found"
    }()
    
    public lazy var firstLine: String = {
        let name = details.committer.name ?? details.author.name ?? "Anonymous"
        return name + " — " + self.date
    }()
    
    public lazy var secondLine: String = {
        return self.shortHash + "  " + self.details.message
    }()
    
    public lazy var identifier: Int = self.sha.hashValue
}
