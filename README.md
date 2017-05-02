Qiscus SDK [![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Qiscus.svg)](https://img.shields.io/cocoapods/v/qiscus-sdk-ios.svg)
======
<p align="center"><img src="https://res.cloudinary.com/qiscus/raw/upload/v1485736947/1485736946/Screen%20Shot%202017-01-30%20at%207.26.07%20AM.png" width="30%" /> <img src="https://res.cloudinary.com/qiscus/raw/upload/v1485736958/1485736957/Screen%20Shot%202017-01-30%20at%207.26.59%20AM.png" width="30%" /> <img src="https://res.cloudinary.com/qiscus/raw/upload/v1485736969/1485736967/Screen%20Shot%202017-01-30%20at%207.41.09%20AM.png" width="30%" />
</p>

Qiscus SDK is a lightweight and powerful chat library. Qiscus SDK will allow you to easily integrating Qiscus engine with your apps to make cool chatting application.

# Quick Start
## Requirements

- iOS 9.0+ 
- Xcode 8.0+
- Swift 3.0+
### Create a new SDK application in the Dashboard and get app_id 
[**Request access**](http://sdk.qiscus.com/start.html) to get new Qiscus APP_ID
### Integrating SDK with an existing app 
##### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```
> CocoaPods 1.1.0+ is required.

Podfile file : 

```
target 'Sample' do

  .....
  use_frameworks!

  .....
  pod 'Qiscus'
  .....

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'YES'
        config.build_settings['SWIFT_VERSION'] = '3.0'
      end
    end
  end
end
```


# Authentication 
### Initializing with APP_ID
To initiate Qiscus SDK, you need to import Qiscus and then add this in your code everywhere you want

##### Swift 3.0:

```
Qiscus.setup( withAppId: YOUR_APP_ID, 
              userEmail: CURRENT_USER_EMAIL, 
              userKey: CURRENT_USER_PASSWORD, 
              username: CURRENT_USER_USERNAME, 
              avatarURL: CURRENT_USER_AVATAR_URL, 
              delegate: self
)
```
##### Objective C

```
[Qiscus setupWithAppId:<YOUR_APP_ID> 
        userEmail:<USER_EMAIL> 
        userKey:<USER_KEY> 
        username:<USER_NAME> 
        avatarURL:<USER_AVATAR_URL> 
        delegate:self 
        secureURl:<true|false>];
```



For example : 
##### Swift 3.0:

```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
// Override point for customization after application launch.

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

##### Objective C:
```
@import Qiscus;
#import "ViewController.h"

@interface ViewController ()
...
...
@end

@implementation ViewController

...

- (void)login {
NSLog(@"Login");
[Qiscus setupWithAppId:@"qisme" 
userEmail:@"081111111111@qiscuswa.com" 
userKey:@"passKey" 
username:@"John Smith" 
avatarURL:nil 
delegate:self 
secureURl:true
];
}

...
@end
```
##### Note:
Don't forget to add usage description for camera, photo library and microphone to your info.plist
![alt tag](https://res.cloudinary.com/qiscus/raw/upload/v1485738688/1485738687/Screen%20Shot%202017-01-30%20at%208.10.46%20AM.png)

# Room Types 
### Group Room
A Group Room is a chat for several users. A user can join the chat only through an invitation.
### 1 on 1 
A 1 on 1 Room is a chat for two users. The chat initiator only need to add the target's messaging username

# 1-to-1 Chat 
### Creating and starting 1-to-1 chat by target
Start chat with target is very easy, all you need is just call 
###### Swift 3.0 :
`Qiscus.chat(withUsers: ["TARGET_EMAIL"], target: self)` 
###### Objective C:
`[Qiscus chatWithUsers:<ARRAY_OF_TARGET_EMAIL> target:self readOnly:<false|true> title:<CHAT_TITLE> subtitle:<CHAT_SUBTITLE> distinctId:NULL optionalData:NULL withMessage:NULL]`
in your code

For example in your ViewController : 
##### Swift 3.0:
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
        Qiscus.chat(withUsers: ["fikri@qiscus.com"], target: self)
    }

.....
}
```

##### Objective C:
```
#import "MainVC.h"

@import Qiscus;

@interface MainVC ()
...
...
@end

@implementation MainVC
...
- (void)goToChat{
[Qiscus chatWithUsers:[NSArray arrayWithObject:@"081234567890@qiscuswa.com"] 
target:self 
readOnly:false 
title:@"Sample Chat" 
subtitle:@"chat with user" 
distinctId:NULL 
withMessage:NULL 
optionalData:NULL];
}

...
@end

```



# Group Room 
### Creating a Group Room 
Qiscus also support group chat. To create new group chat, all you need is just call 
###### Swift 3.0:
`Qiscus.createChat(withUsers users:["TARGET_EMAIL_1, TARGET_EMAIL_2"], target:self)` 
###### Objective C:
`[Qiscus createChatViewWithUsers:<ARRAY_OF_TARGET_EMAIL> target:self readOnly:<false|true> title:<CHAT_TITLE> subtitle:<CHAT_SUBTITLE> distinctId:NULL optionalData:NULL withMessage:NULL]`

For example in your ViewController : 

##### Swift 3.0
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

##### Objective C:
```
#import "MainVC.h"

@import Qiscus;

@interface MainVC ()
...
...
@end

@implementation MainVC
...
- (void)goToChat{
[Qiscus createChatViewWithUsers:emails 
target:self 
readOnly:false 
title:@"New Group Chat" 
subtitle:@"always new chat" 
distinctId:NULL 
optionalData:NULL 
withMessage:NULL];
}

...
@end

```
### Getting a Group Room instance with room id 
When you already know your chat room id, you can easily go to that room. Just call
###### Swift 3.0:
`Qiscus.chat(withRoomId roomId:[ROOM_ID], target:self, optionalDataCompletion: {_ in})` 
###### Objective C:
`[Qiscus chatWithRoomId:<CHAT_ROOM_ID> target:self readOnly:<true|false> title:<CHAT_TITLE> subtitle:<CHAT_SUBTITLE> distinctId:NULL withMessage:NULL optionalData:NULL optionalDataCompletion:^(NSString * _) {}]`


For example in your ViewController : 
##### Swift 3.0
```
import UIKit
import Qiscus

class ViewController: UIViewController {

.....

func goToChat(){
print("go to chat")
Qiscus.chat(withRoomId: roomId, target: self, 
optionalDataCompletion: {_ in 

})
}

.....
}
```

##### Objective C:
```
#import "MainVC.h"

@import Qiscus;

@interface MainVC ()
...
...
@end

@implementation MainVC
...
- (void)goToChat{
[Qiscus chatWithRoomId:135 
target:self 
readOnly:false 
title:@"" 
subtitle:@"chat with room id" 
distinctId:NULL 
withMessage:NULL 
optionalData:NULL 
optionalDataCompletion:^(NSString * _) {

}];
}
...
@end

```
    
# UI Customization
### Theme Customization 
you can explore customisation of chat interface by calling method style

For Example : 
##### Swift 3.0:
```
Qiscus.style.color.leftBaloonColor = UIColor.blueColor()
Qiscus.style.color.rightBaloonColor = UIColor.greenColor()
```
##### Objective C:
```
Qiscus.style.color.leftBaloonColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
Qiscus.style.color.welcomeIconColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
Qiscus.style.color.leftBaloonTextColor = [UIColor whiteColor];
Qiscus.style.color.rightBaloonColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
Qiscus.style.color.rightBaloonTextColor = [UIColor whiteColor];
Qiscus.style.color.rightBaloonLinkColor = [UIColor whiteColor];
[Qiscus setGradientChatNavigation:[UIColor blackColor] 
bottomColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1] 
tintColor:[UIColor whiteColor]];
```



Check sample apps -> [Swift](https://github.com/qiscus/qiscus-sdk-ios-sample) or [Objective C](https://github.com/qiscus/qiscus-sdk-ios-sample-obj-c)



## License

Qiscus-SDK-IOS is released under the MIT license. See LICENSE for details.
