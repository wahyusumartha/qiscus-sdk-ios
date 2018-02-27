# List of Function API v2 iOS

## Setup

### Init *AppId *

client side will call 

```
import Qiscus

Qiscus.setup( withAppId: "app_id",
                          userEmail: "youremail.com",
                          userKey: "yourpassword",
                          username: "yourname",
                          avatarURL: "",
                          delegate: nil
            )
```

Sample usage in client side will be something like this : 

```
import Qiscus

Qiscus.setup( withAppId: "sampleapp-65ghcsaysse",
                          userEmail: "abcde1234@qiscus.com",
                          userKey: "abcde1234",
                          username: "steve Kusuma",
                          avatarURL: "",
                          delegate: self)
```

Listen callback from delegate 

```
extension LoginVC : QiscusConfigDelegate{
    func qiscusConnected() {
        print("connect") // your connected callback
    }
    
    func qiscusFailToConnect(_ withMessage: String) {
        print(withMessage) //your error auth callback
    }
}
```

### init *AppId *using custom server

```
import Qiscus

Qiscus.setBaseURL("Your Constom URL")
Qiscus.setRealtimeServer(server : "Your URL", port : "Your port",enableSSL : true/false)
```



## User

### Authentication with UserID & UserKey

```
import Qiscus

Qiscus.setup( withAppId: "app_id",
                          userEmail: "youremail.com",
                          userKey: "yourpassword",
                          username: "yourname",
                          avatarURL: "",
                          delegate: nil
            )
```

### Authentication with JWT

client side will call getNonce


```
import Qiscus

Qiscus.getNonce(withAppId: "APP_ID", onSuccess: { (nonce) in
    print("get nonce here : \(nonce)")
}, onFailed: { (error) in
    print("error : \(error)")
})
```


client side will verify the Identity Token and setup object


```
import Qiscus

Qiscus.setup(withUserIdentityToken: "IDENTITY_TOKEN")
```


Sample usage in client side will be something like this :


```
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



### Updating a user profile and profile image

```
Qiscus.updateProfile(username: username, avatarURL: avatar, onSuccess: { 
            print("success profile")
        }) { (error) in
            print("error update profile: \(error)")
        }
```

### check is user logged in

```
Qiscus.isLoggedIn // BOOL can be true or false
```

### logout user

```
Qiscus.clear()
```

## Message

### send message (with various type of payloads)

* new text comment:

```
 let comment = room.newComment(text: value) //create new text message on room
 room.post(comment: comment) //post message on room
```



* new file comment / upload media

```
let comment = room.newFileComment(type: .image, filename: fileName, data: data)
// data contains fileData with type Data
// type: can be .image, .video, .audio, .file

room.upload(comment: comment, onSuccess: { (roomResult, commentResult) in
            roomResult.post(comment: commentResult)
        }, onError: { (roomResult, commentResult, error) in
            
        }) { (progress) in
            // progress value will be from 0.00 to 1.00
        }
        
```

Example : 

```
let image = UIImage(named: "abc") // assuming you have file abc locally
let data = UIImagePNGRepresentation(image!)
let comment = room.newFileComment(type: .image, filename: "abc.png", data: data)

room.upload(comment: comment, onSuccess: { (roomResult, commentResult) in
    print("COMMENT", commentResult)
    roomResult.post(comment: commentResult)
}, onError: { (roomResult, commentResult, error) in
    print("ERROR", error)
}) { (progress) in
    print("PROGRESS", progress)
    // progress value will be from 0.00 to 1.00
}
```

* new custom payload comment:

```
 let comment = room.newCustomComment(text: value, type: .custom, payload:payload) //create new custom message on room
 room.post(comment: comment) //post message on room
```

Example : 

```
let comment = room.newCustomComment(type: "custom", payload: "{ \"key\": \"value\"}", text: "THIS IS CUSTOM MESSAGE")
room.post(comment: comment)
```

### load messages (with limit and offset)

```
// offset can be taken from comment.messageId
// this method will give the messages after the offset given
room.loadComments(limit: 20, offset: "12345", onSuccess: { (comments) in
            // comments contain array of QComment objects
        }) { (error) in
            print(error)
        }
