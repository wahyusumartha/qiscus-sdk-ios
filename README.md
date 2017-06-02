# Qiscus SDK iOS

# Quick Start

### Create a new app

Register on [https://dashboard.qiscus.com](https://dashboard.qiscus.com/) using your email and password and then create new application

You should create one application per service, regardless of the platform. For example, an app released in both Android and iOS would require only one application to be created in the Dashboard.

All users within the same Qiscus application are able to communicate with each other, across all platforms. This means users using iOS, Android, web clients, etc. can all chat with one another. However, users in different Qiscus applications cannot talk to each other.

Done! Now you can use the APP_ID into your apps and get chat functionality by implementing Qiscus into your app.


### integrating SDK with an existing app

[CocoaPods](http://cocoapods.org/) is a dependency manager for Cocoa projects. You can install it with the following command:


```
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required.

Podfile :

```
target 'Sample' do

  .....
  use_frameworks!

  .....
  pod 'Qiscus'
  .....

end

```

Install Qiscus through CocoaPods

```
$ pod install
```

# Authentication

### Init with App ID

To initiate Qiscus SDK, you need to import Qiscus and then add this in your code everywhere you want

**Swift 3.0:**

```
import Qiscus


Qiscus.setup( withAppId: YOUR_APP_ID, 
              userEmail: CURRENT_USER_EMAIL, 
              userKey: CURRENT_USER_PASSWORD, 
              username: CURRENT_USER_USERNAME, 
              avatarURL: CURRENT_USER_AVATAR_URL, 
              delegate: self
)
```

**Using the  SDK in Objective-C**


```
import Qiscus

[Qiscus setupWithAppId:<YOUR_APP_ID> 
        userEmail:<USER_EMAIL> 
        userKey:<USER_KEY> 
        username:<USER_NAME> 
        avatarURL:<USER_AVATAR_URL> 
        delegate:self 
        secureURl:<true|false>];
```


**Example on AppDelegate.swift**


```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        Qiscus.setup( withAppId: "DragonGo",
                      userEmail: "abcde@qiscus.coom",
                      userKey: "abcd1234",
                      username: "Steve Kusuma",
                      avatarURL: "",
                      delegate: nil
        )
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
}
```

### Updating a User Profile and Avatar

Updating user profile and details is simply by re-init the user using new details :


```
        Qiscus.setup( withAppId: "DragonGo",
                      userEmail: "abcde@qiscus.coom",
                      userKey: "abcd1234",
                      username: "Steve Kusuma New Name",
                      avatarURL: "https://myimage.com/myNewImage.png",
                      delegate: nil
        )
```

# Room Types 

### Creating and starting 1-to-1 chat

Start chat with target is very easy, all you need is just call

Swift 3.0 :

```
      let email = targetField.text!
      let view = Qiscus.chatView(withUsers: [email])
      self.navigationController?.pushViewController(view, animated: true)
```



in your code

For example in your ViewController :

Swift 3.0:

```
import UIKit
import Qiscus

class ViewController: UIViewController {

.....

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(frame: CGRect(x: 100, y:100, width:100, height:30))
        button.backgroundColor = UIColor.green
        button.setTitle("Start Chat", for: .normal)
        button.addTarget(self, action: #selector(ViewController.startChat), for: .touchUpInside)
        self.view.addSubview(button)
        
    }
    
    func startChat(){
        let email = targetField.text!
        let view = Qiscus.chatView(withUsers: [email])
        self.navigationController?.pushViewController(view, animated: true)
    }

.....
}
```



### Creating a Group Room

Qiscus also support group chat. To create new group chat, all you need is just call

Swift 3.0:

`Qiscus.createChat(withUsers users:["TARGET_EMAIL_1, TARGET_EMAIL_2"], target:self)`

Objective C:

`[Qiscus createChatViewWithUsers:<ARRAY_OF_TARGET_EMAIL> target:self readOnly:<false|true> title:<CHAT_TITLE> subtitle:<CHAT_SUBTITLE> distinctId:NULL optionalData:NULL withMessage:NULL]`

For example in your ViewController :

Swift 3.0

```
import UIKit
import Qiscus

class ViewController: UIViewController {

    .....
    func goToChat(){
        let chatTargets = ["081111111111@qiscuswa.com, 081234567890@qiscuswa.com"]
        Qiscus.createChat(withUsers:chatTargets, target:self)
    }
    .....
}
```


for accesing room that created by this call, you need to call it with its roomId. This methode is always creating new chat room.


### Getting a Group Room instance with room id


When you already know your chat room id, you can easily go to that room. Just call

Swift 3.0:

`Qiscus.chatView(withRoomId: roomId)`


For example in your ViewController :

Swift 3.0

```
import UIKit
import Qiscus

class ViewController: UIViewController {

.....

  func goToChat(){
          let roomId = Int(targetField.text!)
          let view = Qiscus.chatView(withRoomId: roomId)
          self.navigationController?.pushViewController(view, animated: true)
  }

.....
}
```



### Inviting users to an existing Room

Currently we recommend to invite user into existing room through our **REST API** for simplicity and security reason

### Leaving a Group Room

Currently we recommend to kick user out of specific room through our **REST API** for simplicity and security reason

# Event Handler

**QiscusConfigDelegate**

```
class MainView: UIViewController, QiscusConfigDelegate {

    // MARK: - QiscusConfigDelegate
    func qiscusFailToConnect(_ withMessage:String){
        print(withMessage)
        ...
    }
    func qiscusConnected(){
        appDelegate.goToChatNavigationView()
        ...
    }
}
```


**QiscusRoomDelegate**

```
class SampleAppRealtime: QiscusRoomDelegate {
    
    // MARK: - Member of QiscusRoomDelegate
    internal func gotNewComment(_ comments: QiscusComment) {
        print("getting new messages")
    }
    
    internal func didFinishLoadRoom(onRoom room: QiscusRoom) {
        print("did finish load roomId: \(localRoom.roomId), roomName: \(localRoom.roomName)")
    }
    
    internal func didFailLoadRoom(withError error: String) {
        print("did fail load room error: \(error)")
    }

    func didFinishUpdateRoom(onRoom room: QiscusRoom) {
        print("did finish update room roomId: \(localRoom.roomId), roomName: \(localRoom.roomName)")
    }
    
    func didFailUpdateRoom(withError error:String) {
        print("did fail update room: \(error)")
    }
    
}
```

# UI Customization

### Theme Customization

Lots of our items inside Chat Room can be modified based on our needs, here is the example of the customisation that can be done easily

```
 
  let qiscusColor = Qiscus.style.color
  qiscusColor.welcomeIconColor = colorConfig.chatWelcomeIconColor
  qiscusColor.leftBaloonColor = colorConfig.chatLeftBaloonColor
  qiscusColor.leftBaloonTextColor = colorConfig.chatLeftTextColor
  qiscusColor.leftBaloonLinkColor = colorConfig.chatLeftBaloonLinkColor
  qiscusColor.rightBaloonColor = colorConfig.chatRightBaloonColor
  qiscusColor.rightBaloonTextColor = colorConfig.chatRightTextColor
        
  Qiscus.setNavigationColor(colorConfig.baseNavigateColor, tintColor: colorConfig.baseNavigateTextColor)

  let fontSize: CGFloat = CGFloat(17).flexibleIphoneFont()
  Qiscus.style.chatFont = UIFont.systemFont(ofSize: fontSize)
  
```

### UI Source code

If you want full customisations, you can modify everything on the view by forking our repository or just right away modifying our[ QiscusUIConfiguration.swift](https://github.com/qiscus/qiscus-sdk-ios/blob/master/Qiscus/Qiscus/QiscusUIConfiguration.swift) and [QiscusTextConfiguration.swift](https://github.com/qiscus/qiscus-sdk-ios/blob/master/Qiscus/Qiscus/QiscusTextConfiguration.swift)** **based on your needs.

# Push Notifications 

Currently we recommend to use our Webhook-API to push notification from your own server to client app for simplicity and flexibility handling

# Notes

Don't forget to add usage description for camera, photo library and microphone to your **info.plist **to use our attachment functionality in chat SDK
