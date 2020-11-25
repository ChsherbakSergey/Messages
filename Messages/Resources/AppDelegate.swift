//
//  AppDelegate.swift
//  Messages
//
//  Created by Sergey on 11/15/20.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        ApplicationDelegate.shared.application( app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        return GIDSignIn.sharedInstance().handle(url)
    }

    // MARK: UISceneSession Lifecycle

//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }


}
 
// MARK: Goodle GIDSignInDelegate

extension AppDelegate: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with Google: \(error)")
            }
            return
        }
        
        guard let email = user.profile.email, let firstName = user.profile.givenName, let lastName = user.profile.familyName else {
            return
        }
        
        UserDefaults.standard.setValue(email, forKey: "email")
        UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
        
        guard let user = user else {
            return
        }
        
        print("Did sign in with Google: \(user)")
        
        DatabaseManager.shared.userExists(with: email, completion: { exists in
            if !exists {
                //insert to database
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: email)
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                                guard let data = data else {
                                    return
                                }
                                
                                //Upload the image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.updateProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    case .success(let downloadUrl):
                                        print("\(downloadUrl)")
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                    }
                                })
                            }).resume()
                        }
                    }
                })
            }
        })
        
        guard let authentication = user.authentication else {
            print("Missing auth object off of Google user")
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                            accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
            guard authResult != nil, error == nil else {
                print("Failed to log in with Google credentials")
                return
            }
            
            print("Successfully logged in with Google credentials")
            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
        })
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected.")
    }
    
}
