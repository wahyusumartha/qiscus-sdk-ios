//
//  AppDelegate.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit
import Qiscus

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().tintColor = UIColor.black
        
        if !Qiscus.isLoggedIn{
            goToLoginView()
        }else{
            goToChatNavigationView()
        }
        
        Qiscus.registerNotification()
        
        //Chat view styling
        Qiscus.style.color.leftBaloonColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        Qiscus.style.color.welcomeIconColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        Qiscus.style.color.leftBaloonTextColor = UIColor.white
        Qiscus.style.color.rightBaloonColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        Qiscus.style.color.rightBaloonTextColor = UIColor.white
        Qiscus.style.color.rightBaloonLinkColor = UIColor.white
        Qiscus.setGradientChatNavigation(UIColor.black, bottomColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), tintColor: UIColor.white)
        
        window?.makeKeyAndVisible()
        
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        Qiscus.didRegisterUserNotification()
    }
    func goToChatNavigationView(){
        let chatView = goToChatVC()
        let navigationController = UINavigationController(rootViewController: chatView)
        window?.rootViewController = navigationController
    }
    
    func goToLoginView(){
        let mainView = MainView()
        let navigationController = UINavigationController(rootViewController: mainView)
        window?.rootViewController = navigationController
    }
}

