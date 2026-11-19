//
//  RealtimeSceneViewController.swift
//  FirstProject
//
//  Created by Zack-Zeng on 2025/9/10.
//

import UIKit
import MyBaseExtension
import SnapKit
import SwiftSVG
import RxSwift

class RealtimeSceneViewController: UIViewController {

    private let viewModel = RealtimeSceneViewModel()
    private let disposeBag = DisposeBag()
    private let pathSetManager = PathSetManager()

    private lazy var titleLab: UILabel = {
        let titleLab = UILabel()
        titleLab.text = "Realtime Power"
        titleLab.textColor = .init(hex: 0xFFFFFF)
        titleLab.font = .systemFont(ofSize: 16, weight: .regular)
        return titleLab
    }()
    
    private lazy var pathImgV: UIImageView = {
        let pathImgV = UIImageView()
        pathImgV.image = .init(named: "topo_map")
        pathImgV.tintColor = .init(hex: 0xFFFFFF, a: 0.1)
        return pathImgV
    }()
    
    private lazy var lightningModeImgV: UIImageView = {
        let lightningModeImgV = UIImageView()
        lightningModeImgV.image = .init(named: "icon_power_lightning_mode")
        return lightningModeImgV
    }()
    
    let solarView = PowerEquipmentView(name: "Solar", imageName: "icon_power_solar_full", order: .valueNameImage)
    let gridView = PowerEquipmentView(name: "Grid", imageName: "icon_power_grid", order: .valueNameImage)
    let batteryView = PowerEquipmentView(name: "Battery", imageName: "icon_power_battery_background", order: .valueNameImage, imageSize: nil)
    let vehicleView = PowerEquipmentView(name: "Vehicle", imageName: "icon_power_vehicle_charging", order: .imageNameValue, valueHeight: 58)
    let keepOnLoadView = PowerEquipmentView(name: "KeepOn Load", imageName: "icon_power_usage_secure_supply", order: .imageNameValue, valueHeight: 58)
    let additionalLoadView = PowerEquipmentView(name: "Additional Load", imageName: "icon_power_usage_extra_supply", order: .imageNameValue, valueHeight: 60)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .init(hex: 0x2B445E)
        setupSubviews()
        makeConstraints()
        configPath()
        bindViewModel()
        viewModel.start()
        
    }

    func setupSubviews() {
        view.addSubview(titleLab)
        view.addSubview(pathImgV)
        view.addSubview(lightningModeImgV)
        [solarView, gridView, batteryView, vehicleView, keepOnLoadView, additionalLoadView].forEach {
            view.addSubview($0)
        }
    }
    
    func makeConstraints() {
        titleLab.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(15)
            make.top.equalToSuperview().inset(10)
            make.height.equalTo(24)
        }
        pathImgV.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(15)
            make.size.equalTo(CGSize(width: 230, height: 147))
        }
        lightningModeImgV.snp.makeConstraints { make in
            make.left.equalTo(pathImgV).offset(92)
            make.top.equalTo(pathImgV).offset(54)
            make.size.equalTo(24)
        }
        solarView.imageView.snp.makeConstraints { make in
            make.bottom.equalTo(pathImgV.snp.top)
            make.left.equalTo(pathImgV.snp.left).offset(70)
        }
        gridView.imageView.snp.makeConstraints { make in
            make.bottom.equalTo(pathImgV.snp.top)
            make.right.equalTo(pathImgV).offset(30)
        }
        batteryView.imageView.snp.makeConstraints { make in
            make.top.equalTo(pathImgV).offset(45.44)
            make.right.equalTo(pathImgV.snp.left).offset(-3.99)
        }
        vehicleView.imageView.snp.makeConstraints { make in
            make.left.equalTo(pathImgV).offset(-55.99)
            make.bottom.equalTo(pathImgV).offset(46.56)
        }
        keepOnLoadView.imageView.snp.makeConstraints { make in
            make.centerX.equalTo(solarView.imageView)
            make.bottom.equalTo(pathImgV).offset(46.56)
        }
        additionalLoadView.imageView.snp.makeConstraints { make in
            make.centerX.equalTo(gridView.imageView)
            make.bottom.equalTo(pathImgV).offset(46.56)
        }
    }
    
}

