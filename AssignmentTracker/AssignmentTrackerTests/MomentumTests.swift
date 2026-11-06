import CoreGraphics
import Testing
@testable import AssignmentTracker

struct MomentumTests {
    @Test func projectionFollowsTheFlick() {
        #expect(Momentum.project(0) == 0)
        // 1000 pt/s at the scroll-view rate carries just under 500 pt, in the flick's direction.
        #expect(abs(Momentum.project(1000) - 499) < 0.01)
        #expect(Momentum.project(-1000) == -Momentum.project(1000))
    }

    @Test func rubberBandResistsMoreTheFurtherItIsPulled() {
        let near = Momentum.rubberBand(20, dimension: 120)
        let far = Momentum.rubberBand(200, dimension: 120)
        #expect(near > 0 && near < 20)
        #expect(far > near && far < 200)
        // Never travels as far as the dimension, however far it's pulled.
        #expect(Momentum.rubberBand(10_000, dimension: 120) < 120)
    }
}
