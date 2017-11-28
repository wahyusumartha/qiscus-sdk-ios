#Advance Section

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

