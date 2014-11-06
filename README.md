ImageCrop
=========

crop image

https://github.com/ruslanskorb/RSKImageCropper
を参考に。

## HowTo

#### 初期化方法
```swift
// 四角で切り取る
let imageCropVC = ImageCropViewController(squareCropModeWithImage: image)

// 円で切り取る
let imageCropVC = ImageCropViewController(circleCropModeWithImage: image)

// 全画面で切り取る
let imageCropVC = ImageCropViewController(fullScreenCropModeWithImage: image)
```
切り取り枠をサイズ指定する場合(CGSizeで指定)
```swift
// 四角
let imageCropVC = ImageCropViewController(squareCropModeWithImage: image, cropSize: CGSizeMake(width, height))

// 円
let imageCropVC = ImageCropViewController(circleCropModeWithImage: image, cropSize: CGSizeMake(widht, height))
```

#### ボタンハンドリング
・キャンセルボタンハンドリング
```swift
imageCropVC.didCancelHandler = { () -> Void in
            // 処理内容
        }
```
・完了ボタンハンドリング
```swift
imageCropVC.didFinishCroppedHandler = { (image: UIImage) -> Void in
            // 処理内容
        }
```
