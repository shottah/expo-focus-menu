import UIKit

// MARK: - EmojiCollectionViewCell

class EmojiCollectionViewCell: UICollectionViewCell {
  let emojiLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    contentView.backgroundColor = .clear
    contentView.layer.cornerRadius = 20.0

    emojiLabel.textAlignment = .center
    emojiLabel.font = .systemFont(ofSize: 24)
    emojiLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(emojiLabel)

    NSLayoutConstraint.activate([
      emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    ])
  }

  override var isSelected: Bool {
    didSet {
      if isSelected {
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
      } else {
        contentView.backgroundColor = .clear
        transform = .identity
      }
    }
  }

  override var isHighlighted: Bool {
    didSet {
      if isHighlighted {
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
      } else {
        contentView.backgroundColor = .clear
        transform = .identity
      }
    }
  }
}

// MARK: - EmojiPickerView

class EmojiPickerView: UIView {
  // Default emojis if none provided - make it static so it can be accessed from ExpoFocusMenuView
  static let defaultEmojis = ["😀", "😂", "❤️", "👍", "🔥", "💯", "😍", "🎉", "👏", "✨"]

  var emojis: [String] = [] {
    didSet {
    // NSLog("🎯 EmojiPickerView emojis didSet: count=%d", emojis.count)
      collectionView?.reloadData()
    }
  }
  var selectedEmoji: String? {
    didSet {
    // NSLog("🎯 Selected emoji changed to: %@", selectedEmoji ?? "none")
      collectionView?.reloadData()
    }
  }
  var onEmojiSelected: ((String) -> Void)?


  private var collectionView: UICollectionView!
  private var blurView: UIVisualEffectView!
  private var backgroundView: UIView!

  init(frame: CGRect, emojis: [String]) {
    // Ensure proper UTF-8 encoding for emojis BEFORE calling super.init
    self.emojis = emojis.map { emoji in
      // Force re-encode the string to handle multi-byte UTF-8 properly
      if let data = emoji.data(using: .utf8),
         let reencoded = String(data: data, encoding: .utf8) {
        return reencoded
      }
      return emoji
    }

    super.init(frame: frame)

    // Debug logging
    // NSLog("🎯 EmojiPickerView initialized with %d emojis: %@", self.emojis.count, self.emojis.description)
    print("🎯 EmojiPickerView initialized with \(self.emojis.count) emojis: \(self.emojis)")

    // Verify each emoji with UTF-8 byte count
    for (index, emoji) in self.emojis.enumerated() {
    // NSLog("🎯 Emoji at index %d: '%@' (UTF-8 bytes: %d)", index, emoji, emoji.utf8.count)
    }

    setupView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Update shadow path for pill shape
    layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 28.0).cgPath
  }

  private func setupView() {
    backgroundColor = .clear

    // Create background view that can be styled
    backgroundView = UIView()
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.layer.cornerRadius = 28.0 // Default pill shape
    backgroundView.layer.masksToBounds = true
    addSubview(backgroundView)

    // Check if running on simulator
    #if targetEnvironment(simulator)
    // Simulator: Use solid background instead of blur effect
    blurView = UIVisualEffectView(effect: nil)
    blurView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.95)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    blurView.layer.cornerRadius = 28.0 // Pill shape
    blurView.layer.masksToBounds = true
    #else
    // Device: Use blur effect
    let blurEffect = UIBlurEffect(style: .systemMaterialDark)
    blurView = UIVisualEffectView(effect: blurEffect)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    blurView.layer.cornerRadius = 28.0 // Pill shape
    blurView.layer.masksToBounds = true
    #endif

    backgroundView.addSubview(blurView)

    NSLayoutConstraint.activate([
      backgroundView.topAnchor.constraint(equalTo: topAnchor),
      backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
      backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
      backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
      blurView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
      blurView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
      blurView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
      blurView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
    ])

    // Add dark overlay for better emoji visibility - matching react-native-focus-menu
    let darkOverlay = UIView()
    darkOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    darkOverlay.translatesAutoresizingMaskIntoConstraints = false
    blurView.contentView.addSubview(darkOverlay)

    NSLayoutConstraint.activate([
      darkOverlay.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
      darkOverlay.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
      darkOverlay.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
      darkOverlay.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
    ])

    // Setup collection view for emojis
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 4
    layout.minimumInteritemSpacing = 4
    layout.itemSize = CGSize(width: 40, height: 40)
    layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCell")

    // Add collection view on top of the dark overlay
    blurView.contentView.addSubview(collectionView)

    // Collection view constraints to self - matching Objective-C implementation
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    // Shadow for floating effect - matching UIMenu shadow
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.25
    layer.shadowRadius = 12.0
    layer.shadowOffset = CGSize(width: 0, height: 4)
    layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 28.0).cgPath

    // Force initial layout
    setNeedsLayout()
    layoutIfNeeded()

    // Reload data immediately and ensure it's visible
    collectionView.reloadData()

    // Double-check that emojis are set
    // NSLog("🎯 Before animation - emojis count: %d", emojis.count)

    // Animate in after setup is complete
    alpha = 0
    transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
      self.alpha = 1
      self.transform = .identity
    } completion: { _ in
      // Force another reload after animation to ensure cells are displayed
      self.collectionView.reloadData()
    // NSLog("🎯 After animation - collection view items: %d", self.collectionView.numberOfItems(inSection: 0))
    }
  }

  func hide(completion: (() -> Void)? = nil) {
    UIView.animate(withDuration: 0.2, animations: {
      self.alpha = 0
      self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }) { _ in
      self.removeFromSuperview()
      completion?()
    }
  }

  // Public method to reload emoji data
  func reloadData() {
    // NSLog("🎯 EmojiPickerView reloadData called with %d emojis", emojis.count)
    collectionView?.reloadData()
  }

}

// MARK: - UICollectionView DataSource & Delegate

extension EmojiPickerView: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let count = emojis.count
    // NSLog("🎯 numberOfItemsInSection called - returning %d emojis", count)
    print("🎯 numberOfItemsInSection called - returning \(count) emojis")
    return count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCollectionViewCell
    let emoji = emojis[indexPath.item]
    cell.emojiLabel.text = emoji

    // Ensure the label is visible
    cell.emojiLabel.isHidden = false

    // Show selection state
    if emoji == selectedEmoji {
      cell.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
      cell.contentView.layer.cornerRadius = 20.0
      cell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
    } else {
      cell.contentView.backgroundColor = .clear
      cell.contentView.layer.cornerRadius = 20.0
      cell.transform = .identity
    }

    // NSLog("🎯 Setting emoji at index %d: %@", indexPath.item, emoji)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let emoji = emojis[indexPath.item]

    // Haptic feedback
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.prepare()
    generator.impactOccurred()

    // Update selection state
    if selectedEmoji == emoji {
      // Deselect if already selected
      selectedEmoji = nil
    } else {
      // Select new emoji
      selectedEmoji = emoji
    }

    // Notify delegate (always notify, even for deselection)
    onEmojiSelected?(selectedEmoji ?? "")

    // Animate selection
    if let cell = collectionView.cellForItem(at: indexPath) {
      UIView.animate(withDuration: 0.1, animations: {
        cell.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
      }) { _ in
        UIView.animate(withDuration: 0.1) {
          cell.transform = self.selectedEmoji == emoji ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
        }
      }
    }
  }
}

