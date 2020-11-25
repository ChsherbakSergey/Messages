//
//  LoginViewController.swift
//  Messages
//
//  Created by Sergey on 11/15/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    private let spinner: JGProgressHUD = {
        let spinner = JGProgressHUD()
        spinner.style = .dark
        return spinner
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ImessageIcon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Adress..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()

    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        return button
    }()

    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        //Adding button to be able to go to the Register Screen
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        setUpUI()
        setNotificationObserverToDismissLoginScreen()
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
        facebookLoginButton.frame = CGRect(x: 30, y: loginButton.bottom + 10, width: scrollView.width - 60, height: 28)
        googleLoginButton.frame = CGRect(x: 25, y: facebookLoginButton.bottom + 10, width: scrollView.width - 50, height: 28)
    }
    
    func setUpUI() {
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
        
        //loginButton target
        loginButton.addTarget(self, action: #selector(loginButtonDidTap), for: .touchUpInside)
        
        //emailField and passwordFieldDelegates
        emailField.delegate = self
        passwordField.delegate = self
        
        //Facebook Login Button Delegate
        facebookLoginButton.delegate = self
        
        //Set the presenting view controller of the GIDSignIn object, and (optionally) to sign in silently when possible.
        GIDSignIn.sharedInstance()?.presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
    }
    
    func setNotificationObserverToDismissLoginScreen() {
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc private func loginButtonDidTap() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case.failure(let error):
                    print("Got error when trying to get data for path: \(safeEmail). Error: \(error)")
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    print("Got data for path: \(safeEmail)")
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                }
            })
            
            UserDefaults.standard.setValue(email, forKey: "email")
            
            
            print("Logged in user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Please enter all the information to log in.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
        
    }

}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonDidTap()
        }
        
        return true
    }
    
}

extension LoginViewController: LoginButtonDelegate {
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields" : "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start(completionHandler: { connection, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
//            print("\(result)")
            guard let firstName = result["first_name"] as? String, let lastName = result["last_name"] as? String, let email = result["email"] as? String, let picture = result["picture"] as? [String: Any], let data = picture["data"] as? [String: Any], let pictureUrl = data["url"] as? String else {
                print("Failed to get name and email from Facebook result")
                return
            }
            
            UserDefaults.standard.setValue(email, forKey: "email")
            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    
                }
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: email)
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        guard let url = URL(string: pictureUrl) else {
                            return
                        }
                        
                        print("Downloading data from facebook image")
                        
                        URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                            guard let data = data else {
                                print("Failed to get data for picture url from facebook")
                                return
                            }
                            
                            print("Got data from facebook, uploading it")
                            
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
                })
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed: \(error)")
                    }
                    return
                }
                
                print("Successfully logged in the user with Facebook")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            })
        })
        
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }

}
