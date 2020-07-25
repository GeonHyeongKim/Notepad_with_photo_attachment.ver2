//
//  ComposeViewController.swift
//  Notepad.ver2
//
//  Created by gunhyeong on 2020/07/25.
//  Copyright © 2020 geonhyeong. All rights reserved.
//

import UIKit

class ComposeViewController: UIViewController {
    
    var editTarget: Note?
    
    @IBOutlet weak var txtMemo: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                    
        if let memo = editTarget {
            navigationItem.title = "메모 편집"
            txtMemo.text = memo.content
        } else {
            navigationItem.title = "새 메모"
            txtMemo.text = ""
        }
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
        guard let memo = txtMemo.text,
            memo.count > 0 else {  // 메모가 입력되지 않았을 경우
            alert(message: "메모를 입력해주세요")
            return
        }
        
        // 메모가 입력되었을 경우
        if let tartget = editTarget { // 편집
            tartget.content = memo
            DataManager.shard.saveContext()
            NotificationCenter.default.post(name: ComposeViewController.memoDidChange, object: nil)
        } else { // 새 메모
            DataManager.shard.addNewMemo(memo)
            NotificationCenter.default.post(name: ComposeViewController.newMomoDidInsert, object: nil)
        }
//        let newMemo = Note(content: memo)
//        Note.dummyNoteList.append(newMemo)
        
        
        dismiss(animated: true, completion: nil)
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

//MARK:- 새 메모가 발생시 List update
extension ComposeViewController {
    static let newMomoDidInsert = Notification.Name(rawValue: "newMomoDidInsert")
    static let memoDidChange = Notification.Name(rawValue: "momoDidChange")
}
