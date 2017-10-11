# Event Handler

### QiscusConfigDelegate
```swift
class MainView: UIViewController, QiscusConfigDelegate {
  // MARK: - QiscusConfigDelegate
  func qiscusFailToConnect(_ withMessage:String) {
    print(withMessage)
    ...
  }
  func qiscusConnected() {
    appDelegate.goToChatNavigationView()
    ...
  }
}
```
### QiscusRoomDelegate
```swift
class SampleAppRealtime: QiscusRoomDelegate {
  // MARK: - Member of QiscusRoomDelegate
  internal func gotNewComment(_ comments: QiscusComment) {
    print("getting new messages")
  }
  internal func didFinishLoadRoom(onRoom room: QiscusROOM) {
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
