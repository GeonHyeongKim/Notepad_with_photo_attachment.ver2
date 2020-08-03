//
//  ComposeViewController.swift
//  Notepad.ver2
//
//  Created by gunhyeong on 2020/07/25.
//  Copyright © 2020 geonhyeong. All rights reserved.
//

import UIKit
import Photos

class ComposeViewController: UIViewController {
    
    var editTarget: Note?
    var originalMemoContent: String?
    
    @IBOutlet weak var tvMemo: UITextView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var willShowToken: NSObjectProtocol?
    var willHideToken: NSObjectProtocol?
    
    deinit {
        if let token = willShowToken {
            NotificationCenter.default.removeObserver(token)
        }
        
        if let token = willHideToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                    
        if let memo = editTarget {
            navigationItem.title = "메모 편집"
            tvMemo.text = memo.content
            originalMemoContent = memo.content
        } else {
            navigationItem.title = "새 메모"
            tvMemo.text = ""
        }
        
        tvMemo.delegate = self
        tvMemo.inputAccessoryView = toolbar

        // 키보드 노티피케이션
        willShowToken = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main, using: { [weak self] (noti) in
            guard let strongSelf = self, let toolbar = self?.toolbar else { return }
            
            if let frame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let hight = frame.cgRectValue.height
                
                var inset = strongSelf.tvMemo.contentInset
                inset.bottom = hight
                inset.top = toolbar.frame.height
                strongSelf.tvMemo.contentInset = inset
            }
        })
        
        willHideToken = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main, using: { [weak self] (noti) in
            guard let strongSelf = self else { return }
            
            var inset = strongSelf.tvMemo.contentInset
            inset.bottom = 0
            
            inset = strongSelf.tvMemo.scrollIndicatorInsets
            inset.bottom = 0
            inset.top = 0
            strongSelf.tvMemo.scrollIndicatorInsets = inset
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tvMemo.becomeFirstResponder()
        navigationController?.presentationController?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        tvMemo.resignFirstResponder()
        navigationController?.presentationController?.delegate = nil
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
        guard let memo = tvMemo.text,
            memo.count > 0 else {  // 메모가 입력되지 않았을 경우
            alert(message: "메모를 입력해주세요")
            return
        }
        
        // 메모가 입력되었을 경우
        if let tartget = editTarget { // 편집
            tartget.content = memo
            tartget.insertDate = Date()
            DataManager.shared.saveContext()
            NotificationCenter.default.post(name: ComposeViewController.memoDidChange, object: nil)
        } else { // 새 메모
            DataManager.shared.addNewMemo(memo)
            NotificationCenter.default.post(name: ComposeViewController.newMomoDidInsert, object: nil)
        }
//        let newMemo = Note(content: memo)
//        Note.dummyNoteList.append(newMemo)
        
        dismiss(animated: true, completion: nil)
    }
    // MARK: - Camera
    @IBAction func insertImage() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 옵션 초기화
        let libraryAction = UIAlertAction(title: "엘범", style: .default) { [weak self] (alert) in
            self!.checkPhotoLibraryAuthorizationStatus()
        }
        
        let cameraAction = UIAlertAction(title: "새로운 촬영", style: .default, handler: {
            [weak self] (alert: UIAlertAction!) -> Void in
            self!.checkCameraAuthorizationStatus()
        })
        //        let linkAction = UIAlertAction(title: "외부 링크 이미지", style: .default, handler: {
        //            [weak self] (alert: UIAlertAction!) -> Void in
        //            self.presentAlert(title: "URL 입력", message: "")
        //        })
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(libraryAction)
        alert.addAction(cameraAction)
        //        alert.addAction(linkAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // photo library 권한 확인
    private func checkPhotoLibraryAuthorizationStatus(){
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async { () -> Void in self.openLibraryAndCamera(.photoLibrary) }
            case .denied, .restricted:
                self.settingAlert(title: "사진 보관함에 접근 불가", message: "사진 보관함에 접근할 수 있도록, 앱 개인 정보 설정으로 이동하여 접근 허용해 주세요.")
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization() { status in
                    guard status == .authorized else { return }
                    self.openLibraryAndCamera(.photoLibrary)
                }
            @unknown default:
                print("Photo Library Authorization Status에서 에러발생")
            }
        }
    }
    
    // camera 권한 확인
    private func checkCameraAuthorizationStatus(){
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .authorized:
            DispatchQueue.main.async { () -> Void in self.openLibraryAndCamera(.camera) }
        case .denied, .restricted:
            self.settingAlert(title: "카메라에 접근 불가", message: "카메라에 접근할 수 있도록, 앱 개인 정보 설정으로 이동하여 접근 허용해 주세요.")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                if granted { DispatchQueue.main.async { self!.openLibraryAndCamera(.camera) } }
            }
        @unknown default:
            print("Camera Authorization Status에서 에러발생")
        }
    }
    
    // 엘범 열기 & 새로운 촬영
    func openLibraryAndCamera(_ sender: UIImagePickerController.SourceType){
        let imgaePicker = UIImagePickerController()
        imgaePicker.sourceType = sender
        imgaePicker.allowsEditing = true
        imgaePicker.delegate = self
        present(imgaePicker, animated: true)
    }
    
    // 권한 설정 알림 - photo library, camera
    private func settingAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let settingAction = UIAlertAction(title: "승인", style: .default){ (action) in // 다시 설정에서 허용할 수 있도록
                if let settingsUrl = NSURL(string:UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl as URL, options: [:], completionHandler: nil)
                }
            }
            let cancleAction = UIAlertAction(title: "허용 안함", style: .destructive, handler: nil)
            alert.addAction(cancleAction)
            alert.addAction(settingAction)
            self.present(alert, animated:true, completion:nil)
        }
    }

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

// MARK: - UIImagePickerController Delegate
extension ComposeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let userPickedImage = info[.editedImage] as? UIImage else { return }
        
        DataManager.shared.saveImage(userPickedImage.pngData()!)
        
        dismiss(animated: true, completion: nil)
    }
}


//MARK: - 새 메모가 발생시 List update
extension ComposeViewController {
    static let newMomoDidInsert = Notification.Name(rawValue: "newMomoDidInsert")
    static let memoDidChange = Notification.Name(rawValue: "momoDidChange")
}
