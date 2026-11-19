# TopologyNetwork

一个基于 UIKit 的能源拓扑可视化示例，展示光伏、电网、储能电池、车辆充电及负载之间的连接关系，通过路径上的流动动画表达能源传输方向。

页面数值和传输事件由 ViewModel 中的 RxSwift 定时序列模拟，ViewController 通过订阅更新界面，用于演示拓扑寻路与动画效果。

## 核心特性

- **有向拓扑寻路**：根据节点连接关系，通过 BFS 查找连接段数最少的可达路线。
- **路径拼接与缓存**：支持组合 SVG 和代码生成的路径片段，按 URL 缓存 SVG 解析结果，减少重复解析。
- **能源流动动画**：沿完整路径播放流动线段，直观展示源设备到目标设备的传输方向。
- **定时模拟传输**：统一管理设备数值变化与随机传输，在路径就绪后扣除源值、动画完成后增加目标值。

## 重要组成

- **[RealtimeSceneViewController](TopologyNetwork/RealtimeScene/RealtimeSceneViewController.swift)**：负责节点布局、连接关系配置和动画展示。`configPath()` 注册节点间的有向路径，`bindViewModel()` 订阅设备数值与传输事件，`animateTransfer(_:)` 获取完整路径并启动动画。
- **[RealtimeSceneViewModel](TopologyNetwork/RealtimeScene/RealtimeSceneViewModel.swift)**：统一管理光伏、电网、电池、车辆、常开负载和附加负载的模拟数值，以及定时变化和传输状态，不直接持有界面控件。
  - `Equipment` / `PowerTransfer`：定义设备标识和带唯一 ID 的传输事件。
  - 私有 `BehaviorRelay` 保存设备数值，公开 `powerObservable` 和 `powerObservable(for:)` 供页面订阅；后者通过 `distinctUntilChanged()` 过滤连续重复值，避免其他设备变化时重复刷新当前设备。
  - 私有 `PublishRelay` 发布传输事件，通过 `transferObservable` 通知页面播放动画。
  - `start()` 启动主线程上的定时序列：光伏每 3 秒、电网每 4 秒增加数值，车辆每 5 秒、附加负载每 6 秒减少数值，每 2 秒尝试随机传输。数值最低为 0，订阅由 `DisposeBag` 管理，随 ViewModel 释放而清理；页面初始化时调用一次。
  - `beginTransfer(_:)` 检查源设备余额并扣除数值，`completeTransfer(_:)` 在动画结束后增加目标设备数值，并移除活动传输记录，避免重复完成回调重复增加数值。
- **[PathSetManager](TopologyNetwork/RealtimeScene/PathSetManager.swift)**：管理节点、连接关系与路径资源，将路径查找和 SVG 解析从页面中分离。
  - `StartPointRelation` / `DestinationRelation`：描述起点可到达的节点，以及对应的 SVG 资源或 `UIBezierPath` 路径片段。
  - `getPathURL(fromName:toName:)`：使用广度优先搜索（BFS）查找连接段数最少的有向路径，通过已访问集合避免重复访问节点，并处理节点不存在、目标不可达的情况。
  - `parseURL(destinations:completion:)`：解析尚未缓存的 SVG，按查找结果的顺序拼接路径片段，返回完整的 `UIBezierPath`。
  - `cachedPathsByURL`：按资源 URL 缓存已解析的路径，供后续动画复用。
- **`AnimationLayer`**：定义在 [RealtimeSceneViewController.swift](TopologyNetwork/RealtimeScene/RealtimeSceneViewController.swift) 中的 `CAShapeLayer` 子类。使用 `CADisplayLink` 推进 `strokeStart` 和 `strokeEnd`，让一段线沿完整路径移动；动画结束后停止刷新，由页面移除图层。
