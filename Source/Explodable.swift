//
//  Explodable.swift
//  Example (Explodable)
//
//  Created by tang dixi on 7/6/2016.
//  Copyright © 2016 Tangdixi. All rights reserved.
//

import UIKit

protocol Explodable {}

private let goldenRatio = CGFloat(0.625)
private let explodeDuration = Double(goldenRatio)
private let explodaAngle = CGFloat(M_PI)*goldenRatio
private let splitRatio = CGFloat(10)

enum ExplodeDirection {
  case Top, Left, Bottom, Right, Chaos
  func explodeDirection(offset:CGSize) -> CGVector {
    switch self {
    case .Top:
      let xOffset = random(from: -16.8, to: 16.8)
      let yOffset = random(from: -offset.height*goldenRatio, to: 0)
      return CGVector(dx: xOffset, dy: yOffset)
    case .Left:
      let xOffset = random(from: -offset.width*goldenRatio, to: 0)
      let yOffset = random(from: -16.8, to: 16.8)
      return CGVector(dx: xOffset, dy: yOffset)
    case .Bottom:
      let xOffset = random(from: -16.8, to: 16.8)
      let yOffset = random(from: 0, to: offset.height*goldenRatio)
      return CGVector(dx: xOffset, dy: yOffset)
    case .Right:
      let xOffset = random(from: 0, to: offset.width*goldenRatio)
      let yOffset = random(from: -16.8, to: 16.8)
      return CGVector(dx: xOffset, dy: yOffset)
    case .Chaos:
      let xOffset = random(from: -offset.width*goldenRatio, to: offset.width*goldenRatio)
      let yOffset = random(from: -offset.height*goldenRatio, to: offset.height*goldenRatio)
      return CGVector(dx: xOffset, dy: yOffset)
    }
  }
}

extension Explodable where Self:UIView {
  
  func explode(direction:ExplodeDirection = .Chaos, duration:Double) {
    explode(direction, duration: duration) {}
  }
  func explode(direction:ExplodeDirection = .Chaos, duration:Double, complete:(()->Void)) {
    
    guard let containerView = self.superview else { fatalError() }
    let fragments = generateFragmentsFrom(self, with: splitRatio, in: containerView)
    self.alpha = 0
    
    
    UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut,
      animations: {
        fragments.forEach {
          
          let direction = direction.explodeDirection($0.superview!.frame.size)
          let explodeAngle = random(from: -CGFloat(M_PI)*goldenRatio, to: CGFloat(M_PI)*goldenRatio)
          let scale = 0.01 + random(from: 0.01, to: goldenRatio)
          
          let translateTransform = CGAffineTransformMakeTranslation(direction.dx, direction.dy)
          let angleTransform = CGAffineTransformRotate(translateTransform, explodeAngle)
          let scaleTransform = CGAffineTransformScale(angleTransform, scale, scale)
          
          $0.transform = scaleTransform
          $0.alpha = 0
          
        }
      },
      completion: { _ in
        fragments.forEach {
          $0.removeFromSuperview()
        }
        self.removeFromSuperview()
        self.alpha = 1
        complete()
      })
  }
  
}

extension UITableView {
  
  private struct AssociatedKeys {
    static var associatedName = "exploding"
  }
  
  var exploding:Bool {
    get {
      guard let exploding = objc_getAssociatedObject(self, &AssociatedKeys.associatedName) as? Bool else { return false }
      return exploding
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.associatedName, newValue as Bool, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
}

extension Explodable where Self:UITableView {
  
  func explodeRowAtIndexPath(indexPath:NSIndexPath, duration:Double, direction:ExplodeDirection = .Chaos, complete:()->Void) {
    
    if self.exploding == true {
      return
    }
    
    guard let cell = self.cellForRowAtIndexPath(indexPath) else { return }
    if cell.backgroundView == nil {
      cell.backgroundView = UIView()
    }
    
    let fragments = generateFragmentsFrom(cell, with: 10, in: cell)
    cell.contentView.alpha = 0
    
    UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut,
      animations: {
        self.exploding = true
        fragments.forEach {
          
          let direction = direction.explodeDirection($0.superview!.frame.size)
          let explodeAngle = random(from: -CGFloat(M_PI)*goldenRatio, to: CGFloat(M_PI)*goldenRatio)
          let scale = 0.01 + random(from: 0.01, to: goldenRatio)
          
          let translateTransform = CGAffineTransformMakeTranslation(direction.dx, direction.dy)
          let angleTransform = CGAffineTransformRotate(translateTransform, explodeAngle)
          let scaleTransform = CGAffineTransformScale(angleTransform, scale, scale)
          
          $0.transform = scaleTransform
          $0.alpha = 0
          
        }
      },
      completion: { _ in
        fragments.forEach {
          $0.removeFromSuperview()
        }
        
        complete()
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
          cell.contentView.alpha = 1
        }
        self.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        CATransaction.commit()
        
        self.exploding = false
    })
    
  }
  
}

private func generateFragmentsFrom(originView:UIView, with splitRatio:CGFloat, in containerView:UIView) -> [UIView] {
  
  let size = originView.frame.size
  let snapshots = originView.snapshotViewAfterScreenUpdates(true)
  var fragments = [UIView]()
  
  let shortSide = min(size.width, size.height)
  let gap = max(20, shortSide/splitRatio)
  
  for x in 0.0.stride(to: Double(size.width), by: Double(gap)) {
    for y in 0.0.stride(to: Double(size.height), by: Double(gap)) {

      let fragmentRect = CGRect(x: CGFloat(x), y: CGFloat(y), width: size.width/splitRatio, height: size.width/splitRatio)
      let fragment = snapshots.resizableSnapshotViewFromRect(fragmentRect, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsMake(1, 1, 1, 1))
      fragment.frame = originView.convertRect(fragmentRect, toView: containerView)
      containerView.addSubview(fragment)
      fragments.append(fragment)
      
    }
  }

  return fragments
  
}

private func random(from lowerBound:CGFloat, to upperBound:CGFloat) -> CGFloat {
  return CGFloat(arc4random_uniform(UInt32(upperBound - lowerBound))) + lowerBound
}

