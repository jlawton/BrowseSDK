//
//  Created on 7/24/20.
//  Copyright © 2020 Box. All rights reserved.
//

struct Predicated<PredicateInput, ActionInput, Output> {
    private struct Inner {
        let predicate: Predicate<PredicateInput>
        let action: (ActionInput) -> Output
    }

    private var alternatives: [Inner] = []

    private func matchingInnerAction(_ input: PredicateInput) -> Inner? {
        alternatives.first { $0.predicate(input) }
    }

    func canAct(_ input: PredicateInput) -> Bool {
        matchingInnerAction(input) != nil
    }

    func act(_ predicateInput: PredicateInput, _ actionInput: ActionInput) -> Output? {
        matchingInnerAction(predicateInput)?.action(actionInput)
    }

    static func || (lhs: Self, rhs: Self) -> Self {
        .init(alternatives: lhs.alternatives + rhs.alternatives)
    }

    mutating func fallbackTo(_ other: Self) {
        alternatives.append(contentsOf: other.alternatives)
    }
}

extension Predicated {
    init(
        predicate: @escaping (PredicateInput) -> Bool,
        action: @escaping (ActionInput) -> Output
    ) {
        self.init(alternatives: [Inner(predicate: Predicate(predicate), action: action)])
    }

    init(
        predicate: Predicate<PredicateInput>,
        action: @escaping (ActionInput) -> Output
    ) {
        self.init(alternatives: [Inner(predicate: predicate, action: action)])
    }
}

extension Predicated {
    func act(_ input: ActionInput) -> Output?
        where PredicateInput == ActionInput {
        matchingInnerAction(input)?.action(input)
    }

    func act<T>(_ predicateInput: PredicateInput, _ second: T) -> Output?
        where ActionInput == (PredicateInput, T) {
        matchingInnerAction(predicateInput)?.action((predicateInput, second))
    }
}