extension RealtimeSceneViewController {
    
    func configPath() {
        typealias Equipment = RealtimeSceneViewModel.Equipment
        let solarEnter = "solarEnter"
        let gridEnter = "gridEnter"
        let vehicleEnter = "vehicleEnter"
        let vehicleOuter = "vehicleOuter"
        let keepOnLoadOuter = "keepOnLoadOuter"
        pathSetManager.configPath(fromName: Equipment.solar.rawValue, toName: solarEnter, toSVG: "solar——circle".toSVGURL())
        pathSetManager.configPath(fromName: Equipment.grid.rawValue, toName: gridEnter, toSVG: "grid——circle".toSVGURL())
        pathSetManager.configPath(fromName: Equipment.grid.rawValue, toName: Equipment.additionalLoad.rawValue, toSVG: "grid——Additional Load".toSVGURL())
        pathSetManager.configPath(fromName: gridEnter, toName: solarEnter, path: createCirclePath(startAngle: 1.75 * CGFloat.pi, endAngle: 1.25 * CGFloat.pi))
        pathSetManager.configPath(fromName: solarEnter, toName: vehicleEnter, path: createCirclePath(startAngle: 1.25 * CGFloat.pi, endAngle: 0.88 * CGFloat.pi))
        pathSetManager.configPath(fromName: vehicleEnter, toName: vehicleOuter, path: createCirclePath(startAngle: 0.88 * CGFloat.pi, endAngle: 0.68 * CGFloat.pi))
        pathSetManager.configPath(fromName: vehicleOuter, toName: keepOnLoadOuter, path: createCirclePath(startAngle: 0.70 * CGFloat.pi, endAngle: 0.25 * CGFloat.pi))
        pathSetManager.configPath(fromName: solarEnter, toName: Equipment.battery.rawValue, toSVG: "circle——battery".toSVGURL())
        pathSetManager.configPath(fromName: vehicleEnter, toName: Equipment.vehicle.rawValue, toSVG: "circle——vehicle".toSVGURL())
        pathSetManager.configPath(fromName: vehicleOuter, toName: Equipment.keepOnLoad.rawValue, toSVG: "circle——KeepON Load".toSVGURL())
        pathSetManager.configPath(fromName: keepOnLoadOuter, toName: Equipment.additionalLoad.rawValue, toSVG: "circle——Additional Load".toSVGURL())
    }
    
    /// 生成部分圆路径
    /// - Parameters:
    ///   - startAngle: 角度
    ///   - endAngle: 角度
    /// - Returns: 路径
    func createCirclePath(startAngle: CGFloat, endAngle: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.addArc(withCenter: .init(x: 104, y: 66), radius: 20, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

extension String {
    
    func toSVGURL() -> URL {
        if let url = Bundle.main.url(forResource: self, withExtension: "svg") {
            return url
        } else {
            fatalError()
        }
    }
}

extension RealtimeSceneViewController {
    private func bindViewModel() {
        let equipmentViews: [(RealtimeSceneViewModel.Equipment, PowerEquipmentView)] = [
            (.solar, solarView), (.grid, gridView), (.battery, batteryView),
            (.vehicle, vehicleView), (.keepOnLoad, keepOnLoadView), (.additionalLoad, additionalLoadView)
        ]
        for (equipment, equipmentView) in equipmentViews {
            viewModel.powerObservable(for: equipment)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak equipmentView] power in
                    equipmentView?.updatePower(power)
                })
                .disposed(by: disposeBag)
        }
        viewModel.transferObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] transfer in
                self?.animateTransfer(transfer)
            })
            .disposed(by: disposeBag)
    }

    private func animateTransfer(_ transfer: RealtimeSceneViewModel.PowerTransfer) {
        pathSetManager.getPath(fromName: transfer.source.rawValue, toName: transfer.destination.rawValue) { [weak self] path, error in
            guard let self, let path else {
                print("Unable to prepare transfer path: \(String(describing: error))")
                return
            }
            guard viewModel.beginTransfer(transfer) else { return }
            let layer = AnimationLayer()
            layer.path = path.cgPath
            layer.frame = pathImgV.bounds
            pathImgV.layer.addSublayer(layer)
            layer.startAnimation { [weak self, weak layer] in
                layer?.removeFromSuperlayer()
                self?.viewModel.completeTransfer(transfer)
            }
        }
    }
}

