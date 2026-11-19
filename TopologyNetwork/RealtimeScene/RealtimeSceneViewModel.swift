import Foundation
import RxSwift
import RxRelay

final class RealtimeSceneViewModel {
    enum Equipment: String, CaseIterable {
        case solar
        case grid
        case battery
        case vehicle
        case keepOnLoad = "keepOn Load"
        case additionalLoad
    }

    struct PowerTransfer {
        let id = UUID()
        let source: Equipment
        let destination: Equipment
    }

    private let disposeBag = DisposeBag()
    private var activeTransfers: [UUID: PowerTransfer] = [:]

    private let powerRelay = BehaviorRelay<[Equipment: Int]>(value: [
        .solar: 6, .grid: 3, .battery: 0, .vehicle: 0, .keepOnLoad: 0, .additionalLoad: 0
    ])
    var powerObservable: Observable<[Equipment: Int]> { powerRelay.asObservable().distinctUntilChanged() }

    private let transferRelay = PublishRelay<PowerTransfer>()
    var transferObservable: Observable<PowerTransfer> { transferRelay.asObservable() }

    func powerObservable(for equipment: Equipment) -> Observable<Int> {
        powerObservable.map { $0[equipment, default: 0] }.distinctUntilChanged()
    }

    func start() {
        MainScheduler.ensureRunningOnMainThread()
        schedulePowerChange(for: .solar, every: 3, delta: 1, disposeBag: disposeBag)
        schedulePowerChange(for: .grid, every: 4, delta: 1, disposeBag: disposeBag)
        schedulePowerChange(for: .vehicle, every: 5, delta: -1, disposeBag: disposeBag)
        schedulePowerChange(for: .additionalLoad, every: 6, delta: -1, disposeBag: disposeBag)
        Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.requestRandomTransfer()
            })
            .disposed(by: disposeBag)
    }

    @discardableResult
    func beginTransfer(_ transfer: PowerTransfer) -> Bool {
        MainScheduler.ensureRunningOnMainThread()
        guard Self.sources.contains(transfer.source),
              Self.destinations.contains(transfer.destination),
              activeTransfers[transfer.id] == nil,
              powerRelay.value[transfer.source, default: 0] > 0 else { return false }
        activeTransfers[transfer.id] = transfer
        changePower(for: transfer.source, by: -1)
        return true
    }

    func completeTransfer(_ transfer: PowerTransfer) {
        MainScheduler.ensureRunningOnMainThread()
        guard let activeTransfer = activeTransfers.removeValue(forKey: transfer.id) else { return }
        changePower(for: activeTransfer.destination, by: 1)
    }

    private static let sources: [Equipment] = [.solar, .grid]
    private static let destinations: [Equipment] = [.battery, .vehicle, .keepOnLoad, .additionalLoad]

    private func requestRandomTransfer() {
        guard let source = Self.sources.randomElement(),
              let destination = Self.destinations.randomElement(),
              powerRelay.value[source, default: 0] > 0 else { return }
        transferRelay.accept(PowerTransfer(source: source, destination: destination))
    }

    private func schedulePowerChange(for equipment: Equipment, every seconds: Int, delta: Int, disposeBag: DisposeBag) {
        Observable<Int>.interval(.seconds(seconds), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.changePower(for: equipment, by: delta)
            })
            .disposed(by: disposeBag)
    }

    private func changePower(for equipment: Equipment, by delta: Int) {
        var powers = powerRelay.value
        let newValue = max(0, powers[equipment, default: 0] + delta)
        guard newValue != powers[equipment] else { return }
        powers[equipment] = newValue
        powerRelay.accept(powers)
    }
}
