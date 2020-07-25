//
//  DetailViewController.swift
//  Notepad.ver2
//
//  Created by gunhyeong on 2020/07/25.
//  Copyright © 2020 geonhyeong. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    var memo: Note?
    
    @IBOutlet weak var tvMemo: UITableView!
    
    let formatter: DateFormatter = { // Closures를 활용
        let format = DateFormatter()
        format.dateStyle = .long
        format.timeStyle = .short
        format.locale = Locale(identifier: "Ko_kr") // 한글표시
        return format
    }()
    
    var token: NSObjectProtocol?
    
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        token = NotificationCenter.default.addObserver(forName: ComposeViewController.memoDidChange, object: nil, queue: OperationQueue.main, using: { [weak self] (noti) in
            self?.tvMemo.reloadData()
        })
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination.children.first as? ComposeViewController {
            vc.editTarget = memo
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailMemoTableViewCell", for: indexPath)
            cell.textLabel?.text = memo?.content
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailDateTableViewCell", for: indexPath)
            cell.textLabel?.text = formatter.string(from: memo?.insertDate ?? Date())

            return cell
        default:
            fatalError()
        }
    }
    
    
}
