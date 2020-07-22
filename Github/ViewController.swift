//
//  ViewController.swift
//  Github
//
//  Created by Joey on 2020/7/20.
//  Copyright © 2020 Joey. All rights reserved.
//

import UIKit

class ViewController: UIViewController,
    UISearchBarDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    private let cellReuseIdentifier = "UserCell"
    
    @IBOutlet var searchBar: UISearchBar!
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    private var state: State = .ready(nil)
    private var users: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(didTap)))
        
        collectionView.register(UserCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
             layout.sectionInset = .init(top: 0, left: 15, bottom: 0, right: 15)
        }
    }
    
    // MARK: - User Touches
    
    @objc
    func didTap() {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - RemoteDate
    
    private func fetchUsers() {
        guard
            case let .ready(optionalURL) = state,
            let url = optionalURL
        else { return }
        
        let taskID = UUID().uuidString
        state = .fetching(taskID)
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            let decoder = JSONDecoder()
            guard
                let self = self,
                case let .fetching(currentTaskID) = self.state,
                taskID == currentTaskID,
                let httpResponse = response as? HTTPURLResponse,
                let data = data,
                let result = try? decoder.decode(SearchUserResult.self, from: data)
            else { return }
            
            let link = httpResponse.allHeaderFields["Link"] as? String
            let webLinking = link?.parseWebLinking()
            
            DispatchQueue.main.async {
                self.handleUser(result: result, webLinking: webLinking)
            }
        }.resume()
    }
    
    private func handleUser(result: SearchUserResult, webLinking: WebLinking?) {
        if let nextURL = webLinking?.nextURL {
             // has next
             self.state = .ready(nextURL)
         } else {
             // last page
             self.state = .done
         }
         
         if webLinking?.prevURL == nil {
             // first page
             self.users = result.items
         } else {
             // fetch more
             self.users += result.items
         }
        
         self.collectionView.reloadData()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard
            let searchText = searchBar.text,
            searchText.count > 0,
            let reqeustURL = URL(string: "https://api.github.com/search/users?q=\(searchText)")
        else { return }
        
        state = .ready(reqeustURL)
        fetchUsers()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? UserCollectionViewCell,
            let user = users[safe: indexPath.row],
            let avatarURL = URL(string: user.avatarURLString ?? "")
        else {
            return UICollectionViewCell()
        }
        // TODO: May use UICollectionViewDataSourcePrefetching to prefetch remote image
        cell.update(avatarURL: avatarURL, name: user.name)
        
        // check to do load more
        if
            indexPath.row == (users.count - 1),
            case let .ready(optionalURL) = state,
            optionalURL != nil
        {
            // do load more
            fetchUsers()
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: UIScreen.main.bounds.width / 2 - 50, height: 200)
    }
}

enum State: Equatable {
    case ready(URL?)
    case fetching(String)
    case done
    case error(Error)
    
    static func ==(lhs: State, rhs: State) -> Bool {
        switch (lhs, rhs) {
        case (let .ready(lURL), let .ready(rURL)):
            return lURL == rURL
        case (let .fetching(lID), let .fetching(rID)):
            return lID == rID
        case (.done, .done):
            return true
        case (let .error(lError), let .error(rError)):
            return (lError as NSError) == (rError as NSError)
        default:
            return false
        }
    }
}

// MARK: - Network transient models

private struct SearchUserResult: Codable {
    let items: [User]
}

// MARK: - Utils

private extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

private struct WebLinking {
    let nextURL: URL?
    let prevURL: URL?
}

private extension String {
    func parseWebLinking() -> WebLinking {
        let array = self.split(separator: ",")
        var nextURL: URL?
        var prevURL: URL?
        array.forEach { (pair) in
            let pairArray = pair.split(separator: ";")
            guard let urlRaw = pairArray[safe: 0], let relationRaw = pairArray[safe: 1] else { return }
            
            // parse i.e.
            // <https://api.github.com/search/users?q=A&page=2>
            var urlString = urlRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard urlString.first == "<" && urlString.last == ">" else { return }
            urlString.removeFirst()
            urlString.removeLast()
            guard let url = URL(string: urlString) else { return }
            
            // parse i.e.
            // rel = "next"
            let relation = relationRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            let relationArray = relation.split(separator: "\"")
            guard let relationValue = relationArray[safe: 1] else { return }
            
            if relationValue == "next" {
                nextURL = url
            } else if relationValue == "prev" {
                prevURL = url
            }
        }
        return WebLinking(nextURL: nextURL, prevURL: prevURL)
    }
}
