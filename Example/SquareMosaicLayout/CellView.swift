import UIKit

final class CellView: UICollectionViewCell {
    
    let imageView = UIImageView()
    var filterQueue: ImageFilterQueue?
    var downloadQueue: ImageDownloadQueue?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(imageView)
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        self.imageView.contentMode = .scaleAspectFill
        self.contentView.clipsToBounds = true
        filterQueue = ImageFilterQueue(with: DispatchQueue.global(qos: .default), completion: { (image, url) in
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image
            }
        })
        downloadQueue = ImageDownloadQueue(with: DispatchQueue.global(qos: .background), completion: { [weak filterQueue] (image, url) in
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image
            }
            guard let image = image else { return }
            filterQueue?.filter(image: image, url: url)
        })
        let url = URL(string: "https://pp.userapi.com/c636228/v636228551/19703/RujXN4WNJME.jpg")!
        downloadQueue?.download(url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var bounds: CGRect {
        didSet {
            contentView.frame = bounds
            imageView.frame = bounds
        }
    }
}

