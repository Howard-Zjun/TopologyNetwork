//
//  PathSetManager.swift
//  FirstProject
//
//  Created by Zack-Zeng on 2025/9/11.
//

import UIKit
import SwiftSVG

class PathSetManager: NSObject {
    
    private var cachedPathsByURL: [URL : UIBezierPath] = [:]

    private var pointNames: Set<String> = []

    private var relationsBySourceName: [String : StartPointRelation] = [:]
    
    private var parseContextsByParser: [XMLParser : ParseDataModel] = [:]
    
}

extension PathSetManager {
    
    func configPath(fromName: String, toName: String, path: UIBezierPath) {
        pointNames.insert(fromName)
        pointNames.insert(toName)
        var relation: StartPointRelation?
        if let tmp = relationsBySourceName[fromName] {
            relation = tmp
        } else {
            relation = .init(pointName: fromName)
        }
        relation?.destinations.append(.init(pointName: toName, path: path))
        relationsBySourceName[fromName] = relation
    }
    
    func configPath(fromName: String, toName: String, toSVG: URL) {
        pointNames.insert(fromName)
        pointNames.insert(toName)
        var relation: StartPointRelation?
        if let tmp = relationsBySourceName[fromName] {
            relation = tmp
        } else {
            relation = .init(pointName: fromName)
        }
        
        relation?.destinations.append(.init(pointName: toName, svgURL: toSVG))
        relationsBySourceName[fromName] = relation
    }
}

extension PathSetManager {
    
    func getPath(fromName: String, toName: String, completion: @escaping (UIBezierPath?, PathError?) -> Void) {
        print("[\(String(describing: Self.self))-\(#function)-\(Thread.current):\(#line)] 获取\(fromName)到\(toName)的路径")
        do {
            let destinations: [DestinationRelation] = try getPathURL(fromName: fromName, toName: toName)
            parseURL(destinations: destinations, completion: completion)
        } catch {
            print("[\(String(describing: Self.self))-\(#function)-\(Thread.current):\(#line)] 错误: \(error.localizedDescription)")
            completion(nil, error)
        }
    }
    
    private func getPathURL(fromName: String, toName: String) throws(PathError) -> [DestinationRelation] {
        guard pointNames.contains(fromName) else {
            throw .unExistFromPoint
        }
        
        guard pointNames.contains(toName) else {
            throw .unExistToPoint
        }
        
        // 使用广度优先搜索(BFS)寻找最短路径
        var queue: [(currentPoint: String, path: [DestinationRelation])] = [(fromName, [])]
        var visited: Set<String> = [fromName]
        
        while !queue.isEmpty {
            let (current, currentPath) = queue.removeFirst()
            
            // 遍历当前点可达的所有点
            guard let relations = relationsBySourceName[current] else {
                continue
            }
            
            for toPoint in relations.destinations {
                let nextPoint = toPoint.pointName
                if nextPoint == toName {
                    // 找到终点，返回完整路径
                    let ret = currentPath + [toPoint]
                    print("[\(String(describing: Self.self))-\(#function)-\(Thread.current):\(#line)] 找到从\(fromName)到\(toName)的路径")
                    return ret
                }
                
                // 未访问过的点加入队列
                if !visited.contains(nextPoint) {
                    visited.insert(nextPoint)
                    queue.append((nextPoint, currentPath + [toPoint]))
                }
            }
        }
        
        // 遍历完所有可达点仍未找到终点
        throw PathError.unreachable
    }
    
    func parseURL(destinations: [DestinationRelation], completion: ((UIBezierPath?, PathError?) -> Void)? = nil) {
        for tmp in destinations {
            if let path = tmp.path {
                
            } else if let url = tmp.svgURL, cachedPathsByURL[url] == nil {
                print("[\(String(describing: Self.self))-\(#function)-\(Thread.current):\(#line)] 将\(url.lastPathComponent)解析")
                do {
                    let urlData = try Data(contentsOf: url)
                    let parser = XMLParser(data: urlData)
                    parser.delegate = self
                    parseContextsByParser[parser] = .init(destinations: destinations, svgURL: url, completion: completion)
                    parser.parse()
                    return
                } catch {
                    completion?(nil, .parseError)
                    return
                }
            }
        }
        
        var paths: [UIBezierPath] = []
        for destination in destinations {
            if let path = destination.path {
                paths.append(path)
            } else if let url = destination.svgURL, let path = cachedPathsByURL[url] {
                paths.append(path)
            }
        }
        let retPath = UIBezierPath()
        paths.forEach({ retPath.append($0) })
        completion?(retPath, nil)
    }
}

