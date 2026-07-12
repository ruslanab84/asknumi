//
//  DomainError.swift
//  Ask Numi
//

import Foundation

enum DomainError: Error, Equatable {
    case invalidAmount
    case invalidQuestion
    case notEnoughData
}
