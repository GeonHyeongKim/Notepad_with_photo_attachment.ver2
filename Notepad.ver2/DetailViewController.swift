//
//  DetailViewController.swift
//  Notepad.ver2
//
//  Created by gunhyeong on 2020/07/25.
//  Copyright © 2020 geonhyeong. All rights reserved.
//

import UIKit
import Photos

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
    
    @IBAction func deleteMemo(_ sender: Any) {
        let alert = UIAlertController(title: "알림", message: "삭제 확인", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] (action) in
            DataManager.shared.deleteMemo(self?.memo)
            self?.navigationController?.popViewController(animated: true)
        } 
        
        alert.addAction(okAction)
        
        let cancleAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(cancleAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        guard let memo = memo?.content else { return }
        
        let vc = UIActivityViewController(activityItems: [memo], applicationActivities: nil)
        
        if let pc = popoverPresentationController {
            pc.barButtonItem = sender
        }
        
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Camera
    @IBAction func insertImage(_ sender: Any) {
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
    
    //
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

//MARK: - TableVeiw DataSource
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

// MARK: - UIImagePickerController Delegate
extension DetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        
        //        // Camera로 찍은 image 저장
        //        if selectedPhotos == nil {
        //            self.selectedPhotos = [UIImage]()
        //        }
        //
        //        self.selectedPhotos.append(image)
        dismiss(animated: true, completion: nil)
    }
}