extension RealtimeSceneViewController {
 
    class AnimationLayer: CAShapeLayer {
        
        var top: CGFloat {
            0.1
        }
        
        // 0.90 是动画头部到达尽头，1是尾部到达尽头
        var progress: CGFloat = 0 {
            didSet {
                strokeStart = progress
                if progress >= 1 - top {
                    strokeEnd = 1
                } else {
                    strokeEnd = progress + top
                }
            }
        }
        
        weak var link: CADisplayLink?
        
        var endOperation: (() -> Void)?
        
        var frameRate: Int = 60
        
        override init() {
            super.init()
            setup()
        }
        
        override init(layer: Any) {
            super.init(layer: layer)
            setup()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setup() {
            strokeColor = UIColor.white.cgColor
            fillColor = UIColor.clear.cgColor
        }
        
        func startAnimation(endOperation: @escaping (() -> Void)) {
            self.endOperation = endOperation
            strokeEnd = top
            strokeStart = 0
            let link = CADisplayLink(target: self, selector: #selector(updateProgress))
            link.preferredFrameRateRange = .init(minimum: 60, maximum: 60)
            link.add(to: .main, forMode: .common)
            self.link = link
        }
        
        func stopAnimation() {
            link?.invalidate()
            link?.remove(from: .main, forMode: .common)
            link = nil
        }
        
        @objc func updateProgress() {
            guard progress < 1 else {
                stopAnimation()
                endOperation?()
                endOperation = nil
                return
            }
            
            progress += 0.005
        }
    }
}

/// Displays an equipment value, name and image in the requested vertical order.
final class PowerEquipmentView: UIStackView {
    enum Order {
        case valueNameImage
        case imageNameValue
    }

    let valueLabel = UILabel()
    private let nameLabel = UILabel()
    let imageView = UIImageView()

    init(name: String, imageName: String, order: Order, imageSize: CGSize? = CGSize(width: 60, height: 60), valueHeight: CGFloat = 48) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        alignment = .center
        distribution = .fill
        spacing = 0

        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 13, weight: .regular)
        nameLabel.textColor = .init(hex: 0xFFFFFF, a: 0.3)
        imageView.image = UIImage(named: imageName)

        let arrangedViews: [UIView]
        switch order {
        case .valueNameImage:
            arrangedViews = [valueLabel, nameLabel, imageView]
        case .imageNameValue:
            arrangedViews = [imageView, nameLabel, valueLabel]
        }
        arrangedViews.forEach { addArrangedSubview($0) }
        nameLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        valueLabel.snp.makeConstraints { make in
            make.height.equalTo(valueHeight)
        }
        if let imageSize {
            imageView.snp.makeConstraints { make in
                make.size.equalTo(imageSize)
            }
        }
    }

    func updatePower(_ power: Int) {
        let text = NSMutableAttributedString(string: "\(power)", attributes: [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor(hex: 0xFFFFFF)
        ])
        text.append(NSAttributedString(string: "kW", attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor(hex: 0xFFFFFF)
        ]))
        valueLabel.attributedText = text
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
