//
//  ImageCropViewController.swift
//  ImageCrop
//
//  Created by yumaoda on 2014/10/31.
//  Copyright (c) 2014年 yumaoda. All rights reserved.
//

import UIKit

class ImageCropViewController: UIViewController {
    
    private let kPortraitSquareMaskRectInnerEdgeInset: CGFloat              = 20.0
    private let kPortraitCircleMaskRectInnerEdgeInset: CGFloat              = 15.0
    private let kPortraitCancelAndDoneButtonsHorizontalMargin: CGFloat      = 10.0
    private let kPortraitCancelAndDoneButtonsVerticalMargin: CGFloat        = 5.0
    private let kPortraitCancelAndDoneButtonsWidth: CGFloat                 = 105.0
    private let kPortraitCancelAndDoneButtonsHeight: CGFloat                = 40.0
    private let kPortraitBottomViewHeight: CGFloat                          = 50.0
    
    var originalImage: UIImage?
    
    var didFinishCroppedHandler: ((Image: UIImage) -> Void)?
    var didCancelHandler: (() -> Void)?
    
    enum CropMode {
        case circle
        case square
        case fullScreen
    }
    
    var cropMode: CropMode = CropMode.square
    
    // MARK: LifeCycle
    
    func initialize(image: UIImage, cropMode: CropMode, cropSize: CGSize) {
        self.originalImage = image
        self.cropMode = cropMode
        if cropSize == CGSizeZero {
            return
        }
        self.cropSize = (self.cropMode == .fullScreen) ? CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - self.kPortraitBottomViewHeight) : cropSize
    }
    
    convenience init(circleCropModeWithImage: UIImage) {
        self.init()
        self.initialize(circleCropModeWithImage, cropMode: ImageCropViewController.CropMode.circle, cropSize: CGSizeZero)
    }
    
    convenience init(squareCropModeWithImage: UIImage) {
        self.init()
        self.initialize(squareCropModeWithImage, cropMode: ImageCropViewController.CropMode.square, cropSize: CGSizeZero)
    }
    
    convenience init(fullScreenCropModeWithImage: UIImage) {
        self.init()
        self.initialize(fullScreenCropModeWithImage, cropMode: ImageCropViewController.CropMode.fullScreen, cropSize: CGSizeZero)
    }
    
    convenience init(circleCropModeWithImage: UIImage, cropSize: CGSize) {
        self.init()
        self.initialize(circleCropModeWithImage, cropMode: ImageCropViewController.CropMode.circle, cropSize: cropSize)
    }
    
    convenience init(squareCropModeWithImage: UIImage, cropSize: CGSize) {
        self.init()
        self.initialize(squareCropModeWithImage, cropMode: ImageCropViewController.CropMode.square, cropSize: cropSize)
    }
    
    convenience init(fullScreenCropModeWithImage: UIImage, cropSize: CGSize) {
        self.init()
        self.initialize(fullScreenCropModeWithImage, cropMode: ImageCropViewController.CropMode.fullScreen, cropSize: cropSize)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.configure()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configure() {
        self.view.backgroundColor = UIColor.blackColor()
        self.view.clipsToBounds = true
        
        self.view.addSubview(self.imageScrollView)
        self.view.addSubview(self.overlayView!)
        self.view.addGestureRecognizer(self.doubleTapGestureRecognizer)
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.view.addSubview(self.bottomView)
        self.bottomView.addSubview(self.cancelButton)
        self.bottomView.addSubview(self.doneButton)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.layoutImageScrollView()
        self.layoutOverlayView()
        self.updateMaskPath()
        self.view.setNeedsUpdateConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.imageScrollView.imageView == nil {
            self.displayImage()
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // bottomView
        var constaraint: NSLayoutConstraint = NSLayoutConstraint(item: self.bottomView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal,
            toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: self.kPortraitBottomViewHeight)
        self.view.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.bottomView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal,
            toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.bottomView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal,
            toItem: self.view, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.bottomView, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal,
            toItem: self.view, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(constaraint)
        
        // cancelButton
        constaraint = NSLayoutConstraint(item: self.cancelButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal,
            toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: self.kPortraitCancelAndDoneButtonsWidth)
        self.cancelButton.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.cancelButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal,
            toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: self.kPortraitCancelAndDoneButtonsHeight)
        self.cancelButton.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.cancelButton, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal,
            toItem: self.bottomView, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: self.kPortraitCancelAndDoneButtonsHorizontalMargin)
        self.bottomView.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.cancelButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal,
            toItem: self.bottomView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: -self.kPortraitCancelAndDoneButtonsVerticalMargin)
        self.bottomView.addConstraint(constaraint)
        
        // doneButton
        constaraint = NSLayoutConstraint(item: self.doneButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal,
            toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: self.kPortraitCancelAndDoneButtonsWidth)
        self.doneButton.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.doneButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal,
            toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: self.kPortraitCancelAndDoneButtonsHeight)
        self.doneButton.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.doneButton, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal,
            toItem: self.bottomView, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: -self.kPortraitCancelAndDoneButtonsHorizontalMargin)
        self.bottomView.addConstraint(constaraint)
        constaraint = NSLayoutConstraint(item: self.doneButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal,
            toItem: self.bottomView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: -self.kPortraitCancelAndDoneButtonsVerticalMargin)
        self.bottomView.addConstraint(constaraint)
    }
    
    // MARK: Custom Accessors
    
    lazy var bottomView: UIView! = {
        self.bottomView = UIView()
        self.bottomView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        self.bottomView.userInteractionEnabled = true
        self.bottomView.translatesAutoresizingMaskIntoConstraints = false
        return self.bottomView;
        }()
    
    lazy var doneButton: UIButton! = {
        self.doneButton = UIButton()
        self.doneButton.setTitle(NSLocalizedString("ImageCrop.button.done", tableName: "ImageCropLocalizable", comment: ""), forState: UIControlState.Normal)
        self.doneButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        self.doneButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        self.doneButton.backgroundColor = UIColor(red: 38.0/255.0, green: 193.0/255.0, blue: 85.0/255.0, alpha: 1.0)
        self.doneButton.addTarget(self, action: "handleDoneButton:", forControlEvents: UIControlEvents.TouchUpInside)
        self.doneButton.translatesAutoresizingMaskIntoConstraints = false
        self.doneButton.layer.cornerRadius = 3.0
        return self.doneButton
        }()
    
    lazy var cancelButton: UIButton! = {
        self.cancelButton = UIButton()
        self.cancelButton.setTitle(NSLocalizedString("ImageCrop.button.cancel", tableName: "ImageCropLocalizable", comment: ""), forState: UIControlState.Normal)
        self.cancelButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        self.cancelButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        self.cancelButton.backgroundColor = UIColor.clearColor()
        self.cancelButton.addTarget(self, action: "handleCancelButton:", forControlEvents: UIControlEvents.TouchUpInside)
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        self.cancelButton.layer.cornerRadius = 3.0;
        return self.cancelButton
        }()
    
    lazy var imageScrollView: ImageCropScrollView = {
        self.imageScrollView = ImageCropScrollView(frame: CGRectZero)
        self.imageScrollView.clipsToBounds = false
        return self.imageScrollView
        }()
    
    lazy var overlayView: ImageCropTouchView? = {
        self.overlayView = ImageCropTouchView(frame: CGRectZero)
        self.overlayView?.receiver = self.imageScrollView;
        self.overlayView?.layer.addSublayer(self.maskLayer!)
        return self.overlayView
        }()
    
    lazy var maskLayer: CAShapeLayer? = {
        self.maskLayer = CAShapeLayer()
        self.maskLayer!.fillRule = kCAFillRuleEvenOdd
        self.maskLayer!.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).CGColor
        return self.maskLayer
        }()
    
    lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleDoubleTap:")
        self.doubleTapGestureRecognizer.delaysTouchesEnded = false
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        return self.doubleTapGestureRecognizer
        }()
    
    lazy var cropSize: CGSize? = {
        let viewWidth: CGFloat = CGRectGetWidth(self.view.bounds)
        let viewHeight: CGFloat = CGRectGetHeight(self.view.bounds)
        
        switch (self.cropMode) {
        case .circle:
            var diameter: CGFloat = min(viewWidth, viewHeight) - self.kPortraitCircleMaskRectInnerEdgeInset * 2
            self.cropSize = CGSizeMake(diameter, diameter)
        case .square:
            var length: CGFloat = min(viewWidth, viewHeight) - self.kPortraitSquareMaskRectInnerEdgeInset * 2
            self.cropSize = CGSizeMake(length, length)
        case .fullScreen:
            self.cropSize = CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - self.kPortraitBottomViewHeight)
        }
        return self.cropSize
        }()
    
    // MARK: Action Handling
    
    func handleDoneButton(sender: AnyObject) {
        self.cropImage()
        self.doneButton.enabled = false
    }
    
    func handleCancelButton(sender: AnyObject) {
        self.didCancelHandler?()
        self.cancelButton.enabled = false
    }
    
    func handleDoubleTap(sender: UIGestureRecognizer) {
        // zoom
        self.resetZoomScale(true)
        self.resetContentOffset(true)
    }
    
    // MARK: Private
    
    private func resetZoomScale(animated: Bool) {
        var zoomScale: CGFloat
        if CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds) {
            zoomScale = CGRectGetHeight(self.view.bounds) / self.originalImage!.size.height
        } else {
            zoomScale = CGRectGetWidth(self.view.bounds) / self.originalImage!.size.width;
        }
        self.imageScrollView.setZoomScale(zoomScale, animated: animated)
    }
    
    private func resetContentOffset(animated: Bool) {
        let boundsSize: CGSize = self.imageScrollView.bounds.size;
        let frameToCenter: CGRect = self.imageScrollView.imageView!.frame;
        
        var contentOffset: CGPoint = CGPointZero
        if CGRectGetWidth(frameToCenter) > boundsSize.width {
            contentOffset.x = (CGRectGetWidth(frameToCenter) - boundsSize.width) * 0.5;
        } else {
            contentOffset.x = 0;
        }
        if CGRectGetHeight(frameToCenter) > boundsSize.height {
            contentOffset.y = (CGRectGetHeight(frameToCenter) - boundsSize.height) * 0.5;
        } else {
            contentOffset.y = 0;
        }
        self.imageScrollView.setContentOffset(contentOffset, animated: animated)
    }
    
    private func displayImage() {
        if (self.originalImage != nil) {
            self.imageScrollView.scrollImage = self.originalImage!
            self.resetZoomScale(false)
        }
    }
    
    private func layoutImageScrollView() {
        self.imageScrollView.frame = self.maskRect()
    }
    
    private func maskRect () -> CGRect {
        let originY: CGFloat = (self.cropMode == CropMode.fullScreen) ? 0 : (CGRectGetHeight(self.view.frame) - self.cropSize!.height) * 0.5
        let maskRect: CGRect = CGRectMake((CGRectGetWidth(self.view.frame) - self.cropSize!.width) * 0.5,
            originY,
            self.cropSize!.width,
            self.cropSize!.height)
        return maskRect
    }
    
    private func layoutOverlayView() {
        let frame: CGRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds) * 2, CGRectGetHeight(self.view.bounds) * 2)
        self.overlayView?.frame = frame;
    }
    
    private func updateMaskPath() {
        let clipPath: UIBezierPath = UIBezierPath(rect: self.overlayView!.frame)
        
        var maskPath: UIBezierPath? = nil
        switch (self.cropMode) {
        case .circle:
            maskPath = UIBezierPath(ovalInRect: self.maskRect())
        case .square ,.fullScreen:
            maskPath = UIBezierPath(rect: self.maskRect())
        }
        clipPath.appendPath(maskPath!)
        clipPath.usesEvenOddFillRule = true
        
        let pathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.duration = CATransaction.animationDuration()
        pathAnimation.timingFunction = CATransaction.animationTimingFunction()
        
        self.maskLayer!.path = clipPath.CGPath
    }
    
    private func cropRect() -> CGRect {
        var cropRect: CGRect = CGRectZero
        let zoomScale: CGFloat = 1.0 / self.imageScrollView.zoomScale
        cropRect.origin.x = self.imageScrollView.contentOffset.x * zoomScale;
        cropRect.origin.y = self.imageScrollView.contentOffset.y * zoomScale;
        cropRect.size.width = CGRectGetWidth(self.imageScrollView.bounds) * zoomScale;
        cropRect.size.height = CGRectGetHeight(self.imageScrollView.bounds) * zoomScale;
        
        return cropRect
    }
    
    private func croppedImage(image: UIImage, cropRect: CGRect) -> UIImage {
        let image = image.fixImageOrientation()
        let croppedCGImage: CGImageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect)!
        let croppedImage: UIImage = UIImage(CGImage: croppedCGImage, scale: UIScreen.mainScreen().scale, orientation: image.imageOrientation)
        return croppedImage
    }
    
    private func cropImage() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            if let image = self.originalImage {
                let image = self.croppedImage(image, cropRect: self.cropRect())
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.didFinishCroppedHandler?(Image: image)
                    return
                })
            }
        })
    }
    
    class ImageCropScrollView: UIScrollView,UIScrollViewDelegate {
        
        private var _imageSize: CGSize = CGSizeZero
        private var _pointToCenterAfterResize: CGPoint = CGPointZero
        private var _scaleToRestoreAfterResize: CGFloat = 0
        
        var imageView: UIImageView?
        private var _image: UIImage?
        
        var scrollImage: UIImage? {
            get {
                return _image
            }
            set (image){
                self.imageView?.removeFromSuperview()
                self.imageView = nil
                
                self.zoomScale = 1.0
                self.imageView = UIImageView(image: image)
                self.addSubview(self.imageView!)
                self.configureForImageSize(image?.size ?? CGSizeZero)
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.configureView()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.configureView()
        }
        
        private func configureView() {
            self.showsVerticalScrollIndicator = false;
            self.showsHorizontalScrollIndicator = false;
            self.bouncesZoom = true;
            self.alwaysBounceHorizontal = true
            self.alwaysBounceVertical = true
            self.scrollsToTop = false;
            self.decelerationRate = UIScrollViewDecelerationRateFast;
            self.delegate = self;
            self.translatesAutoresizingMaskIntoConstraints = false
            self.imageView?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        override var frame: CGRect {
            get {
                return super.frame
            }
            set (frame){
                let sizeChanging: Bool = !CGSizeEqualToSize(frame.size, self.frame.size)
                
                if sizeChanging {
                    self.prepareForResize()
                }
                
                super.frame = frame
                
                if sizeChanging {
                    self.recoverFromResizing()
                }
            }
        }
        
        private func configureForImageSize(imageSize: CGSize) {
            _imageSize = imageSize;
            self.contentSize = imageSize;
            self.setMaxMinZoomScalesForCurrentBounds()
            self.setInitialZoomScale()
            self.setInitialContentOffset()
        }
        
        private func setInitialZoomScale() {
            let boundsSize = self.bounds.size;
            if !CGSizeEqualToSize(_imageSize, CGSizeZero) {
                let xScale = boundsSize.width  / _imageSize.width;
                let yScale = boundsSize.height / _imageSize.height;
                let scale = max(xScale, yScale);
                self.minimumZoomScale = scale
                self.zoomScale = scale;
            }
        }
        
        private func setInitialContentOffset() {
            if let imageView = self.imageView {
                let boundsSize = self.bounds.size;
                let frameToCenter = imageView.frame;
                var contentOffset = self.contentOffset;
                contentOffset.x = (frameToCenter.size.width - boundsSize.width) / 2.0;
                contentOffset.y = (frameToCenter.size.height - boundsSize.height) / 2.0;
                self.contentOffset = contentOffset
            }
        }
        
        private func prepareForResize() {
            if let imageView = self.imageView {
                let boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
                if #available(iOS 8.0, *) {
                    _pointToCenterAfterResize = self.convertPoint(boundsCenter, fromCoordinateSpace: imageView)
                } else {
                    _pointToCenterAfterResize = self.convertPoint(boundsCenter, fromView: imageView)
                }
                _scaleToRestoreAfterResize = self.zoomScale
                
                if _scaleToRestoreAfterResize <= self.minimumZoomScale + CGFloat(FLT_EPSILON) {
                    _scaleToRestoreAfterResize = 0
                }
            }
        }
        
        private func recoverFromResizing() {
            self.setMaxMinZoomScalesForCurrentBounds()
            
            let maxZoomScale = max(self.minimumZoomScale, _scaleToRestoreAfterResize)
            self.zoomScale = min(self.maximumZoomScale, maxZoomScale)
            
            let boundsCenter = self.convertPoint(_pointToCenterAfterResize, fromView: self.imageView)
            
            var offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                boundsCenter.y - self.bounds.size.height / 2.0);
            
            let maxOffset = self.maximumContentOffset()
            let minOffset = self.minimumContentOffset()
            
            var realMaxOffset = min(maxOffset.x, offset.x);
            offset.x = max(minOffset.x, realMaxOffset)
            
            realMaxOffset = min(maxOffset.y, offset.y)
            offset.y = max(minOffset.y, realMaxOffset)
            
            self.contentOffset = offset
        }
        
        private func setMaxMinZoomScalesForCurrentBounds() {
            
            let boundsSize = self.bounds.size
            
            let xScale = boundsSize.width  / _imageSize.width
            let yScale = boundsSize.height / _imageSize.height
            var minScale = max(xScale, yScale)
            var maxScale = max(xScale, yScale)
            
            
            let xImageScale = maxScale*_imageSize.width / boundsSize.width
            let yImageScale = maxScale*_imageSize.height / boundsSize.width
            var maxImageScale = max(xImageScale, yImageScale)
            
            maxImageScale = max(minScale, maxImageScale)
            maxScale = max(maxScale, maxImageScale)
            
            if (minScale > maxScale) {
                minScale = maxScale
            }
            
            self.maximumZoomScale = maxScale
            self.minimumZoomScale = minScale
        }
        
        private func updateImageViewCenter() {
            let centerX = max(self.contentSize.width, self.bounds.size.width)/2
            let centerY = max(self.contentSize.height, self.bounds.size.height)/2
            self.imageView?.center.x = centerX
            self.imageView?.center.y = centerY
        }
        
        private func maximumContentOffset() -> CGPoint{
            let contentSize = self.contentSize;
            let boundsSize = self.bounds.size;
            return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
        }
        
        private func minimumContentOffset() -> CGPoint {
            return CGPointZero;
        }
        
        // MARK: - UIScrollViewDelegate
        func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
            return self.imageView
        }
        func scrollViewDidScroll(scrollView: UIScrollView) {
            self.updateImageViewCenter()
        }
    }
    
    class ImageCropTouchView: UIView {
        
        var receiver: UIView?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
            if self.pointInside(point, withEvent: event) {
                return self.receiver
            }
            return nil
        }
    }
}

extension UIImage {
    func fixImageOrientation() -> UIImage {
        
        // No-op if the orientation is already correct.
        if self.imageOrientation == UIImageOrientation.Up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransformIdentity
        
        switch self.imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2));
        default:
            break
        }
        
        switch self.imageOrientation {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
        default:
            break
        }
        
        let ctx: CGContextRef = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height),
            CGImageGetBitsPerComponent(self.CGImage), 0,
            CGImageGetColorSpace(self.CGImage),
            CGImageGetBitmapInfo(self.CGImage).rawValue)!
        
        CGContextConcatCTM(ctx, transform)
        switch self.imageOrientation {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.height, self.size.width), self.CGImage)
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage)
        }
        
        // And now we just create a new UIImage from the drawing context.
        let cgimg: CGImageRef! = CGBitmapContextCreateImage(ctx);
        let img: UIImage = UIImage(CGImage: cgimg)
        return img;
    }
}