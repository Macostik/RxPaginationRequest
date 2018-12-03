//
//  Refresher.swift
//  BitbonSpace
//
//  Created by Гранченко Юрий on 8/31/18.
//  Copyright © 2018 Simcord. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

enum RefresherStyle {
    case white, perple
}

enum RefresherPosition {
    case top, bottom
}

class Refresher: UIControl {
    
    public let startRefreshingObservable = PublishSubject<Refresher>()
    public var completable: Completable? {
        willSet {
            let completionBlock: ((Error?) -> Void) = { [unowned self] error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.scrollView?.isUserInteractionEnabled = true
                    self.setRefreshing(refreshing: false, for: self.position, with: true, error: error)
                })
            }
            newValue?.subscribe(onCompleted: {
                completionBlock(nil)
            }, onError: { error in
                completionBlock(error)
            }).disposed(by: disposeBag)
        }
    }
    
    public static var contentSize: CGFloat = 60
    private var inset: CGFloat = 0
    private var scrollView: UIScrollView?
    private var position = RefresherPosition.top
    private var isActivate = false
    
    internal override var isEnabled: Bool {
        didSet {
            isHidden = !isEnabled
        }
    }
    
    fileprivate let disposeBag = DisposeBag()
    
    convenience init(scrollView: UIScrollView, position: RefresherPosition = RefresherPosition.top) {
        var inset = scrollView.contentInset.top
        if position == .top {
            self.init(frame: scrollView.bounds.offsetBy(dx: 0, dy: -(scrollView.height - inset)))
        } else {
            inset = scrollView.contentInset.bottom
            self.init(frame: CGRect(x: 0,
                                    y: UIScreen.main.bounds.height,
                                    width: scrollView.width,
                                    height: Refresher.contentSize))
        }
        self.position = position
        self.scrollView = scrollView
        autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleWidth]
        translatesAutoresizingMaskIntoConstraints = true
        backgroundColor = #colorLiteral(red: 0.5921568627, green: 0.2941176471, blue: 0.8745098039, alpha: 1)
        scrollView.addSubview(self)
        self.inset = inset
        contentMode = .center
        let selector = #selector(dragging(sender:))
        scrollView.panGestureRecognizer.addTarget(self, action: selector)
        add(contentView) { $0.center.equalTo(self) }
        contentView.add(spinner) {
            $0.center.equalTo(contentView)
            $0.size.equalTo(Refresher.contentSize * 1.5)
        }
        contentView.add(refreshIconView)
        strokeLayer.frame = refreshIconView.frame
        let size = strokeLayer.bounds.size.width/2
        strokeLayer.path = UIBezierPath(arcCenter: CGPoint(x: size, y: size),
                                        radius: size - 1,
                                        startAngle: -CGFloat(Double.pi/2),
                                        endAngle: 2*CGFloat(Double.pi) - CGFloat(Double.pi/2),
                                        clockwise: true).cgPath
        contentView.layer.addSublayer(strokeLayer)
        addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        spinner.center = contentView.centerBoundary
        refreshIconView.center = contentView.centerBoundary
        strokeLayer.frame = refreshIconView.frame
    }
    
    private lazy var spinner = specify(UIActivityIndicatorView(style: .gray), {
        $0.hidesWhenStopped = true
    })
 
    private lazy var contentView: UIView = {
        let size = Refresher.contentSize
        let frame = CGRect(x: 0, y: 0, width: size, height: size)
        let view = UIView(frame: frame)
        view.backgroundColor = .clear
        view.autoresizingMask = .flexibleTopMargin
        view.translatesAutoresizingMaskIntoConstraints = true
        return view
    }()
    
    private lazy var refreshIconView = specify(UILabel(frame: CGRect(x: 0, y: 0,width: 36, height: 36))) {
        $0.font = UIFont.systemFont(ofSize: 24.0)
        $0.text = "*"
        $0.textAlignment = .center
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 18
        $0.layer.borderWidth = 2
        $0.alpha = 0.25
        $0.isHidden = true
    }
    
    private lazy var strokeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeEnd = 0.0
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1
        layer.actions = ["strokeEnd":NSNull(),"hidden":NSNull()]
        return layer
    }()
    
    private var refreshable: Bool = false {
        didSet {
            if refreshable != oldValue {
                refreshIconView.alpha = refreshable ? 1.0 : 0.25
            }
        }
    }
    
    private var _refreshing: Bool = false
    private var offset: CGPoint = .zero
    
    private func setRefreshing(refreshing: Bool,
                               for refreshPosition: RefresherPosition,
                               with animated: Bool,
                               error: Error? = nil) {
        if _refreshing != refreshing {
            if refreshing {
                if refreshable && position == refreshPosition {
                    _refreshing = true
                    spinner.isHidden = false
                    isActivate = true
                    spinner.startAnimating()
                    setInset(inset: Refresher.contentSize, animated: animated)
                    if position == .top {
                        scrollView?.setMinimumContentOffsetAnimated(animated)
                    } else {
                        scrollView?.setMaximumContentOffsetAnimated(animated)
                        offset = CGPoint(x: scrollView?.maximumContentOffset.x ?? 0,
                                         y: (scrollView?.maximumContentOffset.y ?? 0) + 50)
                    }
                    UIView.performWithoutAnimation({ () -> Void in
                        self.sendActions(for: .valueChanged)
                    })
                }
            } else {
                _refreshing = false
                isHidden = true
                if position == .top {
                    scrollView?.setMinimumContentOffsetAnimated(animated)
                } else {
                    if error != nil {
                        scrollView?.setMaximumContentOffsetAnimated(animated)
                    } else {
                        scrollView?.setContentOffset(offset, animated: true)
                    }
                }
                scrollView?.contentInset = .zero
                spinner.stopAnimating()
                spinner.isHidden = true
                isActivate = false
            }
        }
    }
    
    private func setInset(inset: CGFloat, animated: Bool) {
        if let scrollView = scrollView {
            UIView.performAnimated(animated: animated, animation: {
                if position == .top {
                    scrollView.contentInset.top = inset + self.inset
                } else {
                    scrollView.contentInset.bottom = inset + self.inset
                }
            })
        }
    }
    
    @objc func dragging(sender: UIPanGestureRecognizer) {
        guard let scrollView = scrollView, isEnabled, !isActivate else {
            return
        }
        let offset = scrollView.contentOffset.y + inset
        
        if position == .bottom {
            self.y = scrollView.contentSize.height
        }
        var hidden = true
        if sender.state == .began {
            isHidden = false
            hidden = offset > 0
            refreshable = false
            if (!hidden) {
                contentView.center = CGPoint(x: width/2.0, y: height - Refresher.contentSize/2.0)
            }
        } else if sender.state == .changed {
            var ratio: CGFloat = 0.0
            if position == .top && offset <= 0 {
                ratio = max(0, min(1, -offset / (1.3 * Refresher.contentSize)))
            } else if scrollView.height + offset >= scrollView.contentSize.height {
                let offest = offset + scrollView.height - scrollView.contentSize.height
                ratio = min(1, max(0, offest/(1.3 * Refresher.contentSize)))
            }
            if (strokeLayer.strokeEnd != ratio) {
                strokeLayer.strokeEnd = ratio
            }
            hidden = false
            refreshable = ratio == 1
        } else if sender.state == .ended && refreshable {
            DispatchQueue.main.async { () -> Void in
                self.setRefreshing(refreshing: true,
                                   for: offset <= 0 ? .top : .bottom,
                                   with: true)
                self.refreshable = false
            }
        }
        if (hidden != refreshIconView.isHidden) {
            refreshIconView.isHidden = hidden
            strokeLayer.isHidden = hidden
        }
    }
    
    @objc func refresh(sender: Refresher) {
        scrollView?.isUserInteractionEnabled = false
        startRefreshingObservable.onNext(sender)
    }
    
    var style: RefresherStyle = .white {
        didSet {
            let color: UIColor?
            if style == .perple {
                color = #colorLiteral(red: 0.5921568627, green: 0.2941176471, blue: 0.8745098039, alpha: 1)
                backgroundColor = .white
            } else {
                color = .white
                backgroundColor = #colorLiteral(red: 0.5921568627, green: 0.2941176471, blue: 0.8745098039, alpha: 1)
            }
            if let color = color {
                refreshIconView.textColor = color
                strokeLayer.strokeColor = color.cgColor
                refreshIconView.layer.borderColor = color.cgColor
            }
        }
    }
}
