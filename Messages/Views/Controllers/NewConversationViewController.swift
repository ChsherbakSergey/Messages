//
//  NewConversationViewController.swift
//  Messages
//
//  Created by Sergey on 11/15/20.
//

import UIKit
import JGProgressHUD

final class NewConversationViewController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
    private var users = [[String: String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    private let spinner: JGProgressHUD = {
        let spinner = JGProgressHUD()
        spinner.style = .dark
        return spinner
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for a new user..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(NewConversationTableViewCell.self, forCellReuseIdentifier: NewConversationTableViewCell.identifier)
        tableView.isHidden = true
        return tableView
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setDelegates()
        setInitialUI()
        //Set Cancel Right BarButton Item
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didTapDismissScreen))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width / 4, y: (view.height - 200) / 2, width: view.width / 2, height: 200)
    }
    
    func setDelegates() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setInitialUI() {
        //Adding view
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        view.addSubview(spinner)
        //Creating search bar in the Navigation Controller
        navigationController?.navigationBar.topItem?.titleView = searchBar
        //If user click on start new conversation it means they want to start a new dialog with someone whom they going to seek. For this purpose I have to implement firstResponder for the searchBar
        searchBar.becomeFirstResponder()
    }
    
    @objc private func didTapDismissScreen() {
        dismiss(animated: true, completion: nil)
    }

}

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        
        spinner.show(in: view)
        
        searchUsers(query: text)
    }
    
    func searchUsers(query: String) {
        // check if array has firebase results.
        if hasFetched {
            //If has - filter.
            filterUsers(with: query)
        } else {
            //If not - fetch.
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .failure(let error):
                    print("Error fetching users: \(error)")
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                }
            })
        }
    }
    
    func filterUsers(with term: String) {
        //Then Update UI and either show results or noResultsLabel
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        
        self.spinner.dismiss()
        
        let results: [SearchResult] = users.filter({
            guard let email = $0["email"], email != safeEmail else {
                return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"], let name = $0["name"] else {
                return nil
            }
            return SearchResult(name: name, email: email)
        })
        self.results = results
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationTableViewCell.identifier, for: indexPath) as! NewConversationTableViewCell
        let model = results[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //Start new Conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)
        })
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}
