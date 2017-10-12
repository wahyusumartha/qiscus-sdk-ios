# UI Customization

## Theme Customization
Lots of our items inside Chat Room can be modified based on our needs, here is
the example of the customisation that can be done easily
```swift
let qiscusColor = Qiscus.style.color
qiscusColor.welcomeIconColor = colorConfig.chatWelcomeIconColor
qiscusColor.leftBaloonColor = colorConfig.chatLeftBaloonColor
qiscusColor.leftBaloonTextColor = colorConfig.chatLeftBaloonTextColor
qiscusColor.leftBaloonLinkColor = colorConfig.chatLeftBaloonLinkColor
qiscusColor.rightBaloonColor = colorConfig.chatRightBaloonColor
qiscusColor.rightBaloonTextColor = colorConfig.chatRightTextColor

Qiscus.setNavigationColor(colorConfig.baseNavigateColor, tintColor: colorConfig.baseNavigateTextColor)

let fontSize: CGFloat = CGFloat(17).flexibleIphoneFont()
Qiscus.style.chatFont = UIFont.systemFont(ofSize: fontSize)
```

## UI Source Code
If you want full customisations, you can modify everything on the view by
extend our `QiscusChatVC` based on your needs.

here is sample of midification by extending our `QiscusChatVC`:
```swift
class QChatView: QiscusChatVC {
    var actions : [ChatAction]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // self.collectionViewTopMargin.constant = 100
        self.backgroundView.isHidden    = true

        let iconCall        = UIImage(named: "ic_phone_call", in: QChat.bundle, compatibleWith: nil)
        let iconCallVideo   = UIImage(named: "ic_video_call", in: QChat.bundle, compatibleWith: nil)
        let iconEnd         = UIImage(named: "ic_end_consultation", in: QChat.bundle, compatibleWith: nil)

        let endButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        endButton.setBackgroundImage(iconEnd, for: .normal)
        endButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        endButton.addTarget(self, action: #selector(endConsultation), for: .touchUpInside)
        let barButtonEnd    = UIBarButtonItem(customView: endButton)

        let callButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        callButton.setBackgroundImage(iconCall, for: .normal)
        callButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        callButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        let barButtonCall    = UIBarButtonItem(customView: callButton)

        let callVideoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        callVideoButton.setBackgroundImage(iconCallVideo, for: .normal)
        callVideoButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        callVideoButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        let barButtonCallVideo    = UIBarButtonItem(customView: callVideoButton)

        navigationItem.rightBarButtonItems = [barButtonEnd, barButtonCallVideo, barButtonCall]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    func addTapped() {
        print("something")
    }

    func endConsultation() {
        postComment(type: "endConsultation", payload: "Semoga Lekas sembuh")
    }

    func postComment(type: String, payload: String) {
        let newComment = self.chatRoom?.newCustomComment(type: type, payload: payload, text: "Pesan Doktor")
        self.chatRoom?.post(comment: newComment!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
}
```