```

### load more (with limit and offset)

```
// offset can be taken from comment.messageId
// this method will give the messages before the offset given
room.loadMore(limit: 20, offset: "12345", onSuccess: { (comments, hasMoreMessages) in
        // comments contain array of QComment objects
        // hasMoreMessages signifies that there is still another message before the first message, this is Boolean (true/false) 
}) { (error) in
   print(error)
}
```

### download media (the path and % process)

```

room.downloadMedia(onComment: comment, onSuccess: { (commentResult) in
            <#code#>
            print(commentResult.file.localPath)
        }, onError: { (error) in
            <#code#>
        }) { (progress) in
            <#code#>
        }
```

### Keyword search

```
        QChatService.searchComment(withQuery: (self.searchViewController?.searchBar.text)!, onSuccess: { (comments) in
            self.filteredComments = comments
            self.tableView.reloadData()
            print("success search comment with result:\n\(comments)")
        }, onFailed: { (error) in
            print("fail to get search result")
        })
```




## Room

### create room (group)

```
Qiscus.newRoom(withUsers: ["user_id1", "user_id2"], roomName: "My RoomName", onSuccess: { (room) in
            // room data in QRoom object
        }) { (error) in
            // resulting error in String
        } 
```



### get chat room by id

```
Qiscus.room(withId: roomId, onSuccess: { (room) in
            // room data in QRoom object
            // for accessing comments inside room
            let comments = room.listComment // ressulting array of QComment
        }) { (error) in
            // resulting error in String
        }
```



### get chat room by channel

```
Qiscus.room(withChannel: channelName, onSuccess: { (room) in
            // room data in QRoom object
            // for accessing comments inside room
            let comments = room.listComment // ressulting array of QComment
        }) { (error) in
            // resulting error in String
        }
```



### get chat room opponent by user_id

```
Qiscus.room(withUserId: userId, onSuccess: { (room) in
            // room data in QRoom object
            // for accessing comments inside room
            let comments = room.listComment // ressulting array of QComment
        }) { (error) in
            // resulting error in String
        }
```

### get rooms info

rooms info sometimes not contain message inside room

* get room info with id

```
Qiscus.roomInfo(withId: "13456", onSuccess: { (room) in
            // room data in QRoom object
        }) { (error) in
            // resulting error in string
        }
```

* get multiple room info

```
Qiscus.roomsInfo(withIds: ["12345", "13456"], onSuccess: { (rooms) in
            // rooms data in array of QRoom object
        }) { (error) in
            // resulting error in string
        }
```

* get channel info

```
Qiscus.channelInfo(withName: "myChannel", onSuccess: { (room) in
            // room data in QRoom object
        }) { (error) in
            // resulting error in string
        }
```

* get multiple channel info

```
Qiscus.channelsInfo(withNames: ["myChannel1","myChannel2"], onSuccess: { (rooms) in
            // rooms data in array of QRoom object
        }) { (error) in
            // resulting error in string
        }
```



### get rooms list

*request always to server


```
Qiscus.roomList(withLimit: 100, page: 1, onSuccess: { (rooms, totalRoom, currentPage, limit) in
            // rooms contains array of room
            // totalRoom = total room in server
            // currentPage = current page requested
            // limit = limit requested
        }) { (error) in
            // resulting error in string
        }
```

* get room list in localDB:

```
let rooms = QRoom.all()
```

### update room (including update options)

```
var room:QRoom?
room.update(roomName: roomName, roomAvatarURL: avatar, onSuccess: { (qRoom) in
                //success update
            }, onError: { (error) in
                //error
            })
```

### Getting a list of participants in a room

```
 Qiscus.room(withId: roomId!, onSuccess: { (room) in
            // getroom list participant
          let allparticipant = room.participants
        }) { (error) in
            print("error")
        }
