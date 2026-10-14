#if LOGIC_TEST_RUNNER
import Foundation

@main
struct LogicTestMain {
    static func main() {
        let failures = PromptLogicChecks.all.compactMap { check in
            check.run().map { "\(check.name): \($0)" }
        }
        if failures.isEmpty {
            print("Passed \(PromptLogicChecks.all.count) logic tests")
            return
        }
        for failure in failures {
            FileHandle.standardError.write(Data((failure + "\n").utf8))
        }
        exit(1)
    }
}
#endif
