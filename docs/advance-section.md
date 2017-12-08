# Advance Section

## Server Authentication

Another option is to authenticate using Json Web Token [(JWT)](https://jwt.io/). Json Web Token contains your app account details which typically consists of a single string which contains information of two parts, Jose header and JWT claims set. 

The steps to authenticate with JWT goes like this:

1. The Client App request a nonce from Qiscus SDK server
2. Qiscus SDK Server will send Nonce to client app
3. Client App send user credentials and Nonce that is obtained from Qiscus SDK Server to Client app backend
4. The Client App backend will send the token to client app
5. The Client App send that token to Qiscus Chat SDK
6. Qiscus Chat SDK send Qiscus Account to Client app

<p align="center"><br/><img src="https://raw.githubusercontent.com/qiscus/qiscus-sdk-android/develop/screenshot/jwt.png" width="80%" /><br/></p>

You need to request Nonce from Qiscus Chat SDK Server. Nonce (Number Used Once) is a unique, randomly generated string used to identify a single request. Please be noted that a Nonce will expire in 10 minutes. So you need to implement your code to request JWT from your backend right after you got the returned Nonce. Here is how to authenticate to Qiscus Chat SDK using JWT :

Client side will call Qiscus.getNonce() to request Nonce from Qiscus SDK Server.

```swift
import Qiscus

Qiscus.getNonce(withAppId: "APP_ID", onSuccess: { (nonce) in
    print("get nonce here : \(nonce)")
}, onFailed: { (error) in
    print("error : \(error)")
})
```
The code above is a sample of method you can implement in your app. By calling Qiscus.getNonce(), you will request Nonce from Qiscus SDK server and a Nonce will be returned. If it is success, you can request JWT from your backend by sending Nonce you got from Qiscus SDK Server. 
When you got the JWT Token, you can pass that JWT to Qiscus.setup(withUserIdentityToken: "IDENTITY_TOKEN") method to allow Qiscus to authenticate your user and return user account, as shown in the code below :

```swift
import Qiscus

Qiscus.setup(withUserIdentityToken: "IDENTITY_TOKEN")
```

If you are wondering the full implementation of JWT authentication, here is the full code sample:

```swift
import Qiscus

Qiscus.getNonce(withAppId: YOUR_APP_ID, onSuccess: { (nonce) in
    print("get nonce here : \(nonce)")    
    
    // this is your own service that call your own server
    // you pass your user credential together with nonce from Qiscus server that just being received
    MyHTTPService.callAuth(params: {user: userDetails, nonce: nonce}, onSuccess: { (data) in
    
        // success authenticate to your own server
        // now time to verify the identity token from your server to Qiscus Server
        Qiscus.setup( 
              withUserIdentityToken: data.identity_token,
              delegate: self
        )
    }, onError: { (error) in 
        // your auth error callback
    })
}, onError: { (error) in
    print("error : \(error)")
})
```
##setting jose header and jwt claim set in your backend

When your backend returns a JWT after receiving Nonce from your client app, the JWT will be caught by client app and will be forwarded to Qiscus Chat SDK Server. In this phase, Qiscus Chat SDK Server will verify the JWT before returning Qiscus Account for your user. To allow Qiscus Chat SDK Server successfully recognize the JWT, you need to setup Jose Header and JWT claim set in your backend as follow :

**Jose Header :**
```
{
  "alg": "HS256",  // must be HMAC algorithm
  "typ": "JWT", // must be JWT
  "ver": "v2" // must be v2
}
```
**JWT Claim Set :**
```
{
  "iss": "QISCUS SDK APP ID", // your qiscus app id, can obtained from dashboard
  "iat": 1502985644, // current timestamp in unix
  "exp": 1502985704, // An arbitrary time in the future when this token should expire. In epoch/unix time. We encourage you to limit 2 minutes
  "nbf": 1502985644, // current timestamp in unix
  "nce": "nonce", // nonce string as mentioned above
  "prn": "YOUR APP USER ID", // your user identity such as email or id, should be unique and stable
  "name": "displayname", // optional, string for user display name
  "avatar_url": "" // optional, string url of user avatar
}
```


## UI Costomization

Qiscus Chat SDK enable you to customize Chat UI as you like. You can modify colors, change bubble chat design, modify Chat Header, and many more. All customization method are inside `Qiscus.style()`. By calling it, you can simply look at the autocomplete suggestion in your IDE to see lots of methods to modify your Chat Interface.

```swift
  // example of modifying colors
  let qiscusColor = Qiscus.style.color
  qiscusColor.welcomeIconColor = colorConfig.chatWelcomeIconColor
  qiscusColor.leftBaloonColor = colorConfig.chatLeftBaloonColor
  qiscusColor.leftBaloonTextColor = colorConfig.chatLeftTextColor
  qiscusColor.leftBaloonLinkColor = colorConfig.chatLeftBaloonLinkColor
  qiscusColor.rightBaloonColor = colorConfig.chatRightBaloonColor
  qiscusColor.rightBaloonTextColor = colorConfig.chatRightTextColor    

  // example of modiying font
  let fontSize: CGFloat = CGFloat(17).flexibleIphoneFont()
  Qiscus.style.chatFont = UIFont.systemFont(ofSize: fontSize)

```

## Event Handler

An Event Handler is a callback routine that operates asynchronously and handles inputs received into a program. Event Handlers are important in Qiscus because it allows a client to react to any events happening in Qiscus Chat SDK. For example, if a client wants to know any important events from server, such as success login event, client's app can be notified by calling a specific Event Handler. Client, then, can do things with data returned by the event.

There are 2 type of Event Handler provided by Qiscus Chat SDK: **QiscusConfigDelegate** and **QiscusRoomDelegate**. 
**QiscusConfigDelegate** provides event handler that are related to Qiscus Chat SDK initialization.such as events for push notification and event synchronize, while **QiscusRoomDelegate** provides event handlers that are related to room and messaging.

To use event handler inside your app, you will need to extend QiscusConfigDelegate or QiscusRoomDelegate, so that you can see all event handlers that are provided by the class, then you can do whatever you need to do inside the event handlers.
 
There are several event handlers that are provided inside **QiscusConfigDelegate** as listed below :

```swift
func qiscusFailToConnect(_ withMessage: String) {
   // do anything if failed to connect to Qiscus Chat SDK 
}

func qiscusConnected() {
   // do anything after successfully connected to Qiscus Chat SDK
}
    
func qiscus(gotSilentNotification comment: QComment) {
   //do anything if got new message in silent mode
}

func qiscus(didConnect succes: Bool, error: String?) {
   //do anything after successfully connected to Qiscus Push Notification
}

func qiscus(didRegisterPushNotification success: Bool, deviceToken: String, error: String?) {
   // got status of registering qiscus sdk
   //do anything after 
}

func qiscus(didUnregisterPushNotification success: Bool, error: String?) {
   // got status of un-registering qiscus sdk
}

func qiscus(didTapLocalNotification comment: QComment, userInfo: [AnyHashable : Any]?) {
   // do anything after push notification alert is clicked
}
    
func qiscusStartSyncing() {    
   // do anything when Qiscus Chat SDK start to synchronize messages
}

func qiscus(finishSync success: Bool, error: String?) {
   // do anything after synchronizing finished
}
```

There are some event handlers that are provided by **QiscusRoomDelegate** as listed below :
```swift
func gotNewComment(_ comments: QComment) {
   // do anything after receiving new comment
}

func didFinishLoadRoom(onRoom room: QRoom) {
   // do anything after chat room is successfully loaded
}

func didFailLoadRoom(withError error: String) {
   // do anything after chat room is failed to load
}

func didFinishUpdateRoom(onRoom room: QRoom) {
   // do anything after chat room is successfully updated
}

func didFailUpdateRoom(withError error: String) {
   // do anything after chat room is failed to update
}
```

