# TopologyNetwork

一个基于 UIKit 的能源拓扑可视化示例，展示光伏、电网、储能电池、车辆充电及负载之间的连接关系，通过路径上的流动动画表达能源传输方向。

页面数值和传输事件由定时器模拟，用于演示拓扑寻路与动画效果。

## 重要组成

- **[RealtimeSceneViewController](TopologyNetwork/RealtimeScene/RealtimeSceneViewController.swift)**：拓扑展示与演示入口，负责节点布局、数值展示和连接关系配置。`configPath()` 注册节点间的有向路径，`powerTransport(fromName:toName:)` 根据起止节点获取完整路径并启动动画。
- **[PathSetManager](TopologyNetwork/RealtimeScene/PathSetManager.swift)**：管理节点、连接关系与路径资源，将路径查找和 SVG 解析从页面中分离。
  - `StartPointRelation` / `DestinationRelation`：描述起点可到达的节点，以及对应的 SVG 资源或 `UIBezierPath` 路径片段。
  - `getPathURL(fromName:toName:)`：使用广度优先搜索（BFS）查找连接段数最少的有向路径，通过已访问集合避免重复访问节点，并处理节点不存在、目标不可达的情况。
  - `parseURL(destinations:completion:)`：解析尚未缓存的 SVG，按查找结果的顺序拼接路径片段，返回完整的 `UIBezierPath`。
  - `parseFinishURLMap`：按资源 URL 缓存已解析的路径，供后续动画复用。
- **`AnimationLayer`**：定义在 [RealtimeSceneViewController.swift](TopologyNetwork/RealtimeScene/RealtimeSceneViewController.swift) 中的 `CAShapeLayer` 子类。使用 `CADisplayLink` 推进 `strokeStart` 和 `strokeEnd`，让一段线沿完整路径移动；动画结束后停止刷新，由页面移除图层。
- **`PowerRquipmentViewModel`**：定义在同一页面文件中的节点数据对象，保存节点名称和模拟数值，数值变化时更新关联的 Label；页面使用这些对象组织模拟传输事件。
- **路径与图片资源**：[Resource/Path](TopologyNetwork/Resource/Path) 中的 SVG 提供连接线片段，页面代码生成中间圆弧；[Realtime Scene](TopologyNetwork/Assets.xcassets/Realtime%20Scene) 中的图片提供拓扑底图和设备图标。静态底图与动画路径分别管理。
- **[ViewController](TopologyNetwork/ViewController.swift)**：Storyboard 的默认页面，继承 `RealtimeSceneViewController`，应用启动后直接展示拓扑。

## 实现流程

1. 注册节点间的有向连接，为每段连接配置 SVG 或代码生成的路径。
2. 模拟传输事件指定起点和终点，由 BFS 查找经过的连接段。
3. 解析并缓存 SVG，将连接段拼接为完整路径。
4. 创建动画图层，沿路径播放流动效果，完成后移除图层并更新模拟数值。

BFS 查找的是展示网络中连接段数最少的路线，不涉及真实电力系统的能源调度计算。
