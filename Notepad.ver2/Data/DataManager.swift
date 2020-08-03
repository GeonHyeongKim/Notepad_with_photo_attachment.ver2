//
//  DataManager.swift
//  Notepad.ver2
//
//  Created by gunhyeong on 2020/07/26.
//  Copyright © 2020 geonhyeong. All rights reserved.
//

import Foundation
import CoreData

class DataManager {
    static let shared = DataManager()
    private init() {
        
    }
    
    // Context : Core Data를 관리
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // 메모리에서 데이터 읽어오기
    var noteList = [Note]()
    func fetchNote() {
        let requestNote: NSFetchRequest<Note> = Note.fetchRequest()
        
        let sortByDateDesc = NSSortDescriptor(key: "insertDate", ascending: false) // 내림차순
        requestNote.sortDescriptors = [sortByDateDesc]
        
        do {
            noteList = try mainContext.fetch(requestNote)
        } catch {
             print(error)
        }
    }
    
    // 새로운 메모 생성
    func addNewMemo(_ memo: String?) {
        let newMemo = Note(context: mainContext)
        
        newMemo.content = memo
        newMemo.insertDate = Date()
//        newMemo.insertImages = images.
        
        // table reload
        noteList.insert(newMemo, at: 0) // 가장 처음에 입력
        
        saveContext()
    }
    
    func deleteMemo(_ memo: Note?) {
        if let memo = memo {
            mainContext.delete(memo)
            saveContext()
        }
    }
//
//    // 이미지 저장
//    func saveImage(_ memo: Note?, _ imageData: Data) {
//        if let memo = memo {
//            memo.image = imageData
//            saveContext()
//        }
//    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Notepad_ver2")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

