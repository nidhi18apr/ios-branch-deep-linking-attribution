import UIKit


@objc class NativeComputeDebugButtonCell: UITableViewCell {

    weak var textView: UITextView!
    weak var processConfigUrlsButton: UIButton!
    
    var buttonTapCallback: () -> ()  = { }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    @objc func didTapButton() {
        buttonTapCallback()
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
        
        // button config
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Process All Config URLs", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.lightGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isEnabled = true
        button.isUserInteractionEnabled = true
        self.contentView.addSubview(button)
        self.processConfigUrlsButton = button
        self.processConfigUrlsButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.contentView.isUserInteractionEnabled = true
        self.contentView.isMultipleTouchEnabled = true


        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.textView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            
            self.processConfigUrlsButton.topAnchor.constraint(equalTo: self.textView.bottomAnchor),
            self.processConfigUrlsButton.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.processConfigUrlsButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.processConfigUrlsButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.textView.text = nil
    }
}