extension PathSetManager {
    
    enum PathError: Error {
        case unreachable // 不可达
        case unExistFromPoint // 不存在出发点
        case unExistToPoint // 不存在到达点
        case parseError
    }
}

// MARK: - XMLParserDelegate
extension PathSetManager: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "path", let d = attributeDict["d"] {
            parseContextsByParser[parser]?.parseResult = PathParseResult(d: d)
        } else if elementName == "circle" {
            var tmp: CircleParseResult?
            if let result = parseContextsByParser[parser]?.parseResult as? CircleParseResult {
                tmp = result
            } else {
                tmp = CircleParseResult()
                parseContextsByParser[parser]?.parseResult = tmp
            }
            if let cx = attributeDict["cx"] {
                tmp?.cx = cx
            }
            if let cy = attributeDict["cy"] {
                tmp?.cy = cy
            }
            if let r = attributeDict["r"] {
                tmp?.r = r
            }
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if let model = parseContextsByParser[parser], let path = model.parseResult?.path {
            print("[\(String(describing: Self.self))-\(#function)-\(Thread.current):\(#line)] 解析\(model.svgURL.lastPathComponent)完成")
            cachedPathsByURL[model.svgURL] = path
            parseContextsByParser[parser] = nil
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5) { [weak self] in
                self?.parseURL(destinations: model.destinations, completion: model.completion ?? nil)
            }
        } else {
            print("[\(String(describing: Self.self))-\(#function)-\(Thread.current):\(#line)] 丢失")
            parseContextsByParser[parser]?.completion?(nil, .parseError)
        }
    }
}

extension PathSetManager {
    
    class StartPointRelation {
        
        let pointName: String
        
        var destinations: [DestinationRelation] = []
        
//        var toPointArr: [(toName: String, path: URL)] = []
        
        init(pointName: String) {
            self.pointName = pointName
        }
    }
    
    struct DestinationRelation {
        
        let pointName: String
        
        let svgURL: URL?
        
        let path: UIBezierPath?
        
        init(pointName: String, svgURL: URL) {
            self.pointName = pointName
            self.svgURL = svgURL
            self.path = nil
        }
        
        init(pointName: String, path: UIBezierPath) {
            self.pointName = pointName
            self.svgURL = nil
            self.path = path
        }
    }
    
}

extension PathSetManager {
    
    class ParseDataModel: NSObject {
        
        let destinations: [DestinationRelation]
        
        var svgURL: URL
        
        var completion: ((UIBezierPath?, PathError?) -> Void)?
        
        var parseResult: ParseResult?
        
        init(destinations: [DestinationRelation], svgURL: URL, completion: ((UIBezierPath?, PathError?) -> Void)? = nil) {
            self.destinations = destinations
            self.svgURL = svgURL
            self.completion = completion
        }
    }
    
    protocol ParseResult {
    
        var isCircle: Bool { get }
        
        var path: UIBezierPath? { get }
    }
    
    class PathParseResult: ParseResult {
        
        let d: String
        
        var isCircle: Bool {
            false
        }
        
        var path: UIBezierPath? {
            return UIBezierPath(pathString: d)
        }
        
        init(d: String) {
            self.d = d
        }
    }
    
    class CircleParseResult: ParseResult {
        
        var cx: String?
        
        var cy: String?
        
        var r: String?
        
        var centerX: CGFloat? {
            if let cx, let dValue = Double(cx) {
                return dValue
            }
            return nil
        }
        
        var centerY: CGFloat? {
            if let cy, let dValue = Double(cy) {
                return dValue
            }
            return nil
        }
        
        var radius: CGFloat? {
            if let r, let dValue = Double(r) {
                return dValue
            }
            return nil
        }
        var isCircle: Bool {
            true
        }
        
        var path: UIBezierPath? {
            if let centerX, let centerY, let radius {
                let path = UIBezierPath()
                path.addArc(withCenter: .init(x: centerX, y: centerY), radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
                return path
            }
            return nil
        }
    }
    
}


