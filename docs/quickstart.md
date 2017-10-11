
# Quick Start

![SDK iOS](https://res.cloudinary.com/qiscus/image/upload/zKB8jtyLZJ/ssios1.png "SDK iOS)

## Create a new app
Register on [www.qiscus.com/dashboard](https://www.qiscus.com/dashboard)
using your email and password and then create new appliation.

You should create one application per service, regardless of the platform. For
example, an app released in both Android and iOS would require only one
application to be created in the Dashboard.

All users within the same Qiscus application are able to communicate with each
other, across all platforms. This means users using iOS, Android, web clients,
etc. can all chat with one another. However, users in different Qiscus
applications cannot talk to each other.

Done! Now you can use the APP_ID into your apps and get chat functionality by
implementing Qiscus into your app.

## Integrating SDK with an existing app
[CocoaPods](http://cocoapods.org/) is a dependency manager for Cocoa projects.
You can install it with the following command:
```bash
$ gem install cocoapods
```
> CocoaPods 1.1.0+ is required

Podfile:
```ruby
target 'Sample' do
  .....
  use_frameworks!
  .....
  pod 'Qiscus'
  .....
end
```
Install Qiscus through CocoaPods
```bash
$ pod install
```
