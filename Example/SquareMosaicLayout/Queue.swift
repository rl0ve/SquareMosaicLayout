import Foundation
import UIKit

class ImageQueue: OperationQueue {
    
    fileprivate let completion: (UIImage?, URL) -> ()
    
    init(with queue: DispatchQueue, completion: @escaping (UIImage?, URL) -> ()) {
        self.completion = completion
        super.init()
        self.maxConcurrentOperationCount = 1
        self.underlyingQueue = queue
    }
}

final class ImageDownloadQueue: ImageQueue {
    
    func download(url: URL) {
        let operation = ImageDownloadOperation(url: url, completion: completion)
        addOperation(operation)
    }
}

final class ImageFilterQueue: ImageQueue {
    
    func filter(image: UIImage, url: URL) {
        let operation = ImageFilterOperation(image: image, url: url, completion: completion)
        addOperation(operation)
    }
}

fileprivate final class ImageDownloadOperation: Operation {
    
    fileprivate let completion: (UIImage?, URL) -> ()
    fileprivate var image: UIImage? = nil
    fileprivate let url: URL
    
    init(url: URL, completion: @escaping (UIImage?, URL) -> ()) {
        self.completion = completion
        self.url = url
        super.init()
        self.completionBlock = { [url, weak operation = self] () -> Void in
            guard operation?.isCancelled ?? false == false else { return }
            completion(operation?.image, url)
        }
    }
    
    override func main() {
        guard self.isCancelled == false else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        image = UIImage(data: data)
    }
}

fileprivate final class ImageFilterOperation: Operation {
    
    fileprivate let completion: (UIImage?, URL) -> ()
    fileprivate var image: UIImage? = nil
    fileprivate let imageOriginal: UIImage
    fileprivate let url: URL
    
    init(image: UIImage, url: URL, completion: @escaping (UIImage?, URL) -> ()) {
        self.completion = completion
        self.imageOriginal = image
        self.url = url
        super.init()
        self.completionBlock = { [url, weak operation = self] () -> Void in
            guard operation?.isCancelled ?? false == false else { return }
            completion(operation?.image, url)
        }
    }
    
    override func main() {
        guard self.isCancelled == false else { return }
        guard let data = UIImagePNGRepresentation(imageOriginal) else { return }
        let inputImage = CIImage(data: data)
        let context = CIContext(options:nil)
        guard let filter = CIFilter(name:"CISepiaTone") else { return }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: "inputIntensity")
        guard let outputImage = filter.outputImage else { return }
        guard let image = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        self.image = UIImage(cgImage: image)
    }
}
