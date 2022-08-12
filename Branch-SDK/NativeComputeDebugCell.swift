import UIKit


@objc class NativeComputeDebugCell: UITableViewCell {

    weak var textView: UITextView!
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }

    func initialize() {
        // textview config
        let textView = UITextView(frame: .zero)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textAlignment = .left
        textView.backgroundColor = .lightGray
        textView.textColor = .black
        self.contentView.addSubview(textView)
        self.textView = textView
        
        
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.textView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.textView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.textView.text = nil
    }
}
