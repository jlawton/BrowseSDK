//
//  Created on 7/24/20.
//  Copyright © 2020 Box. All rights reserved.
//

struct Predicate<Input> {
    let condition: (Input) -> Bool
    init(_ condition: @escaping (Input) -> Bool) {
        self.condition = condition
    }

    func callAsFunction(_ input: Input) -> Bool {
        condition(input)
    }

    static func && (lhs: Self, rhs: Self) -> Self {
        .init { lhs($0) && rhs($0) }
    }

    static func || (lhs: Self, rhs: Self) -> Self {
        .init { lhs($0) || rhs($0) }
    }

    static prefix func ! (rhs: Self) -> Self {
        .init { !rhs($0) }
    }
}
