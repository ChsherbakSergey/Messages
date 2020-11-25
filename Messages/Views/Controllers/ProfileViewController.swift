//
//  ProfileViewController.swift
//  Messages
//
//  Created by Sergey on 11/15/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

final class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appendData()
        setTableViewDelegateAndDataSource()
        
    }
    
    func appendData() {
        data.append(ProfileViewModel(type: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", handler: nil))
        data.append(ProfileViewModel(type: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")", handler: nil))
        data.append(ProfileViewModel(type: .logout, title: "Log Out", handler: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                //Log Out Facebook
                
                FBSDKLoginKit.LoginManager().logOut()
                
                //Log Out Google
                
                GIDSignIn.sharedInstance()?.signOut()
                
                //Firebase Log Out
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    //If Log Out show Login Screen
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true)
                } catch {
                    print("Failed to log out: \(error)")
                }
                
            }))
            
            strongSelf.present(actionSheet, animated: true)
            
        }))
    }
    
    func setTableViewDelegateAndDataSource() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableHeaderView = createTableViewHeader()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
    }
    
    func createTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/" + fileName
        
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.width, height: 200)
        headerView.backgroundColor = .systemBackground
        let imageView = UIImageView()
        imageView.frame = CGRect(x: (headerView.width - 150) / 2, y: 25, width: 150, height: 150)
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadUrl(for: path, completion: { result in
            switch result {
            case .failure(let error):
                print("Storage manager error: \(error)")
            case .success(let downloadUrl):
                imageView.sd_setImage(with: downloadUrl, completed: nil)
            }
        })
        
        return headerView
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?()
        
        
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        textLabel?.text = viewModel.title
        switch viewModel.type {
        case .info:
            textLabel?.textAlignment = .left
            textLabel?.font = .systemFont(ofSize: 23, weight: .semibold)
            selectionStyle = .none
        case .logout:
            
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
            textLabel?.font = .systemFont(ofSize: 23, weight: .semibold)
        }
    }
}
