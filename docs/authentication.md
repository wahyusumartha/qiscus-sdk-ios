# Authentication

## Init with App ID
To initiate Qiscus SDK, you need to import Qiscus and then add this in your
code everywhere you want

Swift 3.0:
```swift
import Qiscus

Qiscus.setup( withAppId: YOUR_APP_ID,
              userEmail: CURRENT_USER_EMAIL,
              userKey: CURRENT_USER_PASSWORD,
              username: CURRENT_USER_USERNAME,
              avatarURL: CURRENT_USER_AVATAR_URL,
              delegate: self
)
```

Using the SDK in Objective-C
```objc
import Qiscus

[Qiscus setupWithAppId:<YOUR_APP_ID>
        userEmail:<USER_EMAIL>
        userKey:<USER_KEY>
        username:<USER_NAME>
        avatarURL:<USER_AVATAR_URL>
        delegate:self
        secureURL:<true|false>];
```
Example on AppDelegate.swift
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
  let viewController = ViewController()
  let navigationController = UINavigationController(rootViewController: viewController)

  Qiscus.setup( withAppId: "DragonGo",
                userEmail: "abcde@qiscus.com",
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

## Updating a User Profile and Avatar
Updatinng user profile and details is simply by re-init the user using new
details:
```swift
Qiscus.setup( withAppId: "DragonGo",
              userEmail: "abcde@qiscus.com",
              userKey: "abcd1234",
              username: "Steve Kusuma New Name",
              avatarURL: "https://myimage.com/myNewImage.png",
              delegate: nil
)
```
