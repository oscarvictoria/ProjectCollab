//
//  FeedViewController.swift
//  ProjectCollaboration
//
//  Created by Liubov Kaper  on 4/21/20.
//  Copyright © 2020 Luba Kaper. All rights reserved.
//

import UIKit
import FirebaseFirestore

class FeedViewController: UIViewController {
    
    private var feedView = FeedView()
    
    private var listener: ListenerRegistration?
    
    private var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.feedView.feedCV.reloadData()
            }
        }
    }
    
    private var allUsers = [Professional]() {
        didSet {
            currentUser = allUsers.first
            print("feed\(currentUser!.name)")
        }
    }
    private var currentUser: Professional?
    
    override func loadView() {
        view = feedView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureCV()
        configureSearchBar()
        addBackgroundGradient()
        navigationItem.title = "Together"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        listener = Firestore.firestore().collection(DatabaseServices.postCollection).addSnapshotListener({ [weak self] (snapshot, error) in
            if let error = error {
                print("\(error.localizedDescription)")
            } else if let snapshot = snapshot {
                let posts = snapshot.documents.map {Post($0.data())}
                self?.posts = posts
            }
        })
        
        listener = Firestore.firestore().collection(DatabaseServices.usersCollection).addSnapshotListener({ [weak self] (snapshot, error) in
            if let error = error {
                print("error getting users\(error.localizedDescription)")
            } else if let snapshot = snapshot {
                let currentUser = snapshot.documents.map {Professional($0.data())}
                self?.allUsers = currentUser
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        listener?.remove()
    }
    
    private func configureCV() {
        feedView.feedCV.register(FeedCell.self, forCellWithReuseIdentifier: "feedCell")
        feedView.feedCV.dataSource = self
        feedView.feedCV.delegate = self
    }
    
    private func configureSearchBar() {
        feedView.searchBar.delegate = self
    }
    
    private func addBackgroundGradient() {
        let collectionViewBackgroundView = UIView()
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame.size = feedView.frame.size
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.colors = [UIColor.white.cgColor, UIColor.green.cgColor]
        feedView.feedCV.backgroundView = collectionViewBackgroundView
        feedView.feedCV.backgroundView?.layer.addSublayer(gradientLayer)
    }
    
}

extension FeedViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "feedCell", for: indexPath) as? FeedCell else {
            fatalError()
        }
        let aPost = posts[indexPath.row]
        cell.updateCell(post: aPost)
        return cell
    }
}

extension FeedViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxSize: CGSize = feedView.safeAreaLayoutGuide.layoutFrame.size
        let itemWidth = maxSize.width
        let itemHeight = maxSize.height * 0.70
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let aPost = posts[indexPath.row]
        let detailVC = DetailViewController(aPost, allUsers)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension FeedViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let searchQuery = searchBar.text else {return}
        posts = posts.filter {$0.postTitle.lowercased().contains(searchQuery.lowercased())}
    }
}
