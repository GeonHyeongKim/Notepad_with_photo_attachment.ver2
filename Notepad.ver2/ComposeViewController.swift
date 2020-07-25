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
    var originalMemoContent: String?
    
    @IBOutlet weak var txtMemo: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                    
        if let memo = editTarget {
            navigationItem.title = "메모 편집"
            txtMemo.text = memo.content
            originalMemoContent = memo.content
        } else {
            navigationItem.title = "새 메모"
            txtMemo.text = ""
        }
        
        txtMemo.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.presentationController?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.presentationController?.delegate = nil
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

//MARK: - UITextViewDelegate
extension ComposeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let origin = originalMemoContent, let edited = textView.text {
            if #available(iOS 13.0, *) {
                isModalInPresentation = origin != edited
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

//MARL: = UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        let alert = UIAlertController(title: "알림", message: "편집한 내용을 저장할까요?", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default) { [weak self] (action) in
            self?.save(action)
        }
        
        alert.addAction(okAction)
        
        let cancleAction = UIAlertAction(title: "취소", style: .cancel) { [weak self] (action) in
            self?.close(action)
        }
        
        alert.addAction(cancleAction)
        
        present(alert, animated: true, completion: nil)
    }
}

//MARK: - 새 메모가 발생시 List update
extension ComposeViewController {
    static let newMomoDidInsert = Notification.Name(rawValue: "newMomoDidInsert")
    static let memoDidChange = Notification.Name(rawValue: "momoDidChange")
}
