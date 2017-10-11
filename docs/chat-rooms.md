# Chat Rooms
## Creating 1-to-1 chat

Start chat with target is very easy, all you need is just call

Swift 3.0:
```swift
let email = targetField.text!
let view = Qiscus.chatView(withUsers: [email])
self.navigationController?.pushViewController(view, animated: true)
```
in your code

For example in your ViewController:

Swift 3.0:
```swift
import UIKit
import Qiscus

class ViewController: UIViewController {
  .....
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 30))
    button.backgroundColor = UIColor.green
    button.setTitle("Start Chat", for: .normal)
    button.addTarget(self, action: #selector(ViewController.startChat), for: .touchUpInside)
    self.view.addSubview(button)
  }
  func startChat() {
    let email = targetField.text!
    let view = Qiscus.chatView(withUsers: [email])
    self.navigationController?.pushViewController(view, animated: true)
  }
  .....
}
```

## Creating Group Room
Qiscus also support group chat. To create new group chat, all you need is just
call

Swift 3.0:
`Qiscus.createChatView(withUsers: ["TARGET_EMAIL_1, TARGET_EMAIL_2"], title: "CHAT_GROUP_TITLE")`
For example in your ViewController:

Swift 3.0
```swift
import UIKit
import Qiscus

class ViewController: UIViewController {
  .....
  func goToChat() {
    let chatTargets = ["081111111111@qiscuswa.com, 081234567890@qiscuswa.com"]
    let view = Qiscus.createChatView(withUsers: chatTargets, title: "New Group Chat")
    self.navigationController?.pushViewController(view, animated: true)
  }
  .....
}
```
for accessing room that create by this call, you need to call it with its
roomId. This method is always creating new chat room.

## Get a room by id
When you already know your chat room id, you can easily go to that room. Just
call

Swift 3.0:
`Qiscus.chatView(withRoomId: roomId)`

For example in your ViewController:

Swift 3.0
```swift
import UIKit
import Qiscus

class ViewController: UIViewController {
  .....
  func goToChat() {
    let roomId = Int(targetField.text!)
    let view = Qiscus.chatView(withRoomId: roomId)
    self.navigationController?.pushViewController(view, animated: true)
  }
  .....
}
```

## Create or join room by defined id
You probably want to set defined id for the room you are creating so that the
id can be reference for users to get into.

Usual usage for this is when user create common room or channel which expecting
other users can join to the same channel by knowing the channel name or id, you
can use the channel name or id as qiscus room defined id.

Additional note: If room with predefined unique id is not exist then it will
create a new one with requester as the only one participant. Otherwise,
if room with predefined unique id is already exist, it will return that room and
add requester as a participant.

When first call (room is not exist), if requester did not send avatar_url and/or
room name it will use default value. But, after the second call (room is exist)
and user (requester) send avatar_url and/or room name, it will be updated to
that value. Object changed will be true in first call and when avatar_url or
room name is updated.

Swift 3.0:
`Qiscus.chatView(withRoomUniqueId: uniqueId)`
For example in your ViewController:

Swift 3.0
```swift
import UIKit
import Qiscus

class ViewController: UIViewController {
  .....
  func goToChat() {
    let roomId = Int(targetField.text!)
    let view = Qiscus.chatView(withRoomUniqueId: uniqueId)
    self.navigationController?.pushViewController(view, animated: true)
  }
  .....
}
```

## Inviting users to an existing Room
Currently we recommend to invite user into existing room through our
*REST API* for simplicity and security reason

## Leaving a Group Room
Currently we recommend to kick user out of specific room through our
*REST API* for simplicity and security reason

## Get Room List
We can get room list for the user by executing this function, however no `view`
being returned. The function will only return data of the rooms
```swift
QChatService.roomList(withLimit: 100, page: page, onSuccess: { (rooms, totalRoom, currentPage, limit) in
  print("room list: \(rooms)")
}) { (error) in
  print("\(error)")
}
```