```

### Leaving the chat room (probably new API)

You can read [this](https://www.qiscus.com/documentation/android/latest/getting-started#group-chat-room) documentation, and goto **Participant Management **section, or you can check [this](https://www.qiscus.com/documentation/rest/latest/list-api#remove-room-participants) **Server API** documentation. Because currently we only provide in **Server API.**


## Statuses

### publish start typing

```
room.publishStartTyping()
```



### publish stop typing

```
room.publishStopTyping()
```



### update message status (read)

```
QRoom.publishStatus(roomId: roomId, commentId: commentId, status: .read)
```

### Getting participants' online statuses

### 

### Viewing who has Received and read a message

To get information who has received and read a message, We can get all data member in QComment. In QComment class have a variable readUser and deliveredUser. 

```
var comment : QComment?

comment?.statusInfo?.readUser //list data users have been read comment
comment?.statusInfo?.readUser.count //count of data users have been read comment
comment?.statusInfo?.deliveredUser //list data users have been delivered comment
comment?.statusInfo?.deliveredUser.count //count of data users have been delivered comment

```

We can get a update users status delivered and received message with **QParticipantDelegate.**

```

extension YourViewController: QParticipantDelegate{
    //in function show your tableview
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var participantGroup = data?.statusInfo?.readUser
        if indexPath.section > 0 {
            participantGroup = data?.statusInfo?.deliveredUser
        }
        let participant = participantGroup?[indexPath.row]
        participant?.delegate = self // init QParticipantdelegate
        //init your cell
        return cell
    }
    func participant(didChange participant: QParticipant) {
       //you can update here
    }
}
```



## Event Handler

### on receive message

* listen to notification

```
NotificationCenter.default.addObserver(self, selector: #selector(YOUR_CLASS.newCommentNotif(_:)), name: QiscusNotification.GOT_NEW_COMMENT, object: nil)
```

* get data on your selector

```
func newCommentNotif(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! QComment
            
            // if you want to get the room where the comment is
            let room = comment.room
            // *note: it can be nil
        }
    }
```



### on user typing (with information on which room)

* subscribe notification channel

```
room.subscribeRealtimeStatus()
```



* listen to notification

```
NotificationCenter.default.addObserver(self, selector: #selector(YOUR_CLASS.userTyping(_:)), name: QiscusNotification.USER_TYPING, object: nil)
```

* get data on your selector

```
func userTyping(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let user = userInfo["user"] as! QUser
            let typing = userInfo["typing"] as! Bool
            let room = userInfo["room"] as! QRoom
            
            // typing can be true or false
        }
}
```

### on message status change

* message status is object type QCommentStatus. the value can be .sending , .pending , .sent , .delivered, .read
* listen to notification:

```
NotificationCenter.default.addObserver(self, selector: #selector(YOUR_CLASS.messageStatusChange(_:)), name: QiscusNotification.MESSAGE_STATUS, object: nil)
```

* get data on your selector 

```
func messageStatusChange(_ notification: Notification){
        if let userData = notification.userInfo {
            let comment = userData["comment"] as? QComment
            let newStatus = userData["status"] as? QCommentStatus
        }
    }
```

**on message status change (update status in cell) - by using Delegate**

* message status is object type QCommentStatus. the value can be .sending , .pending , .sent , .delivered, .read
* declaration object QComment in Cell Class

```
    var comment:QComment?{
        didSet{
            if oldValue != nil {
                oldValue!.delegate = nil
            }
            if comment != nil {
                self.comment?.delegate = self
                textChat.text = commentRaw?.text
                textChat.sizeToFit()
                textChat.layoutIfNeeded()
                
               //update your status in here 
               // the value can be .sending , .pending , .sent , .delivered, .read
        }
    }
```

* extend QCommentDelegate & Implement callback update

```
class (YourClassCell) : UITableViewCell , QCommentDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
         }

    func comment(didChangeStatus comment: QComment, status: QCommentStatus) {
        if self.commentRaw?.uniqueId == comment.uniqueId {
             // update your status in here
             //  the value can be .sending , .pending , .sent , .delivered, .read
        }
    }
}
```




## Notification

### Push Notifications

* REGISTER DEVICE TOKEN

```
Qiscus.didRegisterUserNotification(withToken: token)    
```

* Will Receive Push Notification Payload 



