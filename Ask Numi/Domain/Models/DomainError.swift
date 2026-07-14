//
//  DomainError.swift
//  Ask Numi
//

import Foundation

enum DomainError: Error, Equatable {
    case invalidAmount
    case invalidName
    case invalidQuestion
    case notEnoughData
    case categoryNotFound
}
